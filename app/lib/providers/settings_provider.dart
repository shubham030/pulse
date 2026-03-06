import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { dark, ambient, warm, forest, ocean, rose }

class SettingsState {
  final AppTheme theme;
  final bool soundDefault;
  final bool syncToDevices;

  const SettingsState({
    this.theme = AppTheme.dark,
    this.soundDefault = true,
    this.syncToDevices = false,
  });

  SettingsState copyWith({
    AppTheme? theme,
    bool? soundDefault,
    bool? syncToDevices,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      soundDefault: soundDefault ?? this.soundDefault,
      syncToDevices: syncToDevices ?? this.syncToDevices,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _themeKey = 'app_theme';
  static const _soundKey = 'sound_default';
  static const _syncKey = 'sync_to_devices';

  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey);
    final sound = prefs.getBool(_soundKey) ?? true;
    final sync = prefs.getBool(_syncKey) ?? false;
    final theme = AppTheme.values.where((t) => t.name == themeStr).firstOrNull ??
        AppTheme.dark;
    state = SettingsState(theme: theme, soundDefault: sound, syncToDevices: sync);
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

  Future<void> setSyncToDevices(bool enabled) async {
    state = state.copyWith(syncToDevices: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncKey, enabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
