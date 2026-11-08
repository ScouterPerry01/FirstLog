// File path and name: spikes/speech_trial/lib/speech/sherpa_engines.dart
// Modified On Timestamp: 2026-11-08 @ 16:58 EST (word start times for cutting the end phrase; letter-run check)
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: sherpa-onnx implementations of the trial's speech interfaces: streaming zipformer
//                   (set-up A, optionally biased towards the key phrases with hotwords) and NeMo
//                   Canary-180m-flash (set-up B, fed only the speech the Silero voice detector finds).
// Uses: package:sherpa_onnx (1.13.8), speech/speech_engine.dart, trial_config.dart.
// Used By: capture_controller.dart.
// Purpose: Run speech recognition on the device with no internet (VC-2).

import 'dart:io';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../trial_config.dart';
import 'speech_engine.dart';

bool _bindingsReady = false;

/// Must run once before any sherpa-onnx object is created.
void ensureSherpaBindings() {
  if (_bindingsReady) return;
  sherpa.initBindings();
  _bindingsReady = true;
}

/// Finds the single file in [dir] whose name matches [pattern] (model files carry epoch numbers in their names).
String _find(String dir, RegExp pattern) {
  final hits = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => pattern.hasMatch(f.uri.pathSegments.last))
      .toList();
  if (hits.isEmpty) {
    throw StateError('No file matching ${pattern.pattern} in $dir - run tool/download_models.ps1 '
        '(and tool/push_models_android.ps1 for a phone).');
  }
  return hits.first.path;
}

/// Splits [phrase] into the model's BPE pieces by longest match against tokens.txt, e.g. "scene info" ->
/// "▁SCENE ▁IN FO". Not the exact BPE algorithm, but every piece is a real token. Null if a word cannot be
/// spelled with the model's tokens (e.g. digits).
String? tokenizeForHotwords(String phrase, Set<String> tokens) {
  final out = <String>[];
  for (final word in phrase.toUpperCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
    var pos = 0;
    var first = true;
    while (pos < word.length) {
      String? hit;
      for (var end = word.length; end > pos; end--) {
        final piece = (first ? '▁' : '') + word.substring(pos, end);
        if (tokens.contains(piece)) {
          hit = piece;
          pos = end;
          break;
        }
      }
      if (hit == null) return null;
      out.add(hit);
      first = false;
    }
  }
  return out.isEmpty ? null : out.join(' ');
}

/// Whether sherpa-onnx 1.13.8's streaming token times keep counting across a reset (true) or restart at 0.
/// Self-test 2026-11-08: they restart (first word at 1.08 s after 2 s of silence and a reset).
bool timestampsCountFromCreation = false;

/// Joins BPE pieces into words with the start time of each word's first piece, minus [timestampOffset]. A
/// piece starting with "▁" or a space starts a word (sherpa-onnx returns " PULSE", " ONE", "S" ...).
List<(String, double)> wordsFromTokens(List<String> tokens, List<double> timestamps,
    {double timestampOffset = 0}) {
  final out = <(String, double)>[];
  var word = StringBuffer();
  var start = 0.0;
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    final time = (i < timestamps.length ? timestamps[i] : start + timestampOffset) - timestampOffset;
    if (t.startsWith('▁') || t.startsWith(' ') || word.isEmpty) {
      if (word.isNotEmpty) out.add((word.toString(), start));
      word = StringBuffer(t.replaceFirst(RegExp('^[▁ ]+'), ''));
      start = time;
    } else {
      word.write(t);
    }
  }
  if (word.isNotEmpty) out.add((word.toString(), start));
  return out;
}

