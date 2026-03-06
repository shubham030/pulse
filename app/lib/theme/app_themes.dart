import 'package:flutter/material.dart';

// -- Dark (default) --
const _darkBg = Color(0xFF0D0D14);
const _darkSurface = Color(0xFF1A1A26);
const _darkAccent = Colors.white;

// -- Ambient --
const _ambientBg = Color(0xFF0A0A1A);
const _ambientAccent = Color(0xFF9B8FFF);

// -- Warm --
const _warmBg = Color(0xFF140D08);
const _warmAccent = Color(0xFFE8A55A);

// -- Forest --
const _forestBg = Color(0xFF0A120A);
const _forestAccent = Color(0xFF6BCB77);

// -- Ocean --
const _oceanBg = Color(0xFF080F14);
const _oceanAccent = Color(0xFF5BB8E8);

// -- Rose --
const _roseBg = Color(0xFF140A10);
const _roseAccent = Color(0xFFE87B9B);

// ---- ThemeData builders ----

ThemeData _buildTheme({
  required Color bg,
  required Color accent,
  required Color surface,
  required bool isAmbient,
  LinearGradient? gradient,
}) {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(
      primary: accent,
      secondary: accent.withValues(alpha: 0.7),
      surface: surface,
    ),
    cardTheme: CardThemeData(color: surface),
    extensions: [
      PulseThemeData(
        isAmbient: isAmbient,
        accentColor: accent,
        backgroundGradient: gradient ??
            LinearGradient(colors: [bg, bg]),
        ringColor: accent,
        ringBg: accent.withValues(alpha: 0.15),
      ),
    ],
  );
}

final darkTheme = _buildTheme(
  bg: _darkBg,
  accent: _darkAccent,
  surface: _darkSurface,
  isAmbient: false,
);

final ambientTheme = _buildTheme(
  bg: _ambientBg,
  accent: _ambientAccent,
  surface: const Color(0xFF12122A),
  isAmbient: true,
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A1A), Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
  ),
);

final warmTheme = _buildTheme(
  bg: _warmBg,
  accent: _warmAccent,
  surface: const Color(0xFF1E1510),
  isAmbient: true,
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF140D08), Color(0xFF1E1208), Color(0xFF1A1008)],
  ),
);

final forestTheme = _buildTheme(
  bg: _forestBg,
  accent: _forestAccent,
  surface: const Color(0xFF101E10),
  isAmbient: true,
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A120A), Color(0xFF0A1A10), Color(0xFF081408)],
  ),
);

final oceanTheme = _buildTheme(
  bg: _oceanBg,
  accent: _oceanAccent,
  surface: const Color(0xFF0E1820),
  isAmbient: true,
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF080F14), Color(0xFF081420), Color(0xFF0A1828)],
  ),
);

final roseTheme = _buildTheme(
  bg: _roseBg,
  accent: _roseAccent,
  surface: const Color(0xFF1E0E16),
  isAmbient: true,
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF140A10), Color(0xFF1E0A18), Color(0xFF180A14)],
  ),
);

/// Maps enum name to ThemeData.
final themeMap = {
  'dark': darkTheme,
  'ambient': ambientTheme,
  'warm': warmTheme,
  'forest': forestTheme,
  'ocean': oceanTheme,
  'rose': roseTheme,
};

/// Custom theme extension carrying per-theme styling data.
class PulseThemeData extends ThemeExtension<PulseThemeData> {
  final bool isAmbient;
  final Color accentColor;
  final LinearGradient backgroundGradient;
  final Color ringColor;
  final Color ringBg;

  const PulseThemeData({
    required this.isAmbient,
    required this.accentColor,
    required this.backgroundGradient,
    required this.ringColor,
    required this.ringBg,
  });

  @override
  PulseThemeData copyWith({
    bool? isAmbient,
    Color? accentColor,
    LinearGradient? backgroundGradient,
    Color? ringColor,
    Color? ringBg,
  }) =>
      PulseThemeData(
        isAmbient: isAmbient ?? this.isAmbient,
        accentColor: accentColor ?? this.accentColor,
        backgroundGradient: backgroundGradient ?? this.backgroundGradient,
        ringColor: ringColor ?? this.ringColor,
        ringBg: ringBg ?? this.ringBg,
      );

  @override
  PulseThemeData lerp(PulseThemeData other, double t) =>
      t < 0.5 ? this : other;
}

extension PulseTheme on BuildContext {
  PulseThemeData get pulse =>
      Theme.of(this).extension<PulseThemeData>() ??
      const PulseThemeData(
        isAmbient: false,
        accentColor: _darkAccent,
        backgroundGradient: LinearGradient(colors: [_darkBg, _darkBg]),
        ringColor: Colors.white,
        ringBg: Colors.white12,
      );
}
