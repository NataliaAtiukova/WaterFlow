import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../services/widget_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final widgetServiceProvider = Provider<WidgetService>(
  (ref) => WidgetService(),
);
