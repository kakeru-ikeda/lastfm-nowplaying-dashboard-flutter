import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_settings.freezed.dart';
part 'theme_settings.g.dart';

@freezed
class ThemeSettings with _$ThemeSettings {
  const factory ThemeSettings({
    @Default(ThemeMode.dark) ThemeMode themeMode,
    @Default(ColorThemePreset.spotify) ColorThemePreset colorTheme,
    int? customPrimaryColorValue,
    int? customAccentColorValue,
  }) = _ThemeSettings;

  factory ThemeSettings.fromJson(Map<String, dynamic> json) =>
      _$ThemeSettingsFromJson(json);
}

enum ColorThemePreset {
  spotify('Spotify', 0xFF1DB954, 0xFF191414, 0xFFFF5722),
  appleMusic('Apple Music', 0xFFFA243C, 0xFF000000, 0xFFFF6B6B),
  amazonMusic('Amazon Music', 0xFF00A8E1, 0xFF232F3E, 0xFF87CEEB),
  youtubeMusic('YouTube Music', 0xFFFF0000, 0xFF0F0F0F, 0xFFFF4444),
  tidal('Tidal', 0xFF000000, 0xFF1A1A1A, 0xFFFFFFFF),
  soundcloud('SoundCloud', 0xFFFF5500, 0xFF333333, 0xFFFF8800),
  lastfm('Last.fm', 0xFFD51007, 0xFF000000, 0xFFFF4444),
  custom('Custom', 0xFF6200EE, 0xFF121212, 0xFF03DAC6);

  const ColorThemePreset(this.displayName, this.primaryColor, this.backgroundColor, this.accentColor);

  final String displayName;
  final int primaryColor;
  final int backgroundColor;
  final int accentColor;

  Color get primaryColorValue => Color(primaryColor);
  Color get backgroundColorValue => Color(backgroundColor);
  Color get accentColorValue => Color(accentColor);
}

extension ThemeSettingsExtension on ThemeSettings {
  Color? get customPrimaryColor => 
      customPrimaryColorValue != null ? Color(customPrimaryColorValue!) : null;
  
  Color? get customAccentColor => 
      customAccentColorValue != null ? Color(customAccentColorValue!) : null;
      
  ThemeSettings withCustomColors({Color? primaryColor, Color? accentColor}) {
    return copyWith(
      customPrimaryColorValue: primaryColor?.value ?? customPrimaryColorValue,
      customAccentColorValue: accentColor?.value ?? customAccentColorValue,
    );
  }
}
