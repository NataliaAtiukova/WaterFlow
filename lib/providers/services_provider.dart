import 'package:flutter_riverpod/flutter_riverpod.dart';

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
