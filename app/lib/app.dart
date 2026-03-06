import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'services/foreground_service.dart';
import 'services/device_discovery.dart';
import 'screens/idle_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_themes.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = themeMap[settings.theme.name] ?? darkTheme;

    return MaterialApp(
      title: 'Pulse',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const _AppRoot(),
      routes: {
        '/timer': (_) => const TimerScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

class _AppRoot extends ConsumerStatefulWidget {
  const _AppRoot();

  @override
  ConsumerState<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<_AppRoot> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    initForegroundTask();

    final perm = await FlutterForegroundTask.checkNotificationPermission();
    debugPrint('Notification permission: $perm');
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    await startForegroundTask();

    // Start device discovery for multi-device sync
    ref.read(deviceDiscoveryProvider.notifier).startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return const IdleScreen();
  }
}
