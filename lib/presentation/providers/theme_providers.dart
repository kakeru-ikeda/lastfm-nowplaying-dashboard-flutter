import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/theme_settings.dart';

// SharedPreferences プロバイダー
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main');
});

// テーマ設定通知プロバイダー
final themeSettingsNotifierProvider = 
    StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeSettingsNotifier(prefs);
});

// テーマデータプロバイダー
final themeDataProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsNotifierProvider);
  return _buildThemeData(settings);
});

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  ThemeSettingsNotifier(this._prefs) : super(const ThemeSettings()) {
    _loadSettings();
  }

  final SharedPreferences _prefs;

  static const String _themeModeKey = 'theme_mode';
  static const String _colorThemeKey = 'color_theme';
  static const String _customPrimaryColorKey = 'custom_primary_color';
  static const String _customAccentColorKey = 'custom_accent_color';

  Future<void> _loadSettings() async {
    final themeModeIndex = _prefs.getInt(_themeModeKey) ?? ThemeMode.dark.index;
    final colorThemeIndex = _prefs.getInt(_colorThemeKey) ?? ColorThemePreset.spotify.index;
    final customPrimaryColorValue = _prefs.getInt(_customPrimaryColorKey);
    final customAccentColorValue = _prefs.getInt(_customAccentColorKey);

    state = ThemeSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      colorTheme: ColorThemePreset.values[colorThemeIndex],
      customPrimaryColorValue: customPrimaryColorValue,
      customAccentColorValue: customAccentColorValue,
    );
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    await _prefs.setInt(_themeModeKey, themeMode.index);
    state = state.copyWith(themeMode: themeMode);
  }

  Future<void> updateColorTheme(ColorThemePreset colorTheme) async {
    await _prefs.setInt(_colorThemeKey, colorTheme.index);
    state = state.copyWith(colorTheme: colorTheme);
  }

  Future<void> updateCustomColors({Color? primaryColor, Color? accentColor}) async {
    if (primaryColor != null) {
      await _prefs.setInt(_customPrimaryColorKey, primaryColor.value);
    }
    if (accentColor != null) {
      await _prefs.setInt(_customAccentColorKey, accentColor.value);
    }
    
    state = state.copyWith(
      customPrimaryColorValue: primaryColor?.value ?? state.customPrimaryColorValue,
      customAccentColorValue: accentColor?.value ?? state.customAccentColorValue,
    );
  }

  Future<void> resetToDefaults() async {
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_colorThemeKey);
    await _prefs.remove(_customPrimaryColorKey);
    await _prefs.remove(_customAccentColorKey);
    
    state = const ThemeSettings();
  }
}

ThemeData _buildThemeData(ThemeSettings settings) {
  final isLight = settings.themeMode == ThemeMode.light;
  final preset = settings.colorTheme;
  
  // カスタムカラーがある場合は使用、そうでなければプリセットを使用
  final primaryColor = settings.colorTheme == ColorThemePreset.custom 
      ? (settings.customPrimaryColor ?? preset.primaryColorValue)
      : preset.primaryColorValue;
      
  final accentColor = settings.colorTheme == ColorThemePreset.custom
      ? (settings.customAccentColor ?? preset.accentColorValue)
      : preset.accentColorValue;

  final backgroundColor = isLight 
      ? Colors.white 
      : preset.backgroundColorValue;

  final surfaceColor = isLight
      ? Colors.grey[100]!
      : preset.backgroundColorValue.withOpacity(0.8);

  final textColor = isLight ? Colors.black : Colors.white;

  return ThemeData(
    useMaterial3: true,
    brightness: isLight ? Brightness.light : Brightness.dark,
    primarySwatch: _createMaterialColor(primaryColor),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: primaryColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.notoSansTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
    ),
  );
}

MaterialColor _createMaterialColor(Color color) {
  return MaterialColor(color.value, <int, Color>{
    50: color.withOpacity(0.1),
    100: color.withOpacity(0.2),
    200: color.withOpacity(0.3),
    300: color.withOpacity(0.4),
    400: color.withOpacity(0.5),
    500: color,
    600: color.withOpacity(0.7),
    700: color.withOpacity(0.8),
    800: color.withOpacity(0.9),
    900: color,
  });
}
