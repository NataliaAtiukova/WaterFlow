import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drink_type.dart';
import 'settings_provider.dart';

final drinkTypesProvider =
    AsyncNotifierProvider<DrinkTypesNotifier, List<DrinkType>>(
  DrinkTypesNotifier.new,
);

class DrinkTypesNotifier extends AsyncNotifier<List<DrinkType>> {
  @override
  Future<List<DrinkType>> build() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    return repo.loadDrinkTypes();
  }

  Future<void> reload() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    final types = await repo.loadDrinkTypes();
    state = AsyncData(types);
  }

  Future<void> saveDrinkType(DrinkType type) async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    await repo.upsertDrinkType(type);
    await reload();
  }

  Future<void> deleteDrinkType(String id) async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    await repo.deleteDrinkType(id);
    await reload();
  }
}
