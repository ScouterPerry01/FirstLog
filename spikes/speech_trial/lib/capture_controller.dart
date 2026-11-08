// File path and name: spikes/speech_trial/lib/capture_controller.dart
// Modified On Timestamp: 2026-11-08 @ 13:59 EST (mic kept running when a prompt plays; mic level + diagnostics)
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: The trial's voice loop (decision 0002): ask "new or continuing", listen for key phrases,
//                   "Proceed" -> dictation -> end phrase / silence / next keyword / Stop -> "Saved", "Read back",
//                   and "Call 9-1-1" at any moment. Logs everything for the results.
// Uses: package:record (microphone), package:battery_plus, speech/*, trial_config.dart, trial_log.dart,
//       background_service.dart.
// Used By: main.dart.
// Purpose: Measure key-phrase reliability, dictation accuracy (set-ups A and B) and battery for N1 (FLOG-22).
//          Trial code only: it never dials, and gives no first aid advice.

import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'background_service.dart';
import 'speech/sherpa_engines.dart';
import 'speech/speech_engine.dart';
import 'speech/voice.dart';
import 'trial_config.dart';
import 'trial_log.dart';

enum Phase { stopped, loading, askingSession, listening, dictating }

class Dictation {
  Dictation({required this.field, required this.startedAt});

  final TrialField field;
  final DateTime startedAt;
  DateTime? endedAt;
  String endReason = '';
  String textA = ''; // set-up A: streaming zipformer
  String? textB; // set-up B: Canary (null when B is off)
  int? canaryMs;
  String? audioFile;
}

class CaptureController extends ChangeNotifier {
  CaptureController({required this.modelsRoot, required this.logsRoot, required this.tempDir});

  final String modelsRoot;
  final String logsRoot;
  final String tempDir;

  TrialLanguage language = TrialLanguage.en;
  bool useCanary = true;

  Phase phase = Phase.stopped;
  bool speaking = false;
  String partial = '';
  String? error;

  /// Peak level of the latest microphone chunk, 0..1 (shown on screen so a dead mic is obvious).
  double micLevel = 0;
  final List<Dictation> dictations = [];
  TrialLog? log;

  LanguagePack get pack => packFor(language);

  StreamingRecognizer? _listener;
  SegmentRecognizer? _canary;
  Voice? _voice;
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<RecordState>? _micStateSub;
  int _micSamples = 0; // since the last metrics line
  double _micPeak = 0; // since the last metrics line
  bool _firstAudioLogged = false;
  Timer? _tick;
  Timer? _metrics;
  final Battery _battery = Battery();

  int? _leftoverByte;
  bool _speaking911 = false;
  String _lastRaw = '';

  // Current dictation.
  Dictation? _dict;
  final List<String> _dictParts = [];
  final List<Float32List> _dictAudio = [];
  DateTime _lastWordsAt = DateTime.now();

  // ---------------------------------------------------------------- start / stop

