// File path and name: spikes/speech_trial/lib/self_test.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Hands-off check of the trial's engines: runs the models' sample recordings and key phrases
//                   spoken by the offline voice through set-up A (streaming) and B (Canary), EN and FR, and
//                   prints the recognized text and speed.
// Uses: speech/sherpa_engines.dart, trial_config.dart, capture_controller.dart (matching helpers), sherpa_onnx.
// Used By: main.dart when started with --selftest (desktop: flutter run -d windows -a --selftest).
// Purpose: Prove the engine code works before anyone speaks to it; a first, rough read on key-phrase matching.
//          Synthetic speech is far easier than real speech at a scene - these numbers are NOT trial results.

import 'dart:io';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'capture_controller.dart';
import 'speech/sherpa_engines.dart';
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
    final a = SherpaStreamingRecognizer(modelsRoot, pack);
    p('streaming model loaded at ${w.elapsedMilliseconds} ms');
    final b = SherpaCanaryRecognizer(modelsRoot, pack);
    p('Canary loaded at ${w.elapsedMilliseconds} ms');
    final tts = _tts(modelsRoot, pack);
    p('voice loaded at ${w.elapsedMilliseconds} ms');

    // 1. Sample recordings shipped with the streaming model (real speech).
    final wavDir = Directory('$modelsRoot$sep${pack.streamingModelDir}${sep}test_wavs');
    if (wavDir.existsSync()) {
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
    a.dispose();
    b.dispose();
    tts.free();
  }
  p('done');
}

void _report(void Function(String) p, String label, Float32List samples, SherpaStreamingRecognizer a,
    SherpaCanaryRecognizer b, LanguagePack pack) {
  final secs = samples.length / sampleRate;

  // Set-up A: feed 100 ms chunks plus 1.5 s of silence, collect text at each endpoint.
  a.reset();
  final dec0 = a.decodeSeconds;
  final parts = <String>[];
  final chunk = sampleRate ~/ 10;
  final padded = Float32List(samples.length + sampleRate * 3 ~/ 2)..setRange(0, samples.length, samples);
  var last = '';
  for (var i = 0; i < padded.length; i += chunk) {
    final end = (i + chunk < padded.length) ? i + chunk : padded.length;
    final r = a.accept(Float32List.sublistView(padded, i, end));
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
  p('    B: "$textB"  rtf ${rtfB.toStringAsFixed(2)}  stripped: "${stripEndPhrase(textB, pack.endPhrases)}"');
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
