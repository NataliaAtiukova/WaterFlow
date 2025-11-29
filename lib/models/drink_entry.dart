import 'package:uuid/uuid.dart';

import 'drink_type.dart';

/// Single log entry of consumed liquid with hydration impact pre-calculated.
class DrinkEntry {
  DrinkEntry({
    required this.id,
    required this.drinkTypeId,
    required this.volumeMl,
    required this.dateTime,
    required this.effectiveHydrationMl,
    required this.caffeineMg,
    required this.sugarGr,
  });

  factory DrinkEntry.fromDrinkType({
    required DrinkType type,
    required int volumeMl,
    DateTime? dateTime,
  }) {
    final timestamp = dateTime ?? DateTime.now();
    final hydration =
        (volumeMl * type.hydrationFactor).floor().clamp(0, volumeMl);
    return DrinkEntry(
      id: const Uuid().v4(),
      drinkTypeId: type.id,
      volumeMl: volumeMl,
      dateTime: timestamp,
      effectiveHydrationMl: hydration,
      caffeineMg: (type.caffeineMg * volumeMl / 250).round(),
      sugarGr: (type.sugarGr * volumeMl / 250).round(),
    );
  }

  final String id;
  final String drinkTypeId;
  final int volumeMl;
  final DateTime dateTime;

  /// Cached hydrated amount to avoid recalculating with outdated coefficients.
  final int effectiveHydrationMl;
  final int caffeineMg;
  final int sugarGr;

  DrinkEntry copyWith({
    String? id,
    String? drinkTypeId,
    int? volumeMl,
    DateTime? dateTime,
    int? effectiveHydrationMl,
    int? caffeineMg,
    int? sugarGr,
  }) {
    return DrinkEntry(
      id: id ?? this.id,
      drinkTypeId: drinkTypeId ?? this.drinkTypeId,
      volumeMl: volumeMl ?? this.volumeMl,
      dateTime: dateTime ?? this.dateTime,
      effectiveHydrationMl:
          effectiveHydrationMl ?? this.effectiveHydrationMl,
      caffeineMg: caffeineMg ?? this.caffeineMg,
      sugarGr: sugarGr ?? this.sugarGr,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'drinkTypeId': drinkTypeId,
        'volumeMl': volumeMl,
        'dateTime': dateTime.toIso8601String(),
        'effectiveHydrationMl': effectiveHydrationMl,
        'caffeineMg': caffeineMg,
        'sugarGr': sugarGr,
      };

  factory DrinkEntry.fromJson(Map<String, dynamic> json) {
    return DrinkEntry(
      id: json['id'] as String,
      drinkTypeId: json['drinkTypeId'] as String,
      volumeMl: json['volumeMl'] as int? ?? 0,
      dateTime: DateTime.parse(json['dateTime'] as String),
      effectiveHydrationMl: json['effectiveHydrationMl'] as int? ??
          (json['volumeMl'] as int? ?? 0),
      caffeineMg: json['caffeineMg'] as int? ?? 0,
      sugarGr: json['sugarGr'] as int? ?? 0,
    );
  }
}
