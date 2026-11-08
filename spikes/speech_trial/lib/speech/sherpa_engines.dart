// File path and name: spikes/speech_trial/lib/speech/sherpa_engines.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: sherpa-onnx implementations of the trial's speech interfaces: streaming zipformer
//                   (set-up A) and NeMo Canary-180m-flash (set-up B).
// Uses: package:sherpa_onnx (2.0.1), speech/speech_engine.dart, trial_config.dart.
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

class SherpaStreamingRecognizer implements StreamingRecognizer {
  SherpaStreamingRecognizer(String modelsRoot, LanguagePack pack, {int numThreads = 2}) {
    ensureSherpaBindings();
    final dir = '$modelsRoot${Platform.pathSeparator}${pack.streamingModelDir}';
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
    );
    _recognizer = sherpa.OnlineRecognizer(config);
    _stream = _recognizer.createStream();
    name = 'sherpa-streaming:${pack.streamingModelDir}';
  }

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
    final text = _recognizer.getResult(_stream).text;
    final endpoint = _recognizer.isEndpoint(_stream);
    _decodeWatch.stop();
    return StreamingResult(text, isEndpoint: endpoint);
  }

  @override
  void reset() => _recognizer.reset(_stream);

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

  @override
  String get name => 'sherpa-canary:$canaryModelDir';

  @override
  String transcribe(Float32List samples) {
    // Crude fixed-length split for long dictations (TrialTimings.canaryMaxChunk); may cut a word in two.
    final maxLen = TrialTimings.canaryMaxChunk.inMilliseconds * sampleRate ~/ 1000;
    final parts = <String>[];
    for (var start = 0; start < samples.length; start += maxLen) {
      final end = (start + maxLen < samples.length) ? start + maxLen : samples.length;
      final stream = _recognizer.createStream();
      stream.acceptWaveform(samples: Float32List.sublistView(samples, start, end), sampleRate: sampleRate);
      _recognizer.decode(stream);
      parts.add(_recognizer.getResult(stream).text.trim());
      stream.free();
    }
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  @override
  void dispose() => _recognizer.free();
}

/// Saves a dictation's audio next to its transcript (VC-3).
bool saveWave(String path, Float32List samples) =>
    sherpa.writeWave(filename: path, samples: samples, sampleRate: sampleRate);
