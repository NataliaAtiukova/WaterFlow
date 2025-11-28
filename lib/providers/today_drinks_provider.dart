import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_progress.dart';
import '../models/drink_entry.dart';
import '../models/drink_type.dart';
import '../models/water_settings.dart';
import 'drink_types_provider.dart';
import 'history_provider.dart';
import 'services_provider.dart';
import 'settings_provider.dart';

final todayDrinksProvider =
    AsyncNotifierProvider<TodayDrinksNotifier, TodayHydrationState>(
  TodayDrinksNotifier.new,
);

class TodayHydrationState {
  const TodayHydrationState({
    required this.date,
    required this.entries,
    required this.selectedDrinkTypeId,
    required this.target,
    required this.totalVolumeMl,
    required this.effectiveHydrationMl,
  });

  final DateTime date;
  final List<DrinkEntry> entries;
  final String selectedDrinkTypeId;
  final int target;
  final int totalVolumeMl;
  final int effectiveHydrationMl;

  TodayHydrationState copyWith({
    DateTime? date,
    List<DrinkEntry>? entries,
    String? selectedDrinkTypeId,
    int? target,
    int? totalVolumeMl,
    int? effectiveHydrationMl,
  }) {
    return TodayHydrationState(
      date: date ?? this.date,
      entries: entries ?? this.entries,
      selectedDrinkTypeId: selectedDrinkTypeId ?? this.selectedDrinkTypeId,
      target: target ?? this.target,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      effectiveHydrationMl: effectiveHydrationMl ?? this.effectiveHydrationMl,
    );
  }

  DailyProgress toDailyProgress() => DailyProgress(
        date: date,
        target: target,
        effectiveMl: effectiveHydrationMl,
        totalVolumeMl: totalVolumeMl,
      );
}

class TodayDrinksNotifier extends AsyncNotifier<TodayHydrationState> {
  Timer? _midnightTimer;

  @override
  Future<TodayHydrationState> build() async {
    ref.onDispose(() {
      _midnightTimer?.cancel();
    });

    ref.listen<AsyncValue<WaterSettings>>(settingsProvider, (prev, next) {
      if (next.hasValue) {
        _handleSettingsChange(next.value!);
      }
    });
    ref.listen<AsyncValue<List<DrinkType>>>(
      drinkTypesProvider,
      (prev, next) {
        if (next.hasValue) {
          _handleDrinkTypesChange(next.value!);
        }
      },
    );

    final state = await _loadStateFromRepository();
    _scheduleMidnightReset();
    await _notifyServices(state);
    return state;
  }

  Future<void> addDrink(int volumeMl) async {
    final types = await ref.watch(drinkTypesProvider.future);
    final currentState = state.valueOrNull;
    final selectedId =
        currentState?.selectedDrinkTypeId ?? DrinkType.waterId;
    final type = types.firstWhere(
      (t) => t.id == selectedId,
      orElse: () => types.first,
    );
    final entry = DrinkEntry.fromDrinkType(type: type, volumeMl: volumeMl);
    final repo = await ref.watch(drinksRepositoryProvider.future);
    await repo.addEntry(entry);
    final updated = await _loadStateFromRepository(
      overrideSelected: selectedId,
    );
    state = AsyncData(updated);
    await _notifyServices(updated);
    await ref.read(historyProvider.notifier).reload();
  }

  Future<void> addCustomDrink(int volumeMl) => addDrink(volumeMl);

  Future<void> selectDrinkType(String drinkTypeId) async {
    final current = state.valueOrNull;
    if (current == null || current.selectedDrinkTypeId == drinkTypeId) {
      return;
    }
    state = AsyncData(
      TodayHydrationState(
        date: current.date,
        entries: current.entries,
        selectedDrinkTypeId: drinkTypeId,
        target: current.target,
        totalVolumeMl: current.totalVolumeMl,
        effectiveHydrationMl: current.effectiveHydrationMl,
      ),
    );
  }

  Future<TodayHydrationState> _loadStateFromRepository({
    String? overrideSelected,
  }) async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    final settings = await ref.watch(settingsProvider.future);
    final entries = await repo.loadEntriesForDay(DateTime.now());
    final selectedId =
        overrideSelected ?? state.valueOrNull?.selectedDrinkTypeId;
    final types = await ref.watch(drinkTypesProvider.future);
    final defaultType = types.firstWhere(
      (t) => t.id == DrinkType.waterId,
      orElse: () => types.first,
    );
    final selected = selectedId != null &&
            types.any((t) => t.id == selectedId)
        ? selectedId
        : defaultType.id;
    return _buildState(entries, settings, selected);
  }

  TodayHydrationState _buildState(
    List<DrinkEntry> entries,
    WaterSettings settings,
    String selectedId,
  ) {
    entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final totalVolume =
        entries.fold<int>(0, (sum, e) => sum + e.volumeMl);
    // totalVolume tracks "Всего выпито", while effective counts only the amount
    // credited towards the goal ("Зачтено").
    final effective = entries.fold<int>(0, (sum, e) {
      if (settings.countOnlyWater && e.drinkTypeId != DrinkType.waterId) {
        return sum;
      }
      return sum + e.effectiveHydrationMl;
    });
    return TodayHydrationState(
      date: DateUtils.dateOnly(DateTime.now()),
      entries: entries,
      selectedDrinkTypeId: selectedId,
      target: settings.dailyGoal,
      totalVolumeMl: totalVolume,
      effectiveHydrationMl: effective,
    );
  }

  Future<void> _handleSettingsChange(WaterSettings settings) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = _buildState(
      current.entries,
      settings,
      current.selectedDrinkTypeId,
    );
    state = AsyncData(updated);
    await _notifyServices(updated);
    await ref.read(historyProvider.notifier).reload();
  }

  void _scheduleMidnightReset() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () async {
      final refreshed = await _loadStateFromRepository();
      state = AsyncData(refreshed);
      await _notifyServices(refreshed);
      await ref.read(historyProvider.notifier).reload();
    });
  }

  void _handleDrinkTypesChange(List<DrinkType> types) {
    final current = state.valueOrNull;
    if (current == null || types.isEmpty) return;
    if (!types.any((t) => t.id == current.selectedDrinkTypeId)) {
      final updated =
          current.copyWith(selectedDrinkTypeId: types.first.id);
      state = AsyncData(updated);
    }
  }

  Future<void> _notifyServices(TodayHydrationState state) async {
    final settings = await ref.watch(settingsProvider.future);
    final notifier = ref.read(notificationServiceProvider);
    final widgetService = ref.read(widgetServiceProvider);
    final progress = state.toDailyProgress();

    if (settings.notificationsEnabled &&
        progress.effectiveMl < progress.target) {
      await notifier.scheduleDailyReminders(
        intervalHours: settings.notificationIntervalHours,
      );
    } else {
      await notifier.cancelAll();
    }

    await widgetService.updateWidget(progress);
  }
}
