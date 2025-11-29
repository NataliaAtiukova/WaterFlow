import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/body_metrics.dart';
import '../services/hydration_calculator.dart';
import 'services_provider.dart';
import 'settings_provider.dart';

final bodyMetricsProvider =
    AsyncNotifierProvider<BodyMetricsNotifier, BodyMetrics>(
  BodyMetricsNotifier.new,
);

class BodyMetricsNotifier extends AsyncNotifier<BodyMetrics> {
  @override
  Future<BodyMetrics> build() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    return repo.loadBodyMetrics();
  }

  Future<void> updateMetrics(BodyMetrics metrics) async {
    state = AsyncData(metrics);
    final repo = await ref.watch(drinksRepositoryProvider.future);
    await repo.saveBodyMetrics(metrics);

    final goal = HydrationCalculator.calculateDailyGoal(metrics);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final currentSettings = await ref.read(settingsProvider.future);
    await settingsNotifier.saveSettings(
      currentSettings.copyWith(dailyGoal: goal),
    );
    final healthSync = ref.read(healthSyncServiceProvider);
    await healthSync.syncDailyGoal(goal);
  }
}
