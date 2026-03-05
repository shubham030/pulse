import 'package:flutter/material.dart';

const _darkBg = Color(0xFF0D0D14);
const _darkSurface = Color(0xFF1A1A26);
const _darkAccent = Colors.white;

const _ambientBg = Color(0xFF0A0A1A);
const _ambientAccent = Color(0xFF9B8FFF);

final darkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: _darkBg,
  colorScheme: const ColorScheme.dark(
    primary: _darkAccent,
    secondary: Colors.white70,
    surface: _darkSurface,
  ),
  cardTheme: const CardThemeData(color: _darkSurface),
  extensions: const [PulseThemeData(isAmbient: false)],
);

final ambientTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: _ambientBg,
  colorScheme: const ColorScheme.dark(
    primary: _ambientAccent,
    secondary: Color(0xFF7B6FEF),
    surface: Color(0xFF12122A),
  ),
  cardTheme: const CardThemeData(color: Color(0xFF12122A)),
  extensions: const [PulseThemeData(isAmbient: true)],
);

/// Custom theme extension to carry ambient flag and gradient.
class PulseThemeData extends ThemeExtension<PulseThemeData> {
  final bool isAmbient;

  const PulseThemeData({required this.isAmbient});

  LinearGradient get backgroundGradient => isAmbient
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A1A), Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
        )
      : const LinearGradient(
          colors: [_darkBg, _darkBg],
        );

  Color get accentColor =>
      isAmbient ? _ambientAccent : _darkAccent;

  Color get ringColor =>
      isAmbient ? _ambientAccent : Colors.white;

  Color get ringBg =>
      isAmbient ? const Color(0x229B8FFF) : Colors.white12;

  @override
  PulseThemeData copyWith({bool? isAmbient}) =>
      PulseThemeData(isAmbient: isAmbient ?? this.isAmbient);

  @override
  PulseThemeData lerp(PulseThemeData other, double t) => t < 0.5 ? this : other;
}

extension PulseTheme on BuildContext {
  PulseThemeData get pulse =>
      Theme.of(this).extension<PulseThemeData>() ??
      const PulseThemeData(isAmbient: false);
}
