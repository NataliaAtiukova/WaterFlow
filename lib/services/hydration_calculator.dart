import '../models/body_metrics.dart';

class HydrationCalculator {
  // Calculates daily water goal in ml using a physiologically-inspired formula.
  static int calculateDailyGoal(BodyMetrics metrics) {
    const basePerKg = 35; // 35ml per kg baseline.
    double goal = metrics.weightKg * basePerKg;

    switch (metrics.activityLevel) {
      case ActivityLevel.sedentary:
        goal *= 1.0;
        break;
      case ActivityLevel.moderate:
        goal *= 1.1;
        break;
      case ActivityLevel.intense:
        goal *= 1.25;
        break;
    }

    switch (metrics.climateCondition) {
      case ClimateCondition.cold:
        goal -= 200;
        break;
      case ClimateCondition.normal:
        break;
      case ClimateCondition.hot:
        goal += 300;
        break;
    }

    if (metrics.hadWorkoutToday) {
      goal += 500;
    }

    return goal.clamp(1200, 6000).round();
  }
}
