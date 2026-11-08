// File path and name: spikes/speech_trial/lib/background_service.dart
// Modified On Timestamp: 2026-11-08 @ 06:23 EST
// Created On Timestamp: 2026-11-08 @ 06:23 EST
// File Description: Android foreground service (type "microphone") with a persistent "Listening" notification.
// Uses: package:flutter_foreground_task (11.0.3); AndroidManifest.xml service declaration.
// Used By: capture_controller.dart, main.dart.
// Purpose: Keep the microphone and recognition running with the screen locked (VC-1). The notification is also
//          the visible listening indicator. Does nothing on other platforms.

import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_NoopTaskHandler());
}

/// The work happens in the app's main isolate; the service only keeps the process and microphone alive.
class _NoopTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

class BackgroundService {
  static bool get _supported => Platform.isAndroid;

  /// Call once at app start: notification permission, battery-optimisation exemption, service options.
  static Future<void> prepare() async {
    if (!_supported) return;
    FlutterForegroundTask.initCommunicationPort();
    if (await FlutterForegroundTask.checkNotificationPermission() != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'speech_trial_listening',
        channelName: 'Listening',
        channelDescription: 'Shown while the speech trial is listening for key phrases.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true, // CPU keeps running with the screen off
        allowWifiLock: false,
      ),
    );
  }

  /// Must be called while the app is in the foreground (Android 14+ rule for microphone services).
  static Future<void> start() async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) return;
    final result = await FlutterForegroundTask.startService(
      serviceId: 2201,
      serviceTypes: [ForegroundServiceTypes.microphone],
      notificationTitle: 'FirstLog speech trial - listening',
      notificationText: 'Microphone on. Only dictations you start are saved.',
      callback: _startCallback,
    );
    if (result is ServiceRequestFailure) {
      throw StateError('Foreground service did not start: ${result.error}');
    }
  }

  static Future<void> stop() async {
    if (!_supported) return;
    if (await FlutterForegroundTask.isRunningService) await FlutterForegroundTask.stopService();
  }
}
