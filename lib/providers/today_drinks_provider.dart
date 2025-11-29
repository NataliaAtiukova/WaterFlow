import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/body_metrics.dart';
import '../models/daily_progress.dart';
import '../models/day_schedule.dart';
import '../models/drink_entry.dart';
import '../models/drink_type.dart';
import '../models/water_settings.dart';
import 'body_metrics_provider.dart';
import 'drink_types_provider.dart';
import 'history_provider.dart';
import 'schedule_provider.dart';
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
    required this.plannedHydrationMl,
    required this.deviationPercent,
    required this.totalCaffeine,
    required this.totalSugar,
  });

  final DateTime date;
  final List<DrinkEntry> entries;
  final String selectedDrinkTypeId;
  final int target;
  final int totalVolumeMl;
  final int effectiveHydrationMl;
  final int plannedHydrationMl;
  final double deviationPercent;
  final int totalCaffeine;
  final int totalSugar;

  TodayHydrationState copyWith({
    DateTime? date,
    List<DrinkEntry>? entries,
    String? selectedDrinkTypeId,
    int? target,
    int? totalVolumeMl,
    int? effectiveHydrationMl,
    int? plannedHydrationMl,
    double? deviationPercent,
    int? totalCaffeine,
    int? totalSugar,
  }) {
    return TodayHydrationState(
      date: date ?? this.date,
      entries: entries ?? this.entries,
      selectedDrinkTypeId: selectedDrinkTypeId ?? this.selectedDrinkTypeId,
      target: target ?? this.target,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      effectiveHydrationMl: effectiveHydrationMl ?? this.effectiveHydrationMl,
      plannedHydrationMl: plannedHydrationMl ?? this.plannedHydrationMl,
      deviationPercent: deviationPercent ?? this.deviationPercent,
      totalCaffeine: totalCaffeine ?? this.totalCaffeine,
      totalSugar: totalSugar ?? this.totalSugar,
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
  Timer? _inactivityTimer;
  DateTime? _lastWakeReminderDate;
  DateTime? _lastWorkoutReminderDate;
  DateTime? _lastHydrationWarningDate;

  @override
  Future<TodayHydrationState> build() async {
    ref.onDispose(() {
      _midnightTimer?.cancel();
      _inactivityTimer?.cancel();
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
    ref.listen<AsyncValue<DaySchedule>>(
      scheduleProvider,
      (prev, next) {
        if (next.hasValue) {
          _handleScheduleChange(next.value!);
        }
      },
    );
    ref.listen<AsyncValue<BodyMetrics>>(
      bodyMetricsProvider,
      (prev, next) {
        if (next.hasValue) {
          _handleBodyMetrics(next.value!);
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
    await _checkHydrationQuality(updated.entries);
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
        plannedHydrationMl: current.plannedHydrationMl,
        deviationPercent: current.deviationPercent,
        totalCaffeine: current.totalCaffeine,
        totalSugar: current.totalSugar,
      ),
    );
  }

  Future<TodayHydrationState> _loadStateFromRepository({
    String? overrideSelected,
  }) async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    final settings = await ref.watch(settingsProvider.future);
    final schedule = await ref.watch(scheduleProvider.future);
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
    final built = _buildState(entries, settings, schedule, selected);
    if (_lastWorkoutReminderDate != null &&
        !DateUtils.isSameDay(_lastWorkoutReminderDate, built.date)) {
      _lastWorkoutReminderDate = null;
    }
    _restartInactivityTimer(initial: entries.isEmpty);
    await _maybeSendWakeReminder();
    return built;
  }

  TodayHydrationState _buildState(
    List<DrinkEntry> entries,
    WaterSettings settings,
    DaySchedule schedule,
    String selectedId,
  ) {
    entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final totalVolume =
        entries.fold<int>(0, (sum, e) => sum + e.volumeMl);
    // totalVolume tracks "Всего выпито", while effective counts only the amount
    // credited towards the goal ("Зачтено").
    final effective = entries.fold<int>(0, (sum, e) {
      if (!_shouldIncludeEntry(e, settings)) {
        return sum;
      }
      return sum + e.effectiveHydrationMl;
    });
    final planned =
        schedule.plannedHydrationForTime(time: DateTime.now(), dailyGoal: settings.dailyGoal);
    final deviation = planned == 0
        ? 0.0
        : ((effective - planned) / planned).clamp(-1.0, 1.0).toDouble();
    final caffeine = entries.fold<int>(0, (sum, e) => sum + e.caffeineMg);
    final sugar = entries.fold<int>(0, (sum, e) => sum + e.sugarGr);
    return TodayHydrationState(
      date: DateUtils.dateOnly(DateTime.now()),
      entries: entries,
      selectedDrinkTypeId: selectedId,
      target: settings.dailyGoal,
      totalVolumeMl: totalVolume,
      effectiveHydrationMl: effective,
      plannedHydrationMl: planned,
      deviationPercent: deviation,
      totalCaffeine: caffeine,
      totalSugar: sugar,
    );
  }

  bool _shouldIncludeEntry(DrinkEntry entry, WaterSettings settings) {
    switch (settings.countingMode) {
      case CountingMode.factors:
        return true;
      case CountingMode.waterOnly:
        return entry.drinkTypeId == DrinkType.waterId;
      case CountingMode.ignoreSugary:
        return !(entry.drinkTypeId == 'juice' || entry.drinkTypeId == 'soda');
    }
  }

  Future<void> _handleSettingsChange(WaterSettings settings) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final schedule = await ref.watch(scheduleProvider.future);
    final updated = _buildState(
      current.entries,
      settings,
      schedule,
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

  Future<void> _handleScheduleChange(DaySchedule schedule) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final settings = await ref.watch(settingsProvider.future);
    final updated = _buildState(
      current.entries,
      settings,
      schedule,
      current.selectedDrinkTypeId,
    );
    state = AsyncData(updated);
    await _notifyServices(updated);
  }

  Future<void> _notifyServices(TodayHydrationState state) async {
    final settings = await ref.watch(settingsProvider.future);
    final notifier = ref.read(notificationServiceProvider);
    final widgetService = ref.read(widgetServiceProvider);
    final progress = state.toDailyProgress();

    if (settings.notificationsEnabled &&
        progress.effectiveMl < progress.target) {
      final adjustedInterval = _calculateAdaptiveInterval(
        baseHours: settings.notificationIntervalHours,
        deviation: state.deviationPercent,
      );
      await notifier.scheduleDailyReminders(
        intervalHours: adjustedInterval,
      );
    } else {
      await notifier.cancelAll();
    }

    await widgetService.updateWidget(progress);
    final healthSync = ref.read(healthSyncServiceProvider);
    await healthSync.syncHydration(
      effectiveMl: progress.effectiveMl,
      totalMl: progress.totalVolumeMl,
    );
  }

  void _restartInactivityTimer({bool initial = false}) {
    _inactivityTimer?.cancel();
    final delay = initial ? const Duration(hours: 1) : const Duration(hours: 2);
    _inactivityTimer = Timer(delay, () async {
      final contextual = ref.read(contextualReminderServiceProvider);
      await contextual.sendInactivityReminder(delay);
      _restartInactivityTimer(initial: true);
    });
  }

  Future<void> _maybeSendWakeReminder() async {
    final today = DateUtils.dateOnly(DateTime.now());
    if (_lastWakeReminderDate != null &&
        DateUtils.isSameDay(_lastWakeReminderDate, today)) {
      return;
    }
    _lastWakeReminderDate = today;
    final contextual = ref.read(contextualReminderServiceProvider);
    await contextual.sendWakeUpReminder();
  }

  Future<void> _handleBodyMetrics(BodyMetrics metrics) async {
    if (!metrics.hadWorkoutToday) return;
    final today = DateUtils.dateOnly(DateTime.now());
    if (_lastWorkoutReminderDate != null &&
        DateUtils.isSameDay(_lastWorkoutReminderDate, today)) {
      return;
    }
    _lastWorkoutReminderDate = today;
    final contextual = ref.read(contextualReminderServiceProvider);
    await contextual.schedulePreWorkoutReminder();
    await contextual.schedulePostWorkoutReminder();
  }

  Future<void> _checkHydrationQuality(List<DrinkEntry> entries) async {
    if (entries.length < 3) return;
    final recent = entries.reversed.take(3).toList();
    double avg = 0;
    for (final entry in recent) {
      if (entry.volumeMl == 0) continue;
      avg += entry.effectiveHydrationMl / entry.volumeMl;
    }
    avg /= recent.length;
    if (avg < 0.6) {
      final today = DateUtils.dateOnly(DateTime.now());
      if (_lastHydrationWarningDate != null &&
          DateUtils.isSameDay(_lastHydrationWarningDate, today)) {
        return;
      }
      _lastHydrationWarningDate = today;
      final contextual = ref.read(contextualReminderServiceProvider);
      await contextual.sendLowHydrationFactorReminder();
    }
  }

  int _calculateAdaptiveInterval({
    required int baseHours,
    required double deviation,
  }) {
    if (deviation < -0.1) {
      return (baseHours * 0.7).clamp(1, 6).round();
    }
    if (deviation > 0.2) {
      return (baseHours * 1.5).clamp(1, 8).round();
    }
    return baseHours;
  }
}