  Future<void> start() async {
    if (phase != Phase.stopped) return;
    error = null;
    phase = Phase.loading;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 50)); // let the UI show "Loading"
    try {
      log = await TrialLog.open(logsRoot);
      log!.event('run-start', {
        'language': pack.code,
        'setupB': useCanary,
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'cpus': Platform.numberOfProcessors,
        'battery': await _batteryLevel(),
      });

      final watch = Stopwatch()..start();
      _listener = SherpaStreamingRecognizer(modelsRoot, pack);
      final listenerMs = watch.elapsedMilliseconds;
      if (useCanary) _canary = SherpaCanaryRecognizer(modelsRoot, pack);
      final canaryMs = watch.elapsedMilliseconds - listenerMs;
      _voice = Voice(modelsRoot, pack, tempDir);
      log!.event('models-loaded', {
        'listener': _listener!.name,
        'listenerMs': listenerMs,
        'canary': _canary?.name,
        'canaryMs': canaryMs,
        'totalMs': watch.elapsedMilliseconds,
      });

      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission refused');
      }
      await BackgroundService.start(); // Android: keeps listening with the screen locked (VC-1)
      _firstAudioLogged = false;
      _micStateSub = _recorder.onStateChanged().listen((s) => log?.event('mic-state', {'state': s.name}));
      final mic = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        // The default (pause) stops the mic for good as soon as our own prompt takes the audio focus.
        audioInterruption: AudioInterruptionMode.none,
      ));
      _micSub = mic.listen(_onBytes, onError: (Object e) => log?.event('mic-error', {'error': '$e'}));

      _tick = Timer.periodic(const Duration(milliseconds: 500), (_) => _onTick());
      _metrics = Timer.periodic(TrialTimings.metricsEvery, (_) => _logMetrics());

      phase = Phase.askingSession;
      notifyListeners();
      await _say(pack.promptAsk);
    } catch (e, st) {
      error = '$e';
      log?.event('error', {'error': '$e', 'stack': '$st'});
      await stop();
    }
  }

  Future<void> stop() async {
    if (_dict != null) await _finishDictation('app-stop', speak: false);
    _tick?.cancel();
    _metrics?.cancel();
    await _micSub?.cancel();
    _micSub = null;
    await _micStateSub?.cancel();
    _micStateSub = null;
    micLevel = 0;
    if (await _recorder.isRecording()) await _recorder.stop();
    await BackgroundService.stop();
    if (log != null) {
      _logMetrics();
      log!.event('run-stop');
      await log!.close();
    }
    _listener?.dispose();
    _canary?.dispose();
    _voice?.dispose();
    _listener = null;
    _canary = null;
    _voice = null;
    phase = Phase.stopped;
    speaking = false;
    partial = '';
    notifyListeners();
  }

  /// Stop button during a dictation (VC-7).
  Future<void> stopDictationTap() async {
    if (_dict != null) await _finishDictation('stop-tap');
  }

  // ---------------------------------------------------------------- audio in

  void _onBytes(Uint8List bytes) {
    final samples = _pcm16ToFloat(bytes);
    if (samples.isEmpty || _listener == null) return;
    var peak = 0.0;
    for (final s in samples) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    micLevel = peak;
    _micSamples += samples.length;
    if (peak > _micPeak) _micPeak = peak;
    if (!_firstAudioLogged) {
      _firstAudioLogged = true;
      log?.event('mic-first-audio', {'samples': samples.length, 'peak': peak});
    }
    if (phase == Phase.dictating && !speaking) _dictAudio.add(samples);
    final res = _listener!.accept(samples);
    _handle(res);
    notifyListeners(); // mic level on screen (~10 times a second; fine for a trial screen)
  }

  Float32List _pcm16ToFloat(Uint8List bytes) {
    Uint8List data = bytes;
    if (_leftoverByte != null) {
      data = Uint8List(bytes.length + 1)
        ..[0] = _leftoverByte!
        ..setRange(1, bytes.length + 1, bytes);
      _leftoverByte = null;
    }
    final n = data.length ~/ 2;
    if (data.length.isOdd) _leftoverByte = data.last;
    final bd = ByteData.sublistView(data);
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  // ---------------------------------------------------------------- recognition results

  void _handle(StreamingResult res) {
    final utt = normalize(res.text);
    if (res.text != _lastRaw) {
      _lastRaw = res.text;
      partial = res.text;
      if (utt.isNotEmpty && phase == Phase.dictating && !speaking) _lastWordsAt = DateTime.now();
      notifyListeners();
    }

    // "Call 9-1-1" at any moment, even mid-dictation or while the app speaks (VC-10, EM-2).
    if (!_speaking911 && findPhrase(utt, pack.call911) >= 0) {
      _listener!.reset();
      _lastRaw = '';
      unawaited(_onCall911(utt));
      return;
    }

    if (speaking) {
      // The app may be hearing its own prompt: ignore everything else and discard the utterance.
      if (res.isEndpoint) _resetUtterance();
      return;
    }

    if (phase == Phase.dictating) {
      final endAt = findPhrase(utt, pack.endPhrases);
      if (endAt >= 0) {
        log!.event('end-phrase', {'heard': utt});
        final before = utt.substring(0, endAt).trim();
        if (before.isNotEmpty) _dictParts.add(before);
        _resetUtterance();
        unawaited(_finishDictation('end-phrase'));
        return;
      }
      if (res.isEndpoint) {
        final nextField = matchField(utt);
        if (nextField != null) {
          log!.event('next-keyword', {'heard': utt, 'field': nextField.name});
          _resetUtterance();
          unawaited(_finishDictation('next-keyword', thenField: nextField));
          return;
        }
        if (utt.isNotEmpty) _dictParts.add(utt);
        _resetUtterance();
      }
      return;
    }

    if (!res.isEndpoint) return;
    _resetUtterance();
    if (utt.isEmpty) return;
    log!.event('utterance', {'phase': phase.name, 'text': utt});

    if (phase == Phase.askingSession) {
      if (isCommand(utt, pack.sessionNew)) {
        unawaited(_onSession(isNew: true, heard: utt));
      } else if (isCommand(utt, pack.sessionContinue)) {
        unawaited(_onSession(isNew: false, heard: utt));
      }
      return;
    }

    if (phase == Phase.listening) {
      final field = matchField(utt);
      if (field != null) {
        log!.event('keyword', {'heard': utt, 'field': field.name});
        unawaited(_startDictation(field));
      } else if (isCommand(utt, pack.readBack)) {
        log!.event('read-back-request', {'heard': utt});
        unawaited(_readBack());
      } else {
        log!.event('ignored', {'text': utt}); // not a key phrase - nothing happens (check for false triggers)
      }
    }
  }

  void _resetUtterance() {
    _listener?.reset();
    _lastRaw = '';
    partial = '';
  }

  void _onTick() {
    if (phase == Phase.dictating && !speaking && _dict != null) {
      if (DateTime.now().difference(_lastWordsAt) > TrialTimings.dictationSilence) {
        unawaited(_finishDictation('silence'));
      }
    }
  }

  // ---------------------------------------------------------------- actions

  Future<void> _onSession({required bool isNew, required String heard}) async {
    log!.event('session', {'new': isNew, 'heard': heard});
    phase = Phase.listening;
    notifyListeners();
    final ready = isNew ? pack.promptReadyNew : pack.promptReadyContinue;
    await _say('$ready ${pack.spokenDateTime(DateTime.now())}');
  }

  Future<void> _startDictation(TrialField field) async {
    phase = Phase.dictating; // blocks other commands while "Proceed" is spoken
    await _say(pack.promptProceed);
    _dict = Dictation(field: field, startedAt: DateTime.now());
    _dictParts.clear();
    _dictAudio.clear();
    _lastWordsAt = DateTime.now();
    _resetUtterance();
    log!.event('dictation-start', {'field': field.name});
    notifyListeners();
  }

  Future<void> _finishDictation(String reason, {bool speak = true, TrialField? thenField}) async {
    final d = _dict;
    if (d == null) return;
    _dict = null;
    phase = Phase.listening;

    // Include the words heard so far in the current, unfinished utterance (Stop tap, silence, app stop).
    if (reason == 'stop-tap' || reason == 'silence' || reason == 'app-stop' || reason == 'call-911') {
      final pending = normalize(_lastRaw);
      if (pending.isNotEmpty && findPhrase(pending, pack.call911) < 0) _dictParts.add(pending);
      _resetUtterance();
    }

    d.endedAt = DateTime.now();
    d.endReason = reason;
    d.textA = _dictParts.join(' ').trim();
    final audio = _concat(_dictAudio);
    _dictAudio.clear();
    final seconds = audio.length / sampleRate;

    final wav = '${log!.audioDir}${Platform.pathSeparator}${dictations.length + 1}-${d.field.name}.wav';
    if (saveWave(wav, audio)) d.audioFile = wav; // VC-3

    if (_canary != null && audio.isNotEmpty) {
      final w = Stopwatch()..start();
      final raw = _canary!.transcribe(audio);
      d.canaryMs = w.elapsedMilliseconds;
      d.textB = stripEndPhrase(raw, pack.endPhrases);
      log!.event('canary', {
        'rawText': raw,
        'ms': d.canaryMs,
        'rtf': seconds > 0 ? (d.canaryMs! / 1000 / seconds) : null,
      });
    }
    log!.event('dictation-end', {
      'field': d.field.name,
      'reason': reason,
      'seconds': seconds,
      'textA': d.textA,
      'textB': d.textB,
      'audio': d.audioFile,
    });
    dictations.add(d);
    notifyListeners();

    if (speak) await _say(pack.promptSaved);
    if (thenField != null) await _startDictation(thenField);
  }

  Future<void> _readBack() async {
    if (dictations.isEmpty) {
      await _say(pack.promptNothingToRead);
      return;
    }
    final d = dictations.last;
    final text = (d.textB != null && d.textB!.isNotEmpty) ? d.textB! : d.textA;
    log!.event('read-back', {'source': identical(text, d.textA) ? 'A' : 'B', 'text': text});
    await _say(text.isEmpty ? pack.promptNothingToRead : text);
  }

  Future<void> _onCall911(String heard) async {
    log!.event('call-911', {'heard': heard, 'phase': phase.name}); // trial: logged, never dialled
    await _voice?.stop();
    if (_dict != null) await _finishDictation('call-911', speak: false);
    _speaking911 = true;
    try {
      await _say(pack.promptCall911);
    } finally {
      _speaking911 = false;
    }
  }

  Future<void> _say(String text) async {
    final v = _voice;
    if (v == null) return;
    speaking = true;
    notifyListeners();
    try {
      final genMs = await v.say(text);
      log?.event('prompt', {'text': text, 'genMs': genMs});
      await Future<void>.delayed(TrialTimings.afterPromptGuard);
    } finally {
      _resetUtterance(); // drop anything heard during the prompt (the app's own voice)
      speaking = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- metrics

  Future<int?> _batteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return null; // desktop without a battery
    }
  }

  Future<void> _logMetrics() async {
    final l = _listener;
    log?.event('metrics', {
      'battery': await _batteryLevel(),
      'phase': phase.name,
      'audioSeconds': l?.audioSeconds,
      'decodeSeconds': l?.decodeSeconds,
      'rtf': (l != null && l.audioSeconds > 0) ? l.decodeSeconds / l.audioSeconds : null,
      'dictations': dictations.length,
      'micSeconds': _micSamples / sampleRate, // ~60 when the mic is alive; 0 means it stopped
      'micPeak': _micPeak,
    });
    _micSamples = 0;
    _micPeak = 0;
  }

  @override
  void dispose() {
    unawaited(stop());
    _recorder.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- matching helpers

  TrialField? matchField(String utt) {
    // Longest phrase first, so "scene info" wins over "scene".
    final candidates = <(TrialField, String)>[
      for (final e in pack.fields.entries)
        for (final p in e.value) (e.key, p)
    ]..sort((a, b) => b.$2.length.compareTo(a.$2.length));
    for (final (field, phrase) in candidates) {
      if (isCommand(utt, [phrase])) return field;
    }
    return null;
  }
}

/// Lower case, punctuation and apostrophes to spaces, single spaces. Accents are kept.
String normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();

/// A command must be (almost) the whole utterance: at most one extra word. Reduces accidental triggers.
bool isCommand(String utt, List<String> phrases) {
  final words = utt.isEmpty ? 0 : utt.split(' ').length;
  for (final p in phrases) {
    if (utt == p) return true;
    if (findPhrase(utt, [p]) >= 0 && words <= p.split(' ').length + 1) return true;
  }
  return false;
}

/// Index in [utt] where the earliest of [phrases] starts (whole words), or -1.
int findPhrase(String utt, List<String> phrases) {
  final padded = ' $utt ';
  var best = -1;
  for (final p in phrases) {
    final i = padded.indexOf(' $p ');
    if (i >= 0 && (best < 0 || i < best)) best = i;
  }
  return best; // index in padded == index in utt of the phrase start (padding offsets the leading space)
}

/// Removes an end phrase said at the end of a set-up B transcript ("... First Log end.").
String stripEndPhrase(String raw, List<String> endPhrases) {
  final words = raw.trim().split(RegExp(r'\s+'));
  for (var k = 4; k >= 1; k--) {
    if (words.length < k) continue;
    final tail = normalize(words.sublist(words.length - k).join(' '));
    if (endPhrases.contains(tail)) return words.sublist(0, words.length - k).join(' ').trim();
  }
  return raw.trim();
}

Float32List _concat(List<Float32List> parts) {
  final total = parts.fold<int>(0, (n, p) => n + p.length);
  final out = Float32List(total);
  var o = 0;
  for (final p in parts) {
    out.setRange(o, o + p.length, p);
    o += p.length;
  }
  return out;
}
