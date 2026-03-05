import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../platform/screen_wake_channel.dart';
import 'foreground_task_handler.dart';

void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'pulse_timer',
      channelName: 'Pulse Timer',
      channelDescription: 'Pulse timer HTTP server',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(5000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
    ),
  );
}

Future<void> startForegroundTask() async {
  if (!await FlutterForegroundTask.isRunningService) {
    final result = await FlutterForegroundTask.startService(
      serviceId: 7878,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Pulse',
      notificationText: 'Listening on port 7878',
      callback: startCallback,
    );
    if (result is ServiceRequestFailure) {
      debugPrint('Foreground service failed to start: ${result.error}');
    } else {
      debugPrint('Foreground service started OK');
    }
  } else {
    debugPrint('Foreground service already running');
  }
}

void registerTaskDataCallback(ProviderContainer container) {
  FlutterForegroundTask.addTaskDataCallback((data) {
    if (data is! Map<String, dynamic>) return;
    final action = data['action'] as String?;

    switch (action) {
      case 'start':
        final duration = data['duration'] as int? ?? 60;
        final label = data['label'] as String? ?? '';
        final sound = data['sound'] as bool? ?? true;

        container.read(timerProvider.notifier).startTimer(
              durationSeconds: duration,
              label: label,
              sound: sound,
            );

        _pushStatusUpdate(container);
        ScreenWakeChannel.wakeScreen();
        navigatorKey.currentState?.pushReplacementNamed('/timer');

      case 'stop':
        container.read(timerProvider.notifier).stopTimer();
        _pushStatusUpdate(container);
        navigatorKey.currentState?.pushReplacementNamed('/');

      case 'statusRequest':
        _pushStatusUpdate(container);

      case 'settings':
        final themeStr = data['theme'] as String?;
        if (themeStr != null) {
          final theme = themeStr == 'ambient' ? AppTheme.ambient : AppTheme.dark;
          container.read(settingsProvider.notifier).setTheme(theme);
        }
        final sound = data['sound'] as bool?;
        if (sound != null) {
          container.read(settingsProvider.notifier).setSoundDefault(sound);
        }
    }
  });
}

void _pushStatusUpdate(ProviderContainer container) {
  final state = container.read(timerProvider);
  FlutterForegroundTask.sendDataToTask({
    'action': 'statusUpdate',
    'running': state.status == TimerStatus.running,
    'remaining': state.remainingSeconds,
    'label': state.label,
  });
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PulseTaskHandler());
}
