// File path and name: spikes/speech_trial/lib/self_test.dart
// Modified On Timestamp: 2026-11-08 @ 16:58 EST (word-timing probe, cue-tone echo check, Canary on audio cut at
//                       the end phrase)
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Hands-off check of the trial's engines: runs the models' sample recordings, key phrases
//                   spoken by the offline voice, and dictations recorded on the phone (trial-logs/run-*/audio)
//                   through set-up A (streaming) and B (Canary), EN and FR, and prints the text and speed.
// Uses: speech/sherpa_engines.dart, trial_config.dart, capture_controller.dart (matching helpers), sherpa_onnx.
// Used By: main.dart when started with --selftest (desktop: flutter run -d windows -a --selftest).
// Purpose: Prove the engine code works before anyone speaks to it; a first, rough read on key-phrase matching.
//          Synthetic speech is far easier than real speech at a scene - these numbers are NOT trial results.

import 'dart:io';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'capture_controller.dart';
import 'speech/sherpa_engines.dart';
import 'speech/speech_engine.dart';
import 'speech/voice.dart';
import 'trial_config.dart';

/// Writes each line to [reportPath] straight away, so a crash or hang still shows how far it got.
Future<void> runSelfTest(String modelsRoot, String reportPath) async {
  final report = File(reportPath)..writeAsStringSync('');
  void p(String s) => report.writeAsStringSync('$s\n', mode: FileMode.append, flush: true);

  ensureSherpaBindings();
  final sep = Platform.pathSeparator;

  for (final lang in TrialLanguage.values) {
    final pack = packFor(lang);
    p('=== ${pack.code.toUpperCase()} ===');
    final w = Stopwatch()..start();
    final a = SherpaStreamingRecognizer(modelsRoot, pack, hotwordsDir: File(reportPath).parent.path);
    p('streaming model loaded at ${w.elapsedMilliseconds} ms (${a.name})');
    a.hotwords.forEach((k, v) => p('  hotword "$k" -> $v'));
    if (a.hotwordsSkipped.isNotEmpty) p('  hotwords skipped: ${a.hotwordsSkipped.join(', ')}');
    final b = SherpaCanaryRecognizer(modelsRoot, pack);
    p('Canary loaded at ${w.elapsedMilliseconds} ms (${b.name})');
    final tts = _tts(modelsRoot, pack);
    p('voice loaded at ${w.elapsedMilliseconds} ms');

    // 1. Sample recordings shipped with the streaming model (real speech).
    final wavDir = Directory('$modelsRoot$sep${pack.streamingModelDir}${sep}test_wavs');
    if (wavDir.existsSync()) {
      final firstWav = wavDir.listSync().whereType<File>().firstWhere((f) => f.path.endsWith('.wav'));
      _probe(p, a, tts, pack, sherpa.readWave(firstWav.path).samples);
      for (final f in wavDir.listSync().whereType<File>().where((f) => f.path.endsWith('.wav')).take(2)) {
        final wave = sherpa.readWave(f.path);
        if (wave.sampleRate != sampleRate) continue;
        _report(p, f.uri.pathSegments.last, wave.samples, a, b, pack);
      }
    }

    // 2. Key phrases and a dictation, spoken by the offline voice (synthetic speech).
    final phrases = [
      pack.sessionNew.first,
      pack.fields[TrialField.scene]!.first,
      pack.fields[TrialField.vitals]!.first,
      pack.readBack.first,
      pack.call911.first,
      pack.code == 'fr'
          ? 'pouls cent dix, respiration vingt-quatre, ${pack.endPhrases.first}'
          : 'pulse one hundred ten, breathing twenty four, ${pack.endPhrases.first}',
    ];
    for (final phrase in phrases) {
      final audio = tts.generate(text: phrase, speed: 1.0);
      p('  (voice: ${audio.samples.length} samples at ${audio.sampleRate} Hz)');
      final samples = _resample(audio.samples, audio.sampleRate, sampleRate);
      _report(p, 'voice: "$phrase"', samples, a, b, pack);
    }

    // 3. Real dictations recorded on the phone (pulled with push_models_android.ps1 -PullLogs), same language.
    final logs = File(reportPath).parent;
    for (final run in logs.listSync().whereType<Directory>().where((d) => d.path.contains('run-'))) {
      final events = File('${run.path}${sep}events.jsonl');
      final audio = Directory('${run.path}${sep}audio');
      if (!events.existsSync() || !audio.existsSync()) continue;
      if (!events.readAsLinesSync().first.contains('"language":"${pack.code}"')) continue;
      for (final f in audio.listSync().whereType<File>().where((f) => f.path.endsWith('.wav'))) {
        final wave = sherpa.readWave(f.path);
        if (wave.sampleRate != sampleRate || wave.samples.isEmpty) continue;
        _report(p, 'phone: ${run.uri.pathSegments.where((s) => s.isNotEmpty).last}/${f.uri.pathSegments.last}',
            wave.samples, a, b, pack);
      }
    }
    a.dispose();
    b.dispose();
    tts.free();
  }
  p('done');
}

