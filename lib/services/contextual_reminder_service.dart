import 'notification_service.dart';

/// Coordinates context-aware reminders using NotificationService.
class ContextualReminderService {
  ContextualReminderService(this._notifications);

  final NotificationService _notifications;

  Future<void> sendWakeUpReminder() {
    return _notifications.showInstantNotification(
      title: 'Доброе утро!',
      body: 'Начните день со стакана воды — это поможет держать темп.',
    );
  }

  Future<void> schedulePreWorkoutReminder() {
    return _notifications.scheduleOneShot(
      delay: const Duration(minutes: 30),
      title: 'Скоро тренировка',
      body: 'Пополните воду заранее, чтобы тренировка прошла легче.',
    );
  }

  Future<void> schedulePostWorkoutReminder() {
    return _notifications.scheduleOneShot(
      delay: const Duration(hours: 1),
      title: 'После тренировки',
      body: 'Восполните жидкость, чтобы восстановиться быстрее.',
    );
  }

  Future<void> sendInactivityReminder(Duration inactivity) {
    return _notifications.showInstantNotification(
      title: 'Пора попить воды',
      body:
          'Вы не добавляли напитки ${inactivity.inMinutes ~/ 60}ч — обновите прогресс.',
    );
  }

  Future<void> sendLowHydrationFactorReminder() {
    return _notifications.showInstantNotification(
      title: 'Выбирайте более гидратирующие напитки',
      body: 'Последние напитки почти не дают гидратацию. Добавьте воды.',
    );
  }
}
