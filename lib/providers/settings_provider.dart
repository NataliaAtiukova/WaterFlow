import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/drinks_repository.dart';
import '../models/water_settings.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (ref) async => SharedPreferences.getInstance(),
);

final drinksRepositoryProvider = FutureProvider<DrinksRepository>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return DrinksRepository(prefs);
});

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, WaterSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<WaterSettings> {
  @override
  Future<WaterSettings> build() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    return repo.loadSettings();
  }

  Future<void> saveSettings(WaterSettings settings) async {
    state = AsyncData(settings);
    final repo = await ref.watch(drinksRepositoryProvider.future);
    await repo.saveSettings(settings);
  }
}
