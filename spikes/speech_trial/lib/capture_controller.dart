// File path and name: spikes/speech_trial/lib/capture_controller.dart
// Modified On Timestamp: 2026-11-08 @ 16:58 EST (run-2 fixes: close-match and bare "nine one one", no 9-1-1 from
//                       the app's own voice, Android echo cancellation removed, tones/vibration cues, Canary
//                       audio cut at the end phrase)
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: The trial's voice loop (decision 0002): ask "new or continuing", listen for key phrases,
//                   "Proceed" -> dictation -> end phrase / silence / next keyword / Stop -> "Saved", "Read back",
//                   and "Call 9-1-1" at any moment. Logs everything for the results.
// Uses: package:record (microphone), package:battery_plus, speech/* (Voice, Cue), trial_config.dart, trial_log.dart,
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

  /// Bias set-up A towards the key phrases (sherpa-onnx hotwords).
  bool useHotwords = true;

  /// Tones and vibration before prompts, with a silent lead-in for Bluetooth earbuds (VC-8).
  bool useCues = true;

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

  /// The prompt just spoken (normalized); its tail at the start of the next utterance is the app's own echo.
  String? _echoText;

  /// Set while a prompt that itself contains a 9-1-1 phrase (a read-back) may still be echoing; cleared at the
  /// next endpoint after it. Run 2: the app's own voice triggered "Call 9-1-1" again.
  bool _ignore911Utterance = false;

  // Current dictation.
  Dictation? _dict;
  final List<String> _dictParts = [];
  final List<Float32List> _dictAudio = [];
  int _dictSamples = 0;

  /// Where the end phrase starts in the dictation audio (samples); Canary only gets the audio before it.
  int? _dictCutAt;
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
        'hotwords': useHotwords,
        'echoCancel': false, // run 2: Android echo cancellation added phantom "and"s and removed no echo
        'cues': useCues,
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'cpus': Platform.numberOfProcessors,
        'battery': await _batteryLevel(),
      });

      final watch = Stopwatch()..start();
      final listener = SherpaStreamingRecognizer(modelsRoot, pack, hotwordsDir: useHotwords ? tempDir : null);
      _listener = listener;
      final listenerMs = watch.elapsedMilliseconds;
      if (useCanary) _canary = SherpaCanaryRecognizer(modelsRoot, pack);
      final canaryMs = watch.elapsedMilliseconds - listenerMs;
      _voice = Voice(modelsRoot, pack, tempDir, useCues: useCues);
      log!.event('models-loaded', {
        'listener': _listener!.name,
        'listenerMs': listenerMs,
        'canary': _canary?.name,
        'canaryMs': canaryMs,
        'totalMs': watch.elapsedMilliseconds,
        if (useHotwords) 'hotwords': listener.hotwords,
        if (useHotwords) 'hotwordsSkipped': listener.hotwordsSkipped,
      });

      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission refused');
      }
      await BackgroundService.start(); // Android: keeps listening with the screen locked (VC-1)
      _firstAudioLogged = false;
      _micStateSub = _recorder.onStateChanged().listen((s) => log?.event('mic-state', {'state': s.name}));
      final mic = await _recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        // The default (pause) stops the mic for good as soon as our own prompt takes the audio focus.
        audioInterruption: AudioInterruptionMode.none,
        // No Android echo cancellation ("voice communication" mode): on the S22 (run 2) it removed no echo and
        // made the recognizer hear a phantom "and" about once a second (54 times, none with it off), which
        // also stopped dictations ending on silence. The app strips its own echo itself (_stripEcho).
      ));
      _micSub = mic.listen(_onBytes, onError: (Object e) => log?.event('mic-error', {'error': '$e'}));

      _tick = Timer.periodic(const Duration(milliseconds: 500), (_) => _onTick());
      _metrics = Timer.periodic(TrialTimings.metricsEvery, (_) => _logMetrics());

      phase = Phase.askingSession;
      notifyListeners();
      await _say(pack.promptAsk, cue: Cue.start);
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
    if (phase == Phase.dictating && !speaking) {
      _dictAudio.add(samples);
      _dictSamples += samples.length;
    }
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
    var utt = normalize(res.text);
    if (res.text != _lastRaw) {
      _lastRaw = res.text;
      partial = res.text;
      if (utt.isNotEmpty && phase == Phase.dictating && !speaking) _lastWordsAt = DateTime.now();
      notifyListeners();
    }

    // "Call 9-1-1" at any moment, even mid-dictation or while the app speaks (VC-10, EM-2). Close matches
    // count too (run 2: "call mine one one"), except in the app's own echo of a prompt that contains it.
    if (!_speaking911 && !_ignore911Utterance && containsCall911(utt, pack.call911, TrialTuning.call911Ratio)) {
      _listener!.reset();
      _lastRaw = '';
      unawaited(_onCall911(utt));
      return;
    }
    if (res.isEndpoint && !speaking) _ignore911Utterance = false;

    if (speaking) {
      // The app may be hearing its own prompt: ignore everything else and discard the utterance.
      if (res.isEndpoint) _resetUtterance();
      return;
    }

    if (phase == Phase.dictating) {
      final endAt = findPhrase(utt, pack.endPhrases);
      if (endAt >= 0) {
        final before = utt.substring(0, endAt).trim();
        final cut = _cutBeforeWord(res, before.isEmpty ? 0 : before.split(' ').length, utt);
        log!.event('end-phrase', {'heard': utt, 'cutSeconds': cut});
        if (before.isNotEmpty) _dictParts.add(before);
        _resetUtterance();
        unawaited(_finishDictation('end-phrase'));
        return;
      }
      if (res.isEndpoint) {
        final clean = _stripEcho(utt);
        // A slightly misheard end phrase right before a pause ("first law end") also ends the dictation.
        final fuzzyEnd = fuzzyEndPhraseWords(clean, pack.endPhrases, TrialTuning.endPhraseLiveRatio);
        if (fuzzyEnd > 0) {
          final words = clean.split(' ');
          final cut = _cutBeforeWord(res, utt.split(' ').length - fuzzyEnd, utt);
          log!.event('end-phrase',
              {'heard': words.skip(words.length - fuzzyEnd).join(' '), 'fuzzy': true, 'cutSeconds': cut});
          final before = words.take(words.length - fuzzyEnd).join(' ');
          if (before.isNotEmpty) _dictParts.add(before);
          _resetUtterance();
          unawaited(_finishDictation('end-phrase'));
          return;
        }
        final nextField = matchField(clean);
        if (nextField != null) {
          log!.event('next-keyword', {'heard': clean, 'field': nextField.name});
          _resetUtterance();
          unawaited(_finishDictation('next-keyword', thenField: nextField));
          return;
        }
        if (clean.isNotEmpty) _dictParts.add(clean);
        _resetUtterance();
      }
      return;
    }

    if (!res.isEndpoint) return;
    _resetUtterance();
    if (utt.isEmpty) return;
    final raw = utt;
    utt = _stripEcho(utt);
    log!.event('utterance', {'phase': phase.name, 'text': utt, if (raw != utt) 'raw': raw});
    if (utt.isEmpty) return;

    // "Nine one one" on its own (the user paused after "call") - whole short utterance only (EM-2).
    if (utt.split(' ').length <= 4 && containsCall911(utt, pack.call911Bare, TrialTuning.call911Ratio)) {
      unawaited(_onCall911(utt));
      return;
    }

    if (phase == Phase.askingSession) {
      if (isCommand(utt, pack.sessionNew)) {
        unawaited(_onSession(isNew: true, heard: utt));
      } else if (isCommand(utt, pack.sessionContinue)) {
        unawaited(_onSession(isNew: false, heard: utt));
      } else {
        _logNearMiss(utt);
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
        _logNearMiss(utt);
      }
    }
  }

  /// Drops the app's own echo from the start of the first utterance after a prompt (e.g. "ing" from
  /// "continuing", "cede" from "proceed"). Never touches an utterance that is itself a key phrase.
  String _stripEcho(String utt) {
    final echo = _echoText;
    _echoText = null;
    if (echo == null || utt.isEmpty || isAnyCommand(utt, pack)) return utt;
    final cut = echoPrefixWords(utt, echo);
    if (cut == 0) return utt;
    final words = utt.split(' ');
    log!.event('echo-stripped', {'removed': words.take(cut).join(' '), 'from': utt});
    return words.skip(cut).join(' ');
  }

  /// Marks the dictation audio to be cut where word [wordIndex] of [utt] (normalized words) started, so Canary
  /// never hears the end phrase (run 2: "Firstlogin.", "Plug End."). Returns the seconds cut off, or null when
  /// the timing could not be matched to the words (then the text clean-up is the only defence).
  double? _cutBeforeWord(StreamingResult res, int wordIndex, String utt) {
    final keep = endPhraseCutSample(res, utt, wordIndex, _dictSamples);
    if (keep == null) return null;
    _dictCutAt = keep;
    return double.parse(((_dictSamples - keep) / sampleRate).toStringAsFixed(2));
  }

  /// Logs an ignored short utterance that is close to a key phrase, to show which phrases are misheard.
  void _logNearMiss(String utt) {
    if (utt.split(' ').length > 4) return;
    final m = closestCommand(utt, pack);
    if (m != null && m.$2 <= TrialTuning.nearMissRatio) {
      log!.event('near-miss', {'heard': utt, 'closest': m.$1, 'ratio': double.parse(m.$2.toStringAsFixed(2))});
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
    await _say('$ready ${pack.spokenDateTime(DateTime.now())}', cue: Cue.start);
  }

  Future<void> _startDictation(TrialField field) async {
    phase = Phase.dictating; // blocks other commands while "Proceed" is spoken
    await _say(pack.promptProceed, cue: Cue.start);
    _dict = Dictation(field: field, startedAt: DateTime.now());
    _dictParts.clear();
    _dictAudio.clear();
    _dictSamples = 0;
    _dictCutAt = null;
    _lastWordsAt = DateTime.now();
    // No reset here: it would cut off words the user starts saying right after "Proceed".
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
      var pending = normalize(_lastRaw);
      if (_dictParts.isEmpty) pending = _stripEcho(pending);
      if (pending.isNotEmpty && !containsCall911(pending, pack.call911, TrialTuning.call911Ratio)) {
        _dictParts.add(pending);
      }
      _resetUtterance();
    }

    d.endedAt = DateTime.now();
    d.endReason = reason;
    d.textA = _dictParts.join(' ').trim();
    final audio = _concat(_dictAudio);
    _dictAudio.clear();
    _dictSamples = 0;
    final seconds = audio.length / sampleRate;
    // Canary gets the audio up to the end phrase only; the saved recording stays complete (VC-3).
    final cutAt = (reason == 'end-phrase' && _dictCutAt != null && _dictCutAt! < audio.length) ? _dictCutAt! : null;
    _dictCutAt = null;
    final forCanary = cutAt == null ? audio : Float32List.sublistView(audio, 0, cutAt);

    final wav = '${log!.audioDir}${Platform.pathSeparator}${dictations.length + 1}-${d.field.name}.wav';
    if (saveWave(wav, audio)) d.audioFile = wav; // VC-3

    if (_canary != null && forCanary.isNotEmpty) {
      final w = Stopwatch()..start();
      final raw = _canary!.transcribe(forCanary);
      d.canaryMs = w.elapsedMilliseconds;
      final (textB, repeatedRemoved) = cleanCanaryText(raw, pack, endedByPhrase: reason == 'end-phrase');
      d.textB = textB;
      final c = _canary;
      log!.event('canary', {
        'rawText': raw,
        if (repeatedRemoved > 0) 'repeatedWordsRemoved': repeatedRemoved, // hallucination guard (ST-4)
        'speechSeconds': c is SherpaCanaryRecognizer ? c.lastSpeechSeconds : null,
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

    if (speak) await _say(pack.promptSaved, cue: Cue.saved);
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
      await _say(pack.promptCall911, cue: Cue.alert);
    } finally {
      _speaking911 = false;
    }
  }

  Future<void> _say(String text, {Cue cue = Cue.none}) async {
    final v = _voice;
    if (v == null) return;
    speaking = true;
    // A read-back can contain "call nine one one": its echo must not trigger a new call.
    if (containsCall911(normalize(text), pack.call911, TrialTuning.call911Ratio)) _ignore911Utterance = true;
    notifyListeners();
    try {
      final genMs = await v.say(text, cue: cue);
      log?.event('prompt', {'text': text, 'genMs': genMs, if (useCues && cue != Cue.none) 'cue': cue.name});
      await Future<void>.delayed(TrialTimings.afterPromptGuard);
    } finally {
      // Run 1: resetting here also threw away the start of whatever the user had begun to say ("scene info"
      // became "impo"). Now nothing is dropped; only an echo of the prompt's tail is stripped later.
      _echoText = normalize(text);
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

/// How many trailing words of [text] sound like one of [endPhrases] (letters compared without spaces; share
/// of differing letters at most [maxRatio]). 0 when none. Run 1: "first law end", "Firstlogin",
/// "Personal Log End".
int fuzzyEndPhraseWords(String text, List<String> endPhrases, double maxRatio) {
  final words = text.trim().split(RegExp(r'\s+'));
  var bestK = 0;
  var bestR = maxRatio;
  for (var k = 1; k <= 4 && k <= words.length; k++) {
    final tail = normalize(words.sublist(words.length - k).join(' ')).replaceAll(' ', '');
    if (tail.isEmpty) continue;
    for (final p in endPhrases) {
      final pp = p.replaceAll(' ', '');
      final r = levenshtein(tail, pp) / (tail.length > pp.length ? tail.length : pp.length);
      if (r <= bestR) {
        bestR = r;
        bestK = k;
      }
    }
  }
  return bestK;
}

/// Canary text clean-up, also used by the self-test: repetition guard (ST-4), then the end phrase removed from
/// the end - exactly, or (when the dictation was ended by it) a look-alike such as "Personal Log End".
/// Returns the text and how many repeated words were removed.
(String, int) cleanCanaryText(String raw, LanguagePack pack, {required bool endedByPhrase}) {
  final (clean, repeatedRemoved) = stripRepetition(raw);
  var text = stripEndPhrase(clean, pack.endPhrases);
  if (endedByPhrase && text == clean) {
    final k = fuzzyEndPhraseWords(text, pack.endPhrases, TrialTuning.endPhraseTextRatio);
    if (k > 0) {
      final words = text.trim().split(RegExp(r'\s+'));
      text = words.take(words.length - k).join(' ');
    }
  }
  if (endedByPhrase) {
    // The start of the end phrase left over after the audio cut ("First", "Firstlog"): 5+ letters only, so
    // "stop" in "traffic stop" is never taken for "stop dictation".
    final words = text.trim().split(RegExp(r'\s+'));
    final last = normalize(words.last).replaceAll(' ', '');
    if (words.length > 1 &&
        last.length >= 5 &&
        pack.endPhrases.any((p) => p.replaceAll(' ', '').startsWith(last))) {
      text = words.take(words.length - 1).join(' ');
    }
  }
  return (text, repeatedRemoved);
}

/// Where to cut dictation audio so it ends just before the end phrase: [nowSample] is the audio position
/// matching [res]'s "now", [wordIndex] the end phrase's first normalized word in [utt]. Null when the timing
/// cannot be matched to the words.
int? endPhraseCutSample(StreamingResult res, String utt, int wordIndex, int nowSample) {
  final starts = normalizedWordStarts(res.words);
  final count = utt.isEmpty ? 0 : utt.split(' ').length;
  if (starts.length != count || wordIndex < 0 || wordIndex >= starts.length) return null;
  final back = res.secondsSinceReset - starts[wordIndex] + TrialTuning.endPhraseTimingLag.inMilliseconds / 1000;
  final cut = nowSample - (back * sampleRate).round();
  return (cut <= 0 || cut >= nowSample) ? null : cut;
}

/// True if [utt] contains one of the 9-1-1 [phrases], exactly or within [maxRatio] (share of letters that
/// differ, spaces ignored) over any run of words of about the phrase's length. Run 2 misses: "call mine one
/// one", "carlvine one one", "all nine one one".
bool containsCall911(String utt, List<String> phrases, double maxRatio) {
  if (utt.isEmpty) return false;
  if (findPhrase(utt, phrases) >= 0) return true;
  final words = utt.split(' ');
  for (final p in phrases) {
    final pp = p.replaceAll(' ', '');
    final n = p.split(' ').length;
    for (var len = n - 1; len <= n + 1; len++) {
      if (len < 1) continue;
      for (var i = 0; i + len <= words.length; i++) {
        final w = words.sublist(i, i + len).join();
        if ((w.length - pp.length).abs() > pp.length * maxRatio) continue;
        final r = levenshtein(w, pp) / (w.length > pp.length ? w.length : pp.length);
        if (r <= maxRatio) return true;
      }
    }
  }
  return false;
}

/// Start time of each normalized word, from the engine's raw words (a raw word like "WASN'T" becomes two
/// normalized words with the same start), so indexes match `normalize(text).split(' ')`.
List<double> normalizedWordStarts(List<(String, double)> words) => [
      for (final (w, t) in words)
        for (final _ in normalize(w).split(' ').where((s) => s.isNotEmpty)) t,
    ];

/// True if [utt] is any key phrase of [pack] (same rule as [isCommand]).
bool isAnyCommand(String utt, LanguagePack pack) => isCommand(utt, pack.allCommands);

/// How many leading words of [utt] are the app's own echo of [prompt]'s tail (letters compared without spaces,
/// allowing small recognition errors). 0 when there is none. One short leading word before the echo is
/// included: the cue tone is sometimes heard as a word ("els proceed", "des allés y").
int echoPrefixWords(String utt, String prompt, {bool allowToneWord = true}) {
  final words = utt.split(' ');
  final p = prompt.replaceAll(' ', '');
  for (var k = words.length; k >= 1; k--) {
    final s = words.take(k).join();
    if (s.isEmpty || s.length > p.length + 2) continue;
    // Heard text a letter or two longer than the whole prompt ("enregistrée") is compared with all of it.
    final tail = s.length >= p.length ? p : p.substring(p.length - s.length);
    final allowed = s.length <= 3 ? 0 : (s.length <= 6 ? 2 : s.length ~/ 3);
    if (levenshtein(s, tail) <= allowed) return k;
  }
  if (allowToneWord && words.length >= 2 && words.first.length <= 4) {
    final rest = echoPrefixWords(words.skip(1).join(' '), prompt, allowToneWord: false);
    if (rest > 0) return rest + 1;
  }
  return 0;
}

/// The key phrase closest to [utt] and the share of letters that differ (0 = identical).
(String, double)? closestCommand(String utt, LanguagePack pack) {
  final u = utt.replaceAll(' ', '');
  if (u.isEmpty) return null;
  (String, double)? best;
  for (final c in pack.allCommands) {
    final cc = c.replaceAll(' ', '');
    final r = levenshtein(u, cc) / (u.length > cc.length ? u.length : cc.length);
    if (best == null || r < best.$2) best = (c, r);
  }
  return best;
}

/// Edit distance between two strings.
int levenshtein(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final del = prev[j] + 1, ins = cur[j - 1] + 1, sub = prev[j - 1] + cost;
      cur[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    prev = cur;
  }
  return prev[b.length];
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
