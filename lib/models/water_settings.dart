enum MeasurementUnit { milliliters, ounces }

enum ThemePreference { system, light, dark }

class WaterSettings {
  const WaterSettings({
    required this.dailyGoal,
    required this.quickAddOptions,
    required this.notificationsEnabled,
    required this.notificationIntervalHours,
    required this.themePreference,
    this.countOnlyWater = false,
    this.unit = MeasurementUnit.milliliters,
  });

  final int dailyGoal;
  final List<int> quickAddOptions;
  final MeasurementUnit unit;
  final bool notificationsEnabled;
  final int notificationIntervalHours;
  final ThemePreference themePreference;
  final bool countOnlyWater;

  WaterSettings copyWith({
    int? dailyGoal,
    List<int>? quickAddOptions,
    MeasurementUnit? unit,
    bool? notificationsEnabled,
    int? notificationIntervalHours,
    ThemePreference? themePreference,
    bool? countOnlyWater,
  }) {
    return WaterSettings(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      quickAddOptions: quickAddOptions ?? this.quickAddOptions,
      unit: unit ?? this.unit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationIntervalHours:
          notificationIntervalHours ?? this.notificationIntervalHours,
      themePreference: themePreference ?? this.themePreference,
      countOnlyWater: countOnlyWater ?? this.countOnlyWater,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyGoal': dailyGoal,
        'quickAddOptions': quickAddOptions,
        'unit': unit.name,
        'notificationsEnabled': notificationsEnabled,
        'notificationIntervalHours': notificationIntervalHours,
        'themePreference': themePreference.name,
        'countOnlyWater': countOnlyWater,
      };

  factory WaterSettings.fromJson(Map<String, dynamic> json) {
    final rawUnit = json['unit'] as String? ?? MeasurementUnit.milliliters.name;
    final rawTheme =
        json['themePreference'] as String? ?? ThemePreference.system.name;
    return WaterSettings(
      dailyGoal: json['dailyGoal'] as int? ?? 2000,
      quickAddOptions: (json['quickAddOptions'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [200, 250, 300],
      unit: MeasurementUnit.values.firstWhere(
        (u) => u.name == rawUnit,
        orElse: () => MeasurementUnit.milliliters,
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      notificationIntervalHours: json['notificationIntervalHours'] as int? ?? 2,
      themePreference: ThemePreference.values.firstWhere(
        (t) => t.name == rawTheme,
        orElse: () => ThemePreference.system,
      ),
      countOnlyWater: json['countOnlyWater'] as bool? ?? false,
    );
  }

  static const defaultSettings = WaterSettings(
    dailyGoal: 2000,
    quickAddOptions: [200, 250, 300],
    unit: MeasurementUnit.milliliters,
    notificationsEnabled: false,
    notificationIntervalHours: 2,
    themePreference: ThemePreference.system,
    countOnlyWater: false,
  );
}
