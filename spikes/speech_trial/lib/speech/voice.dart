// File path and name: spikes/speech_trial/lib/speech/voice.dart
// Modified On Timestamp: 2026-11-08 @ 16:58 EST (tones, vibration and a silent Bluetooth lead-in before prompts)
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Offline spoken prompts for the N1 trial: sherpa-onnx text-to-speech (Piper voice) played
//                   through audioplayers, optionally preceded by a short tone and a vibration (a "cue").
// Uses: package:sherpa_onnx, package:audioplayers, package:vibration, trial_config.dart,
//       speech/sherpa_engines.dart.
// Used By: capture_controller.dart, self_test.dart (cueSamples).
// Purpose: Say "Ready", "Proceed", "Saved" and read back text, with no internet, in EN or FR (VC-8, VC-9);
//          tones and vibration tell the user what happened without looking at the screen, even when earbuds
//          drop the start of a short prompt (run 2).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:vibration/vibration.dart';

import '../trial_config.dart';
import 'sherpa_engines.dart';

/// What a prompt means, for its tone and vibration.
enum Cue { none, start, saved, alert }

/// Silent lead-in plus the cue's tones, at [rate] Hz. With [Cue.none] only the lead-in (it still helps a
/// sleeping Bluetooth link).
Float32List cueSamples(Cue cue, int rate) {
  final pitches = switch (cue) {
    Cue.none => const <double>[],
    Cue.start => TrialCues.start,
    Cue.saved => TrialCues.saved,
    Cue.alert => TrialCues.alert,
  };
  final lead = TrialCues.leadIn.inMilliseconds * rate ~/ 1000;
  final tone = TrialCues.toneMs * rate ~/ 1000;
  final gap = TrialCues.gapMs * rate ~/ 1000;
  final out = Float32List(lead + pitches.length * (tone + gap));
  var o = lead;
  final fade = rate ~/ 200; // 5 ms fade in/out, so the tones do not click
  for (final hz in pitches) {
    for (var i = 0; i < tone; i++) {
      final env = math.min(1.0, math.min(i, tone - 1 - i) / fade);
      out[o + i] = TrialCues.volume * env * math.sin(2 * math.pi * hz * i / rate);
    }
    o += tone + gap;
  }
  return out;
}

class Voice {
  Voice(String modelsRoot, LanguagePack pack, this._tempDir, {this.useCues = true}) {
    ensureSherpaBindings();
    final sep = Platform.pathSeparator;
    final dir = '$modelsRoot$sep${pack.voiceDir}';
    final model = Directory(dir)
        .listSync()
        .whereType<File>()
        .firstWhere((f) => f.path.endsWith('.onnx'),
            orElse: () => throw StateError('No voice model in $dir - run tool/download_models.ps1'))
        .path;
    _tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
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
    _player.setReleaseMode(ReleaseMode.stop);
    // Play without taking the audio focus, so the microphone keeps running during prompts.
    _player.setAudioContext(AudioContext(android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none)));
  }

  /// Tones and vibration before prompts (off: spoken prompts only, as in runs 1-2).
  final bool useCues;

  late final sherpa.OfflineTts _tts;
  final AudioPlayer _player = AudioPlayer();
  final String _tempDir;
  int _n = 0;

  /// Generates and plays [text] (after the lead-in and [cue] tones); completes when playback has finished.
  /// Returns generation time in ms.
  Future<int> say(String text, {Cue cue = Cue.none}) async {
    final watch = Stopwatch()..start();
    final audio = _tts.generate(text: text, speed: 1.05);
    final genMs = watch.elapsedMilliseconds;
    final pre = cueSamples(useCues ? cue : Cue.none, audio.sampleRate);
    final samples = Float32List(pre.length + audio.samples.length)
      ..setRange(0, pre.length, pre)
      ..setRange(pre.length, pre.length + audio.samples.length, audio.samples);
    final path = '$_tempDir${Platform.pathSeparator}prompt_${_n++ % 4}.wav';
    sherpa.writeWave(filename: path, samples: samples, sampleRate: audio.sampleRate);
    if (useCues && cue != Cue.none) await _vibrate(cue);
    // then<void>: onPlayerComplete.first is a Future<AudioEvent> at run time, so a void onTimeout on it fails.
    final done = _player.onPlayerComplete.first.then<void>((_) {});
    await _player.play(DeviceFileSource(path));
    await done.timeout(Duration(milliseconds: 1000 + samples.length * 1000 ~/ audio.sampleRate), onTimeout: () {});
    return genMs;
  }

  Future<void> _vibrate(Cue cue) async {
    final pattern = switch (cue) {
      Cue.start => TrialCues.vibrateStart,
      Cue.saved => TrialCues.vibrateSaved,
      Cue.alert => TrialCues.vibrateAlert,
      Cue.none => const <int>[],
    };
    try {
      if (pattern.isNotEmpty && await Vibration.hasVibrator()) await Vibration.vibrate(pattern: pattern);
    } catch (_) {
      // Desktop: no vibrator plugin. Never let a cue stop a prompt.
    }
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
    _tts.free();
  }
}
