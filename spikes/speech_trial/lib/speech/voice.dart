// File path and name: spikes/speech_trial/lib/speech/voice.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Offline spoken prompts for the N1 trial: sherpa-onnx text-to-speech (Piper voice) played
//                   through audioplayers.
// Uses: package:sherpa_onnx, package:audioplayers, trial_config.dart, speech/sherpa_engines.dart.
// Used By: capture_controller.dart.
// Purpose: Say "Ready", "Proceed", "Saved" and read back text, with no internet, in EN or FR (VC-8, VC-9).

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../trial_config.dart';
import 'sherpa_engines.dart';

class Voice {
  Voice(String modelsRoot, LanguagePack pack, this._tempDir) {
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
  }

  late final sherpa.OfflineTts _tts;
  final AudioPlayer _player = AudioPlayer();
  final String _tempDir;
  int _n = 0;

  /// Generates and plays [text]; completes when playback has finished. Returns generation time in ms.
  Future<int> say(String text) async {
    final watch = Stopwatch()..start();
    final audio = _tts.generate(text: text, speed: 1.05);
    final genMs = watch.elapsedMilliseconds;
    final path = '$_tempDir${Platform.pathSeparator}prompt_${_n++ % 4}.wav';
    sherpa.writeWave(filename: path, samples: audio.samples, sampleRate: audio.sampleRate);
    final done = _player.onPlayerComplete.first;
    await _player.play(DeviceFileSource(path));
    await done.timeout(Duration(milliseconds: 1000 + audio.samples.length * 1000 ~/ audio.sampleRate),
        onTimeout: () {});
    return genMs;
  }

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
    _tts.free();
  }
}
