import 'package:flutter/material.dart';

class DailyProgress {
  const DailyProgress({
    required this.date,
    required this.target,
    required this.effectiveMl,
    required this.totalVolumeMl,
  });

  final DateTime date;
  final int target;

  /// Hydration credited towards the goal ("Зачтено").
  final int effectiveMl;

  /// Total fluid consumed regardless of hydration factor.
  final int totalVolumeMl;

  double get percent =>
      target == 0 ? 0 : (effectiveMl / target).clamp(0, double.infinity);

  DailyProgress copyWith({
    DateTime? date,
    int? target,
    int? effectiveMl,
    int? totalVolumeMl,
  }) {
    return DailyProgress(
      date: date ?? this.date,
      target: target ?? this.target,
      effectiveMl: effectiveMl ?? this.effectiveMl,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'target': target,
        'effectiveMl': effectiveMl,
        'totalVolumeMl': totalVolumeMl,
      };

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    final consumed = json['consumed'] as int?; // legacy key.
    final effective = json['effectiveMl'] as int? ?? consumed ?? 0;
    final total = json['totalVolumeMl'] as int? ?? consumed ?? effective;
    return DailyProgress(
      date: DateTime.parse(json['date'] as String),
      target: json['target'] as int? ?? 0,
      effectiveMl: effective,
      totalVolumeMl: total,
    );
  }

  bool isToday() => DateUtils.isSameDay(date, DateTime.now());
}
