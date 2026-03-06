import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';
import '../providers/settings_provider.dart';
import '../services/device_discovery.dart';
import '../theme/app_themes.dart';
import '../app.dart';
import '../widgets/timer_input_sheet.dart';

const _presets = [
  (label: 'Short Break', minutes: 5),
  (label: 'Focus', minutes: 25),
  (label: 'Long Break', minutes: 15),
  (label: 'Deep Work', minutes: 90),
];

class IdleScreen extends ConsumerStatefulWidget {
  const IdleScreen({super.key});

  @override
  ConsumerState<IdleScreen> createState() => _IdleScreenState();
}

class _IdleScreenState extends ConsumerState<IdleScreen> {
  String _ip = '';

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            if (mounted) setState(() => _ip = addr.address);
            return;
          }
        }
      }
    } catch (_) {}
  }

  void _startPreset(String label, int minutes) {
    final sound = ref.read(settingsProvider).soundDefault;
    ref.read(timerProvider.notifier).startTimer(
          durationSeconds: minutes * 60,
          label: label,
          sound: sound,
        );
    _syncToDevices({'action': 'start', 'duration': minutes * 60, 'label': label, 'sound': sound});
    navigatorKey.currentState?.pushReplacementNamed('/timer');
  }

  void _startPomodoro() {
    ref.read(timerProvider.notifier).startPomodoro(const PomodoroConfig());
    _syncToDevices({
      'action': 'pomodoro',
      '_path': '/pomodoro',
    });
    navigatorKey.currentState?.pushReplacementNamed('/timer');
  }

  void _openCustomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TimerInputSheet(),
    );
  }

  void _openSettings() {
    Navigator.of(context).pushNamed('/settings');
  }

  void _syncToDevices(Map<String, dynamic> command) {
    final settings = ref.read(settingsProvider);
    if (settings.syncToDevices) {
      ref.read(deviceDiscoveryProvider.notifier).broadcastToDevices({...command});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pulse = context.pulse;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final devices = ref.watch(deviceDiscoveryProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: pulse.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'PULSE',
                      style: TextStyle(
                        color: pulse.accentColor,
                        fontSize: 13,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (devices.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.devices,
                          color: pulse.accentColor.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white38),
                      onPressed: _openSettings,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Presets grid
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 80 : 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: isTablet ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isTablet ? 1.3 : 1.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _presets
                        .map((p) => _PresetCard(
                              label: p.label,
                              minutes: p.minutes,
                              accentColor: pulse.accentColor,
                              isAmbient: pulse.isAmbient,
                              onTap: () =>
                                  _startPreset(p.label, p.minutes),
                            ))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons row
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 80 : 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _startPomodoro,
                          icon: Icon(Icons.timer, color: pulse.accentColor, size: 18),
                          label: Text(
                            'Pomodoro',
                            style: TextStyle(color: pulse.accentColor, letterSpacing: 1),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            side: BorderSide(color: pulse.accentColor.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openCustomSheet,
                          icon: Icon(Icons.add, color: pulse.accentColor, size: 18),
                          label: Text(
                            'Custom',
                            style: TextStyle(color: pulse.accentColor, letterSpacing: 1),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            side: BorderSide(color: pulse.accentColor.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Status bar
              if (_ip.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          boxShadow: pulse.isAmbient
                              ? [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_ip:7878',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      if (devices.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Text(
                          '${devices.length} device${devices.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: pulse.accentColor.withValues(alpha: 0.4),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String label;
  final int minutes;
  final Color accentColor;
  final bool isAmbient;
  final VoidCallback onTap;

  const _PresetCard({
    required this.label,
    required this.minutes,
    required this.accentColor,
    required this.isAmbient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
            color: isAmbient
                ? accentColor.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.05),
            boxShadow: isAmbient
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${minutes}m',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w200,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
