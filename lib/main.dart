import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:yandex_mobileads/mobile_ads.dart';

import 'app.dart';
import 'ads/app_open_ad_manager.dart';
import 'ads/interstitial_service.dart';
import 'models/daily_progress.dart';
import 'models/drink_entry.dart';
import 'models/drink_type.dart';
import 'models/water_settings.dart';
import 'providers/settings_provider.dart';
import 'providers/services_provider.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize();
  final appOpenAdManager = AppOpenAdManager(
    adUnitId: 'R-M-17907836-2',
    minTimeBetweenDisplays: const Duration(hours: 1),
  )..start();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => appOpenAdManager.showAdIfAvailable(),
  );
  final interstitialAdService = InterstitialAdService(
    adUnitId: 'R-M-17907836-3',
  )..load();
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  runApp(
    ProviderScope(
      overrides: [
        appOpenAdManagerProvider.overrideWithValue(appOpenAdManager),
        interstitialAdServiceProvider.overrideWithValue(interstitialAdService),
      ],
      child: const WaterFlowApp(),
    ),
  );
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
    if (!_shouldIncludeEntry(e, settings.countingMode)) {
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

bool _shouldIncludeEntry(DrinkEntry entry, CountingMode mode) {
  switch (mode) {
    case CountingMode.factors:
      return true;
    case CountingMode.waterOnly:
      return entry.drinkTypeId == DrinkType.waterId;
    case CountingMode.ignoreSugary:
      return !(entry.drinkTypeId == 'juice' || entry.drinkTypeId == 'soda');
  }
}
