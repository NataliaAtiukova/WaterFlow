enum ActivityLevel { sedentary, moderate, intense }

enum ClimateCondition { cold, normal, hot }

class BodyMetrics {
  const BodyMetrics({
    required this.weightKg,
    required this.activityLevel,
    required this.climateCondition,
    required this.hadWorkoutToday,
  });

  final double weightKg;
  final ActivityLevel activityLevel;
  final ClimateCondition climateCondition;
  final bool hadWorkoutToday;

  BodyMetrics copyWith({
    double? weightKg,
    ActivityLevel? activityLevel,
    ClimateCondition? climateCondition,
    bool? hadWorkoutToday,
  }) {
    return BodyMetrics(
      weightKg: weightKg ?? this.weightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      climateCondition: climateCondition ?? this.climateCondition,
      hadWorkoutToday: hadWorkoutToday ?? this.hadWorkoutToday,
    );
  }

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'activityLevel': activityLevel.name,
        'climateCondition': climateCondition.name,
        'hadWorkoutToday': hadWorkoutToday,
      };

  factory BodyMetrics.fromJson(Map<String, dynamic> json) {
    final rawActivity =
        json['activityLevel'] as String? ?? ActivityLevel.sedentary.name;
    final rawClimate =
        json['climateCondition'] as String? ?? ClimateCondition.normal.name;
    return BodyMetrics(
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
      activityLevel: ActivityLevel.values.firstWhere(
        (a) => a.name == rawActivity,
        orElse: () => ActivityLevel.sedentary,
      ),
      climateCondition: ClimateCondition.values.firstWhere(
        (c) => c.name == rawClimate,
        orElse: () => ClimateCondition.normal,
      ),
      hadWorkoutToday: json['hadWorkoutToday'] as bool? ?? false,
    );
  }

  static const BodyMetrics defaults = BodyMetrics(
    weightKg: 70,
    activityLevel: ActivityLevel.sedentary,
    climateCondition: ClimateCondition.normal,
    hadWorkoutToday: false,
  );
}
