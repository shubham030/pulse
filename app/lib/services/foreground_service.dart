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
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.pulse.notification_icon',
      ),
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
  // Push full status to task handler on every timer state change (for WS broadcast)
  container.listen(timerProvider, (prev, next) {
    if (prev == next) return;
    _pushFullStatus(next);
  });

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
        ScreenWakeChannel.wakeScreen();
        navigatorKey.currentState?.pushReplacementNamed('/timer');

      case 'stop':
        container.read(timerProvider.notifier).stopTimer();
        navigatorKey.currentState?.pushReplacementNamed('/');

      case 'pause':
        container.read(timerProvider.notifier).pauseTimer();

      case 'resume':
        container.read(timerProvider.notifier).resumeTimer();

      case 'skip':
        container.read(timerProvider.notifier).skipTimer();

      case 'enqueue':
        final duration = data['duration'] as int? ?? 60;
        final label = data['label'] as String? ?? '';
        final sound = data['sound'] as bool? ?? true;
        container.read(timerProvider.notifier).enqueueTimer(
              durationSeconds: duration,
              label: label,
              sound: sound,
            );
        // If timer just started from idle, navigate to timer screen
        final state = container.read(timerProvider);
        if (state.status == TimerStatus.running) {
          ScreenWakeChannel.wakeScreen();
          navigatorKey.currentState?.pushReplacementNamed('/timer');
        }

      case 'removeFromQueue':
        final index = data['index'] as int? ?? -1;
        container.read(timerProvider.notifier).removeFromQueue(index);

      case 'clearQueue':
        container.read(timerProvider.notifier).clearQueue();

      case 'pomodoro':
        final config = PomodoroConfig(
          focusMinutes: data['focusMinutes'] as int? ?? 25,
          shortBreakMinutes: data['shortBreakMinutes'] as int? ?? 5,
          longBreakMinutes: data['longBreakMinutes'] as int? ?? 15,
          cyclesBeforeLongBreak: data['cyclesBeforeLongBreak'] as int? ?? 4,
          totalCycles: data['totalCycles'] as int? ?? 4,
        );
        container.read(timerProvider.notifier).startPomodoro(config);
        ScreenWakeChannel.wakeScreen();
        navigatorKey.currentState?.pushReplacementNamed('/timer');

      case 'statusRequest':
        _pushFullStatus(container.read(timerProvider));

      case 'settings':
        final themeStr = data['theme'] as String?;
        if (themeStr != null) {
          final theme = AppTheme.values
                  .where((t) => t.name == themeStr)
                  .firstOrNull ??
              AppTheme.dark;
          container.read(settingsProvider.notifier).setTheme(theme);
        }
        final sound = data['sound'] as bool?;
        if (sound != null) {
          container.read(settingsProvider.notifier).setSoundDefault(sound);
        }
    }
  });
}

void _pushFullStatus(TimerState state) {
  FlutterForegroundTask.sendDataToTask({
    'action': 'statusUpdate',
    ...state.toStatusJson(),
  });
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(PulseTaskHandler());
}
