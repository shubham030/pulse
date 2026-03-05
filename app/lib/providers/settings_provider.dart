import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { dark, ambient }

class SettingsState {
  final AppTheme theme;
  final bool soundDefault;

  const SettingsState({
    this.theme = AppTheme.dark,
    this.soundDefault = true,
  });

  SettingsState copyWith({AppTheme? theme, bool? soundDefault}) {
    return SettingsState(
      theme: theme ?? this.theme,
      soundDefault: soundDefault ?? this.soundDefault,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _themeKey = 'app_theme';
  static const _soundKey = 'sound_default';

  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey);
    final sound = prefs.getBool(_soundKey) ?? true;
    final theme = themeStr == 'ambient' ? AppTheme.ambient : AppTheme.dark;
    state = SettingsState(theme: theme, soundDefault: sound);
  }

  Future<void> setTheme(AppTheme theme) async {
    state = state.copyWith(theme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }

  Future<void> setSoundDefault(bool enabled) async {
    state = state.copyWith(soundDefault: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
