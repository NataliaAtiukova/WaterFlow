import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_schedule.dart';
import 'settings_provider.dart';

final scheduleProvider =
    AsyncNotifierProvider<ScheduleNotifier, DaySchedule>(
  ScheduleNotifier.new,
);

class ScheduleNotifier extends AsyncNotifier<DaySchedule> {
  @override
  Future<DaySchedule> build() async {
    final repo = await ref.watch(drinksRepositoryProvider.future);
    return repo.loadSchedule();
  }

  Future<void> updateSchedule(DaySchedule schedule) async {
    state = AsyncData(schedule);
    final repo = await ref.watch(drinksRepositoryProvider.future);
    await repo.saveSchedule(schedule);
  }
}
