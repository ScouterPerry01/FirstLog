// File path and name: spikes/speech_trial/lib/trial_log.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Append-only JSON-lines log for one trial run, plus a short in-memory tail for the screen.
// Uses: dart:io, dart:convert.
// Used By: capture_controller.dart, main.dart.
// Purpose: Record every recognized utterance, command, dictation, timing and battery reading so results can be
//          analysed after the run (docs/spikes/n1-speech-trial-results.md). Logs stay on the device / PC.

import 'dart:convert';
import 'dart:io';

class TrialLog {
  TrialLog._(this.runDir, this._sink);

  /// Creates `<logsRoot>/run-YYYYMMDD-HHMMSS/` with `events.jsonl` and an `audio/` folder.
  static Future<TrialLog> open(String logsRoot) async {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name = 'run-${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
    final dir = Directory('$logsRoot${Platform.pathSeparator}$name');
    await Directory('${dir.path}${Platform.pathSeparator}audio').create(recursive: true);
    final sink = File('${dir.path}${Platform.pathSeparator}events.jsonl').openWrite(mode: FileMode.append);
    return TrialLog._(dir.path, sink);
  }

  final String runDir;
  final IOSink _sink;
  final List<String> tail = [];

  String get audioDir => '$runDir${Platform.pathSeparator}audio';

  void event(String type, [Map<String, Object?> data = const {}]) {
    final now = DateTime.now();
    _sink.writeln(jsonEncode({'t': now.toIso8601String(), 'type': type, ...data}));
    final hhmmss = now.toIso8601String().substring(11, 19);
    tail.add('$hhmmss $type ${data.isEmpty ? '' : jsonEncode(data)}');
    if (tail.length > 60) tail.removeAt(0);
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