void _report(void Function(String) p, String label, Float32List samples, SherpaStreamingRecognizer a,
    SherpaCanaryRecognizer b, LanguagePack pack) {
  final secs = samples.length / sampleRate;

  // Set-up A: feed 100 ms chunks plus 1.5 s of silence, collect text at each endpoint. Like the app, note
  // where the end phrase starts (word times) so Canary can be given the audio before it only.
  a.reset();
  final dec0 = a.decodeSeconds;
  final parts = <String>[];
  final chunk = sampleRate ~/ 10;
  final padded = Float32List(samples.length + sampleRate * 3 ~/ 2)..setRange(0, samples.length, samples);
  var last = '';
  (StreamingResult, String, int, int)? endHit; // result, utterance, end-phrase word index, audio position
  for (var i = 0; i < padded.length; i += chunk) {
    final end = (i + chunk < padded.length) ? i + chunk : padded.length;
    final r = a.accept(Float32List.sublistView(padded, i, end));
    final u = normalize(r.text);
    final endAt = findPhrase(u, pack.endPhrases);
    if (endHit == null && endAt >= 0) {
      endHit = (r, u, endAt == 0 ? 0 : u.substring(0, endAt).trim().split(' ').length, end);
    }
    last = r.text;
    if (r.isEndpoint) {
      if (r.text.trim().isNotEmpty) parts.add(r.text.trim());
      a.reset();
      last = '';
    }
  }
  if (last.trim().isNotEmpty) parts.add(last.trim());
  final textA = normalize(parts.join(' '));
  final rtfA = (a.decodeSeconds - dec0) / (padded.length / sampleRate);

  final w = Stopwatch()..start();
  final textB = b.transcribe(samples);
  final rtfB = w.elapsedMilliseconds / 1000 / secs;

  final match = <String>[
    if (findPhrase(textA, pack.endPhrases) >= 0) 'end-phrase',
    if (findPhrase(textA, pack.call911) >= 0) 'call-911',
    if (isCommand(textA, pack.sessionNew)) 'new',
    if (isCommand(textA, pack.readBack)) 'read-back',
    for (final e in pack.fields.entries)
      if (e.value.any((ph) => isCommand(textA, [ph]))) 'field:${e.key.name}',
  ];
  p('- $label (${secs.toStringAsFixed(1)} s)');
  p('    A: "$textA"  rtf ${rtfA.toStringAsFixed(2)}  matches: ${match.isEmpty ? '-' : match.join(', ')}');
  p('    B: decoding…');
  final (clean, removed) = stripRepetition(textB);
  p('    B: "$textB"  rtf ${rtfB.toStringAsFixed(2)}  speech ${b.lastSpeechSeconds?.toStringAsFixed(1)} s'
      '${removed > 0 ? '  REPETITION REMOVED: $removed words' : ''}');
  p('    B final (text clean-up only): "${cleanCanaryText(textB, pack, endedByPhrase: endHit != null).$1}"');
  // Canary on the audio cut before the end phrase, for several timing lags (picks TrialTuning value).
  if (endHit != null) {
    final keep = TrialTuning.endPhraseTimingLag;
    for (final ms in [0, 200, 300, 400, 600]) {
      TrialTuning.endPhraseTimingLag = Duration(milliseconds: ms);
      final cut = endPhraseCutSample(endHit.$1, endHit.$2, endHit.$3, endHit.$4);
      if (cut == null || cut > samples.length) {
        p('    B cut lag $ms ms: (timing not matched)');
        continue;
      }
      final raw = b.transcribe(Float32List.sublistView(samples, 0, cut));
      p('    B cut lag $ms ms at ${(cut / sampleRate).toStringAsFixed(2)} s: raw "$raw" -> '
          '"${cleanCanaryText(raw, pack, endedByPhrase: true).$1}"');
    }
    TrialTuning.endPhraseTimingLag = keep;
  }
}