class SherpaStreamingRecognizer implements StreamingRecognizer {
  /// With [hotwordsDir] set, the key phrases of [pack] are written there as a hotwords file and the recognizer
  /// switches to modified_beam_search so it can use them.
  SherpaStreamingRecognizer(String modelsRoot, LanguagePack pack, {int numThreads = 2, String? hotwordsDir}) {
    ensureSherpaBindings();
    final sep = Platform.pathSeparator;
    final dir = '$modelsRoot$sep${pack.streamingModelDir}';
    var hotwordsFile = '';
    if (hotwordsDir != null) {
      final tokens = File('$dir${sep}tokens.txt')
          .readAsLinesSync()
          .map((l) => l.split(' ').first)
          .where((t) => t.isNotEmpty)
          .toSet();
      final lines = <String>[];
      for (final p in pack.allCommands.toSet()) {
        final t = tokenizeForHotwords(p, tokens);
        if (t == null) {
          hotwordsSkipped.add(p);
        } else {
          lines.add(t);
          hotwords[p] = t;
        }
      }
      hotwordsFile = '$hotwordsDir${sep}hotwords_${pack.code}.txt';
      File(hotwordsFile).writeAsStringSync('${lines.join('\n')}\n');
    }
    final config = sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: _find(dir, RegExp(r'^encoder.*\.int8\.onnx$')),
          decoder: _find(dir, RegExp(r'^decoder.*\.int8\.onnx$')),
          joiner: _find(dir, RegExp(r'^joiner.*\.int8\.onnx$')),
        ),
        tokens: '$dir${Platform.pathSeparator}tokens.txt',
        numThreads: numThreads,
        debug: false,
      ),
      enableEndpoint: true,
      // Short pause ends a command utterance quickly; long utterances are cut at 20 s.
      rule1MinTrailingSilence: 2.0,
      rule2MinTrailingSilence: 0.8,
      rule3MinUtteranceLength: 20,
      decodingMethod: hotwordsFile.isEmpty ? 'greedy_search' : 'modified_beam_search',
      maxActivePaths: TrialTuning.maxActivePaths,
      hotwordsFile: hotwordsFile,
      hotwordsScore: TrialTuning.hotwordsScore,
    );
    _recognizer = sherpa.OnlineRecognizer(config);
    _stream = _recognizer.createStream();
    name = 'sherpa-streaming:${pack.streamingModelDir}${hotwordsFile.isEmpty ? '' : '+hotwords'}';
  }

  /// Key phrase -> the BPE pieces given to the recognizer (logged so the results show what was biased).
  final Map<String, String> hotwords = {};

  /// Key phrases that could not be turned into hotwords.
  final List<String> hotwordsSkipped = [];

  late final sherpa.OnlineRecognizer _recognizer;
  late sherpa.OnlineStream _stream;
  final Stopwatch _decodeWatch = Stopwatch();
  int _samples = 0;

  @override
  late final String name;

  @override
  StreamingResult accept(Float32List samples) {
    _samples += samples.length;
    _stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
    _decodeWatch.start();
    while (_recognizer.isReady(_stream)) {
      _recognizer.decode(_stream);
    }
    final r = _recognizer.getResult(_stream);
    final endpoint = _recognizer.isEndpoint(_stream);
    _decodeWatch.stop();
    final sinceReset = (_samples - _samplesAtReset) / sampleRate;
    return StreamingResult(r.text,
        isEndpoint: endpoint,
        words: wordsFromTokens(r.tokens, r.timestamps, timestampOffset: _timestampOffset()),
        secondsSinceReset: sinceReset);
  }

  @override
  void reset() {
    _recognizer.reset(_stream);
    _samplesAtReset = _samples;
  }

  int _samplesAtReset = 0;

  /// Seconds to subtract from sherpa's token times so they count from the last reset. Set by
  /// [timestampsCountFromCreation] (checked by the self-test: see README).
  double _timestampOffset() => timestampsCountFromCreation ? _samplesAtReset / sampleRate : 0;

  @override
  double get decodeSeconds => _decodeWatch.elapsedMicroseconds / 1e6;

  @override
  double get audioSeconds => _samples / sampleRate;

  @override
  void dispose() {
    _stream.free();
    _recognizer.free();
  }
}

