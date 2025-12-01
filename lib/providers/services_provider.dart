import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/app_open_ad_manager.dart';
import '../ads/interstitial_service.dart';
import '../services/contextual_reminder_service.dart';
import '../services/health_sync_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final widgetServiceProvider = Provider<WidgetService>(
  (ref) => WidgetService(),
);

final contextualReminderServiceProvider =
    Provider<ContextualReminderService>(
  (ref) => ContextualReminderService(ref.read(notificationServiceProvider)),
);

final healthSyncServiceProvider = Provider<HealthSyncService>(
  (ref) => HealthSyncService(),
);

final interstitialAdServiceProvider = Provider<InterstitialAdService>(
  (ref) => throw UnimplementedError(
    'interstitialAdServiceProvider must be overridden in main.dart',
  ),
);

final appOpenAdManagerProvider = Provider<AppOpenAdManager>(
  (ref) => throw UnimplementedError(
    'appOpenAdManagerProvider must be overridden in main.dart',
  ),
);
