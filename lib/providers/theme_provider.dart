import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/water_settings.dart';
import 'settings_provider.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings =
      ref.watch(settingsProvider).valueOrNull ?? WaterSettings.defaultSettings;
  return _mapToThemeMode(settings.themePreference);
});

ThemeMode _mapToThemeMode(ThemePreference preference) {
  switch (preference) {
    case ThemePreference.light:
      return ThemeMode.light;
    case ThemePreference.dark:
      return ThemeMode.dark;
    case ThemePreference.system:
      return ThemeMode.system;
  }
}
