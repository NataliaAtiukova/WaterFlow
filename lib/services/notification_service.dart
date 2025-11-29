import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService() {
    _plugin = FlutterLocalNotificationsPlugin();
  }

  late final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_contextual',
          'Контекстные напоминания',
          channelDescription: 'Разовые уведомления',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleOneShot({
    required Duration delay,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(delay);
    await _plugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_contextual',
          'Контекстные напоминания',
          channelDescription: 'Разовые уведомления',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'context',
    );
  }

  // Расписание напоминаний до конца дня с заданным интервалом.
  Future<void> scheduleDailyReminders({
    required int intervalHours,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final todayEnd =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 23, 59);

    // Стартуем через интервал от текущего момента.
    var scheduled = now.add(Duration(hours: intervalHours));
    int id = 0;

    while (scheduled.isBefore(todayEnd)) {
      await _plugin.zonedSchedule(
        id++,
        'Напоминание о воде',
        'Пора выпить воды и обновить прогресс.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminders',
            'Напоминания о воде',
            channelDescription: 'Периодические напоминания о воде',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: 'reminder',
      );
      scheduled = scheduled.add(Duration(hours: intervalHours));
    }
  }
}
