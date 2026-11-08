// File path and name: spikes/speech_trial/lib/speech/speech_engine.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Engine-neutral interfaces for speech recognition in the N1 trial.
// Uses: dart:typed_data.
// Used By: capture_controller.dart (consumer), speech/sherpa_engines.dart (implementations).
// Purpose: Let engines be swapped (sherpa-onnx streaming, sherpa-onnx Canary, later Vosk or others - N6)
//          without touching the capture logic (CLAUDE.md: code against a speech-engine interface).

import 'dart:typed_data';

/// Text so far for the current utterance.
class StreamingResult {
  const StreamingResult(this.text, {required this.isEndpoint});

  /// Recognized text of the current utterance (since the last endpoint / reset).
  final String text;

  /// True when the engine decided the utterance ended (trailing silence). The caller then calls [reset].
  final bool isEndpoint;
}

/// Gives text while the user speaks. Used for key-phrase listening (VC-1, VC-4) and set-up A dictation.
abstract class StreamingRecognizer {
  String get name;

  /// Feed 16 kHz mono samples in [-1, 1]. Returns the current result.
  StreamingResult accept(Float32List samples);

  /// Start a fresh utterance (after an endpoint, a prompt, or a state change).
  void reset();

  /// Seconds spent decoding since creation (for the real-time factor).
  double get decodeSeconds;

  /// Seconds of audio accepted since creation.
  double get audioSeconds;

  void dispose();
}

/// Turns a finished piece of audio into text. Used for set-up B dictation (phrase by phrase).
abstract class SegmentRecognizer {
  String get name;

  /// [samples] are 16 kHz mono in [-1, 1].
  String transcribe(Float32List samples);

  void dispose();
}
