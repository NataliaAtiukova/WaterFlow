import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'models/daily_progress.dart';
import 'models/drink_entry.dart';
import 'models/drink_type.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  runApp(const ProviderScope(child: WaterTrackerApp()));
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? data) async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final repo = await container.read(drinksRepositoryProvider.future);
  final settings = await repo.loadSettings();
  if (data?.host == WidgetService.addAction) {
    final types = await repo.loadDrinkTypes();
    final waterType = types.firstWhere(
      (t) => t.id == DrinkType.waterId,
      orElse: () => types.first,
    );
    final entry = DrinkEntry.fromDrinkType(type: waterType, volumeMl: 200);
    await repo.addEntry(entry);
  }
  final entries = await repo.loadEntriesForDay(DateTime.now());
  final totalVolume = entries.fold<int>(0, (sum, e) => sum + e.volumeMl);
  final effective = entries.fold<int>(0, (sum, e) {
    if (settings.countOnlyWater && e.drinkTypeId != DrinkType.waterId) {
      return sum;
    }
    return sum + e.effectiveHydrationMl;
  });
  final updated = DailyProgress(
    date: DateUtils.dateOnly(DateTime.now()),
    target: settings.dailyGoal,
    effectiveMl: effective,
    totalVolumeMl: totalVolume,
  );

  // Обновляем уведомления и виджет даже из фона.
  final notificationService = NotificationService();
  await notificationService.initialize();
  if (settings.notificationsEnabled &&
      updated.effectiveMl < updated.target) {
    await notificationService.scheduleDailyReminders(
      intervalHours: settings.notificationIntervalHours,
    );
  } else {
    await notificationService.cancelAll();
  }
  await WidgetService().updateWidget(updated);
  container.dispose();
}