/// Is sherpa's token time counted from the last reset or from stream creation? And does a cue tone (plus the
/// prompt after it) come back from set-up A as words that would defeat the echo strip?
void _probe(void Function(String) p, SherpaStreamingRecognizer a, sherpa.OfflineTts tts, LanguagePack pack,
    Float32List speech) {
  a.reset();
  a.accept(Float32List(sampleRate * 2)); // 2 s of silence, then a reset
  a.reset();
  StreamingResult? r;
  for (var i = 0; i < speech.length; i += sampleRate ~/ 10) {
    final e = i + sampleRate ~/ 10 < speech.length ? i + sampleRate ~/ 10 : speech.length;
    r = a.accept(Float32List.sublistView(speech, i, e));
  }
  final firstWords = r!.words.take(3).map((w) => '${w.$1}@${w.$2.toStringAsFixed(2)}').join(' ');
  p('  timing probe after a reset: $firstWords (since reset ${r.secondsSinceReset.toStringAsFixed(2)} s)'
      '${timestampsCountFromCreation ? ' [offset applied]' : ''}');

  for (final (cue, text) in [(Cue.start, pack.promptProceed), (Cue.saved, pack.promptSaved)]) {
    final audio = tts.generate(text: text, speed: 1.05);
    final pre = cueSamples(cue, audio.sampleRate);
    final all = Float32List(pre.length + audio.samples.length)
      ..setRange(0, pre.length, pre)
      ..setRange(pre.length, pre.length + audio.samples.length, audio.samples);
    final s = _resample(all, audio.sampleRate, sampleRate);
    a.reset();
    final padded = Float32List(s.length + sampleRate)..setRange(0, s.length, s);
    var text0 = '';
    for (var i = 0; i < padded.length; i += sampleRate ~/ 10) {
      final e = i + sampleRate ~/ 10 < padded.length ? i + sampleRate ~/ 10 : padded.length;
      text0 = a.accept(Float32List.sublistView(padded, i, e)).text;
    }
    final heard = normalize(text0);
    final cut = echoPrefixWords(heard, normalize(text));
    p('  cue ${cue.name} + "$text" heard by A as "$heard" -> echo strip removes $cut of '
        '${heard.isEmpty ? 0 : heard.split(' ').length} words');
  }
  a.reset();
}

sherpa.OfflineTts _tts(String modelsRoot, LanguagePack pack) {
  final sep = Platform.pathSeparator;
  final dir = '$modelsRoot$sep${pack.voiceDir}';
  final model = Directory(dir).listSync().whereType<File>().firstWhere((f) => f.path.endsWith('.onnx')).path;
  return sherpa.OfflineTts(sherpa.OfflineTtsConfig(
    model: sherpa.OfflineTtsModelConfig(
      vits: sherpa.OfflineTtsVitsModelConfig(
        model: model,
        tokens: '$dir${sep}tokens.txt',
        dataDir: '$dir${sep}espeak-ng-data',
      ),
      numThreads: 2,
      debug: false,
    ),
  ));
}

/// Linear resampling - good enough for a self-test.
Float32List _resample(Float32List x, int from, int to) {
  if (from == to) return x;
  final n = (x.length * to / from).floor();
  final y = Float32List(n);
  for (var i = 0; i < n; i++) {
    final pos = i * from / to;
    final j = pos.floor();
    final f = pos - j;
    final a = x[j];
    final b = j + 1 < x.length ? x[j + 1] : a;
    y[i] = a + (b - a) * f;
  }
  return y;
}
