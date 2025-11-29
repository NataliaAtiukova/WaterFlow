/// Stub service that would integrate with Health Connect / Google Fit.
/// In a production build this should use the respective platform APIs.
class HealthSyncService {
  Future<void> syncDailyGoal(int goalMl) async {
    // TODO: integrate with Health Connect / Google Fit hydration goal APIs.
  }

  Future<void> syncHydration({
    required int effectiveMl,
    required int totalMl,
  }) async {
    // TODO: push hydration data to Health Connect / Google Fit.
  }
}
