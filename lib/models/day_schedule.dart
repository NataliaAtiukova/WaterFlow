class DaySchedule {
  const DaySchedule({
    required this.morningPercent,
    required this.afternoonPercent,
    required this.eveningPercent,
  }) : assert(
          morningPercent + afternoonPercent + eveningPercent == 100,
          'Проценты должны суммироваться до 100',
        );

  final int morningPercent;
  final int afternoonPercent;
  final int eveningPercent;

  DaySchedule copyWith({
    int? morningPercent,
    int? afternoonPercent,
    int? eveningPercent,
  }) {
    final newMorning = morningPercent ?? this.morningPercent;
    final newAfternoon = afternoonPercent ?? this.afternoonPercent;
    final newEvening = eveningPercent ?? this.eveningPercent;
    final total = newMorning + newAfternoon + newEvening;
    if (total != 100) {
      final normalizedEvening = 100 - newMorning - newAfternoon;
      return DaySchedule(
        morningPercent: newMorning,
        afternoonPercent: newAfternoon,
        eveningPercent: normalizedEvening,
      );
    }
    return DaySchedule(
      morningPercent: newMorning,
      afternoonPercent: newAfternoon,
      eveningPercent: newEvening,
    );
  }

  Map<String, dynamic> toJson() => {
        'morningPercent': morningPercent,
        'afternoonPercent': afternoonPercent,
        'eveningPercent': eveningPercent,
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      morningPercent: json['morningPercent'] as int? ?? 40,
      afternoonPercent: json['afternoonPercent'] as int? ?? 35,
      eveningPercent: json['eveningPercent'] as int? ?? 25,
    );
  }

  static const DaySchedule balanced = DaySchedule(
    morningPercent: 40,
    afternoonPercent: 35,
    eveningPercent: 25,
  );

  static const DaySchedule earlyBird = DaySchedule(
    morningPercent: 50,
    afternoonPercent: 30,
    eveningPercent: 20,
  );

  static const DaySchedule nightOwl = DaySchedule(
    morningPercent: 30,
    afternoonPercent: 40,
    eveningPercent: 30,
  );

  static List<DaySchedule> presets = [
    balanced,
    earlyBird,
    nightOwl,
  ];

  static const defaultSchedule = balanced;

  /// Calculates planned hydration (ml) by current time to decide ahead/behind.
  /// Morning segment is 5:00-12:00, day 12:00-18:00, evening 18:00-24:00.
  int plannedHydrationForTime({
    required DateTime time,
    required int dailyGoal,
  }) {
    final segments = [
      _Segment(
        startHour: 5,
        endHour: 12,
        percent: morningPercent,
      ),
      _Segment(
        startHour: 12,
        endHour: 18,
        percent: afternoonPercent,
      ),
      _Segment(
        startHour: 18,
        endHour: 24,
        percent: eveningPercent,
      ),
    ];

    double planned = 0;
    for (final segment in segments) {
      final result = segment.progressForTime(time);
      planned += result * segment.percent / 100;
      if (!segment.isPast(time)) {
        break;
      }
    }
    return (dailyGoal * planned).clamp(0, dailyGoal).round();
  }
}

class _Segment {
  const _Segment({
    required this.startHour,
    required this.endHour,
    required this.percent,
  });

  final int startHour;
  final int endHour;
  final int percent;

  bool isPast(DateTime now) => now.hour >= endHour;

  double progressForTime(DateTime now) {
    final start = DateTime(now.year, now.month, now.day, startHour);
    final end = DateTime(now.year, now.month, now.day, endHour);
    if (now.isAfter(end)) return 1;
    if (now.isBefore(start)) return 0;
    final total = end.difference(start).inMinutes;
    final passed = now.difference(start).inMinutes;
    return (passed / total).clamp(0, 1);
  }
}
