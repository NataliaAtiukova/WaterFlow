enum MeasurementUnit { milliliters, ounces }

enum ThemePreference { system, light, dark }

enum CountingMode { factors, waterOnly, ignoreSugary }

class WaterSettings {
  const WaterSettings({
    required this.dailyGoal,
    required this.quickAddOptions,
    required this.notificationsEnabled,
    required this.notificationIntervalHours,
    required this.themePreference,
    this.countingMode = CountingMode.factors,
    this.unit = MeasurementUnit.milliliters,
  });

  final int dailyGoal;
  final List<int> quickAddOptions;
  final MeasurementUnit unit;
  final bool notificationsEnabled;
  final int notificationIntervalHours;
  final ThemePreference themePreference;
  final CountingMode countingMode;

  WaterSettings copyWith({
    int? dailyGoal,
    List<int>? quickAddOptions,
    MeasurementUnit? unit,
    bool? notificationsEnabled,
    int? notificationIntervalHours,
    ThemePreference? themePreference,
    CountingMode? countingMode,
  }) {
    return WaterSettings(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      quickAddOptions: quickAddOptions ?? this.quickAddOptions,
      unit: unit ?? this.unit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationIntervalHours:
          notificationIntervalHours ?? this.notificationIntervalHours,
      themePreference: themePreference ?? this.themePreference,
      countingMode: countingMode ?? this.countingMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyGoal': dailyGoal,
        'quickAddOptions': quickAddOptions,
        'unit': unit.name,
        'notificationsEnabled': notificationsEnabled,
        'notificationIntervalHours': notificationIntervalHours,
        'themePreference': themePreference.name,
        'countingMode': countingMode.name,
      };

  factory WaterSettings.fromJson(Map<String, dynamic> json) {
    final rawUnit = json['unit'] as String? ?? MeasurementUnit.milliliters.name;
    final rawTheme =
        json['themePreference'] as String? ?? ThemePreference.system.name;
    final countingModeRaw =
        json['countingMode'] as String? ?? (json['countOnlyWater'] == true
            ? CountingMode.waterOnly.name
            : CountingMode.factors.name);
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
      countingMode: CountingMode.values.firstWhere(
        (mode) => mode.name == countingModeRaw,
        orElse: () => CountingMode.factors,
      ),
    );
  }

  static const defaultSettings = WaterSettings(
    dailyGoal: 2000,
    quickAddOptions: [200, 250, 300],
    unit: MeasurementUnit.milliliters,
    notificationsEnabled: false,
    notificationIntervalHours: 2,
    themePreference: ThemePreference.system,
    countingMode: CountingMode.factors,
  );
}
