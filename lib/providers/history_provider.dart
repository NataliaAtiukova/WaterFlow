import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_progress.dart';
import 'settings_provider.dart';

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<DailyProgress>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends AsyncNotifier<List<DailyProgress>> {
  static const _days = 7;

  @override
  Future<List<DailyProgress>> build() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    final settings = await ref.watch(settingsProvider.future);
    return repo.loadDailySummaries(
      days: _days,
      target: settings.dailyGoal,
      countingMode: settings.countingMode,
    );
  }

  Future<void> reload() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    final settings = await ref.watch(settingsProvider.future);
    final history = await repo.loadDailySummaries(
      days: _days,
      target: settings.dailyGoal,
      countingMode: settings.countingMode,
    );
    state = AsyncData(history);
  }
}