class SherpaCanaryRecognizer implements SegmentRecognizer {
  SherpaCanaryRecognizer(String modelsRoot, LanguagePack pack, {int numThreads = 2}) {
    ensureSherpaBindings();
    final dir = '$modelsRoot${Platform.pathSeparator}$canaryModelDir';
    final vadPath = '$modelsRoot${Platform.pathSeparator}${TrialTuning.vadModel}';
    if (File(vadPath).existsSync()) {
      _vadConfig = sherpa.VadModelConfig(
        sileroVad: sherpa.SileroVadModelConfig(
          model: vadPath,
          threshold: TrialTuning.vadThreshold,
          minSilenceDuration: TrialTuning.vadMinSilence,
          minSpeechDuration: TrialTuning.vadMinSpeech,
          maxSpeechDuration: TrialTuning.vadMaxSpeech,
        ),
        sampleRate: sampleRate,
        numThreads: 1,
        debug: false,
      );
    }
    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        canary: sherpa.OfflineCanaryModelConfig(
          encoder: '$dir${Platform.pathSeparator}encoder.int8.onnx',
          decoder: '$dir${Platform.pathSeparator}decoder.int8.onnx',
          srcLang: pack.code,
          tgtLang: pack.code, // same language: transcribe, do not translate
          usePnc: true,
        ),
        tokens: '$dir${Platform.pathSeparator}tokens.txt',
        numThreads: numThreads,
        debug: false,
      ),
    );
    _recognizer = sherpa.OfflineRecognizer(config);
  }

  late final sherpa.OfflineRecognizer _recognizer;
  sherpa.VadModelConfig? _vadConfig;

  /// Seconds of speech the voice detector found in the last [transcribe] call (null: no detector).
  double? lastSpeechSeconds;

  @override
  String get name => 'sherpa-canary:$canaryModelDir${_vadConfig == null ? '' : '+silero-vad'}';

  @override
  String transcribe(Float32List samples) {
    final segments = _speechSegments(samples);
    final parts = <String>[];
    for (final seg in segments) {
      final stream = _recognizer.createStream();
      stream.acceptWaveform(samples: seg, sampleRate: sampleRate);
      _recognizer.decode(stream);
      parts.add(_recognizer.getResult(stream).text.trim());
      stream.free();
    }
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  /// Only the speech: the voice detector's segments, or (no detector) fixed chunks of canaryMaxChunk.
  List<Float32List> _speechSegments(Float32List samples) {
    final cfg = _vadConfig;
    if (cfg == null) {
      lastSpeechSeconds = null;
      final maxLen = TrialTimings.canaryMaxChunk.inMilliseconds * sampleRate ~/ 1000;
      return [
        for (var s = 0; s < samples.length; s += maxLen)
          Float32List.sublistView(samples, s, s + maxLen < samples.length ? s + maxLen : samples.length),
      ];
    }
    final vad = sherpa.VoiceActivityDetector(config: cfg, bufferSizeInSeconds: samples.length / sampleRate + 5);
    final out = <Float32List>[];
    void drain() {
      while (!vad.isEmpty()) {
        out.add(vad.front().samples);
        vad.pop();
      }
    }

    const window = 512; // Silero window size
    for (var s = 0; s < samples.length; s += window) {
      final e = s + window < samples.length ? s + window : samples.length;
      vad.acceptWaveform(Float32List.fromList(Float32List.sublistView(samples, s, e)));
      drain();
    }
    vad.flush();
    drain();
    vad.free();
    lastSpeechSeconds = out.fold<int>(0, (n, x) => n + x.length) / sampleRate;
    return out;
  }

  @override
  void dispose() => _recognizer.free();
}

/// Removes runs of 4+ identical words ("F F F F ...", a known hallucination on silence) and letter groups
/// repeated 4+ times inside a word (run 2: "Firststststststst" -> "First"). Returns the cleaned text and how
/// many words were removed or shortened, so the log can show it (ST-4: never keep invented text silently).
(String, int) stripRepetition(String text) {
  var shortened = 0;
  final inWord = RegExp(r'(\p{L}{1,3})\1{3,}', unicode: true);
  text = text.replaceAllMapped(inWord, (m) {
    shortened++;
    return m.group(1)!;
  });
  final (clean, removed) = _stripWordRuns(text);
  return (clean, removed + shortened);
}

(String, int) _stripWordRuns(String text) {
  final words = text.split(' ');
  final out = <String>[];
  var removed = 0;
  var i = 0;
  while (i < words.length) {
    var j = i;
    final key = words[i].toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    while (j + 1 < words.length &&
        key.isNotEmpty &&
        words[j + 1].toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '') == key) {
      j++;
    }
    final run = j - i + 1;
    if (run >= 4) {
      removed += run;
    } else {
      out.addAll(words.sublist(i, j + 1));
    }
    i = j + 1;
  }
  return (out.join(' ').trim(), removed);
}

/// Saves a dictation's audio next to its transcript (VC-3).
bool saveWave(String path, Float32List samples) =>
    sherpa.writeWave(filename: path, samples: samples, sampleRate: sampleRate);
