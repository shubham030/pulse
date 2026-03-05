import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../theme/app_themes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final pulse = context.pulse;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: pulse.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              // Theme section
              _SectionHeader(label: 'Theme', color: pulse.accentColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 24),
                  Expanded(
                    child: _ThemeCard(
                      label: 'Minimal Dark',
                      isSelected: settings.theme == AppTheme.dark,
                      isAmbient: false,
                      accentColor: pulse.accentColor,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setTheme(AppTheme.dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemeCard(
                      label: 'Ambient',
                      isSelected: settings.theme == AppTheme.ambient,
                      isAmbient: true,
                      accentColor: pulse.accentColor,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setTheme(AppTheme.ambient),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),

              const SizedBox(height: 32),

              // Sound section
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

              // API info
              _SectionHeader(label: 'Remote Control API', color: pulse.accentColor),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ApiRow('POST /timer', '{"duration":1500,"label":"Focus","sound":true}'),
                    const SizedBox(height: 8),
                    _ApiRow('POST /stop', ''),
                    const SizedBox(height: 8),
                    _ApiRow('GET /status', '→ running, remaining, label'),
                    const SizedBox(height: 8),
                    _ApiRow('POST /settings', '{"theme":"ambient"}'),
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
  final bool isAmbient;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.isSelected,
    required this.isAmbient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          gradient: isAmbient
              ? const LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAmbient ? null : const Color(0xFF1A1A26),
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
