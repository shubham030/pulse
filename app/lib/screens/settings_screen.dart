import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/device_discovery.dart';
import '../theme/app_themes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final pulse = context.pulse;
    final devices = ref.watch(deviceDiscoveryProvider);
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: pulse.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white54),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SETTINGS',
                          style: TextStyle(
                            color: pulse.accentColor,
                            fontSize: 13,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // -- Theme section --
                  _SectionHeader(label: 'Theme', color: pulse.accentColor),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        for (final theme in AppTheme.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _ThemeCard(
                              label: _themeLabel(theme),
                              isSelected: settings.theme == theme,
                              previewColors: _themePreviewColors(theme),
                              accentColor: pulse.accentColor,
                              onTap: () => ref
                                  .read(settingsProvider.notifier)
                                  .setTheme(theme),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // -- Defaults section --
                  _SectionHeader(label: 'Defaults', color: pulse.accentColor),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.vibration, color: Colors.white54, size: 18),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Vibrate on completion',
                              style: TextStyle(color: Colors.white70)),
                        ),
                        Switch(
                          value: settings.soundDefault,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setSoundDefault(v),
                          activeThumbColor: pulse.accentColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // -- Multi-device section --
                  _SectionHeader(label: 'Multi-Device', color: pulse.accentColor),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sync, color: Colors.white54, size: 18),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Sync timers to other devices',
                                  style: TextStyle(color: Colors.white70)),
                            ),
                            Switch(
                              value: settings.syncToDevices,
                              onChanged: (v) => ref
                                  .read(settingsProvider.notifier)
                                  .setSyncToDevices(v),
                              activeThumbColor: pulse.accentColor,
                            ),
                          ],
                        ),
                        if (devices.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final device in devices)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${device.name} (${device.host}:${device.port})',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ] else
                          const Padding(
                            padding: EdgeInsets.only(left: 30, top: 4),
                            child: Text(
                              'No other Pulse devices found on network',
                              style: TextStyle(color: Colors.white24, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // -- API info --
                  _SectionHeader(label: 'Remote Control API', color: pulse.accentColor),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _ApiRow('POST /timer', '{"duration":1500,"label":"Focus"}'),
                        SizedBox(height: 8),
                        _ApiRow('POST /stop', ''),
                        SizedBox(height: 8),
                        _ApiRow('POST /pause', ''),
                        SizedBox(height: 8),
                        _ApiRow('POST /resume', ''),
                        SizedBox(height: 8),
                        _ApiRow('POST /skip', ''),
                        SizedBox(height: 8),
                        _ApiRow('GET  /status', ''),
                        SizedBox(height: 8),
                        _ApiRow('POST /queue', '{"duration":300,"label":"Break"}'),
                        SizedBox(height: 8),
                        _ApiRow('POST /pomodoro', '{"focusMinutes":25,...}'),
                        SizedBox(height: 8),
                        _ApiRow('GET  /ws', 'WebSocket for live updates'),
                        SizedBox(height: 8),
                        _ApiRow('POST /settings', '{"theme":"ambient"}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _themeLabel(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.ambient:
        return 'Ambient';
      case AppTheme.warm:
        return 'Warm';
      case AppTheme.forest:
        return 'Forest';
      case AppTheme.ocean:
        return 'Ocean';
      case AppTheme.rose:
        return 'Rose';
    }
  }

  List<Color> _themePreviewColors(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return [const Color(0xFF0D0D14), const Color(0xFF1A1A26)];
      case AppTheme.ambient:
        return [const Color(0xFF1A0A2E), const Color(0xFF0A1A2E)];
      case AppTheme.warm:
        return [const Color(0xFF1E1208), const Color(0xFF1A1008)];
      case AppTheme.forest:
        return [const Color(0xFF0A1A10), const Color(0xFF081408)];
      case AppTheme.ocean:
        return [const Color(0xFF081420), const Color(0xFF0A1828)];
      case AppTheme.rose:
        return [const Color(0xFF1E0A18), const Color(0xFF180A14)];
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 11,
          letterSpacing: 3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final List<Color> previewColors;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.isSelected,
    required this.previewColors,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          gradient: LinearGradient(
            colors: previewColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? accentColor : Colors.white38,
              size: 16,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiRow extends StatelessWidget {
  final String method;
  final String detail;
  const _ApiRow(this.method, this.detail);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(method,
            style: const TextStyle(
                color: Colors.white54, fontSize: 11, fontFamily: 'monospace')),
        if (detail.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(detail,
                style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    fontFamily: 'monospace')),
          ),
        ],
      ],
    );
  }
}
