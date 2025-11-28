import 'package:flutter/material.dart';

/// Describes a type of drink selectable in the UI.
class DrinkType {
  const DrinkType({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.hydrationFactor,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int colorValue;

  /// Portion of the drink that counts towards hydration progress.
  /// 1.0 means full volume is credited, 0.0 means it is ignored.
  final double hydrationFactor;
  final bool isDefault;

  Color get color => Color(colorValue);

  DrinkType copyWith({
    String? id,
    String? name,
    int? colorValue,
    double? hydrationFactor,
    bool? isDefault,
  }) {
    return DrinkType(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      hydrationFactor: hydrationFactor ?? this.hydrationFactor,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'hydrationFactor': hydrationFactor,
        'isDefault': isDefault,
      };

  factory DrinkType.fromJson(Map<String, dynamic> json) {
    return DrinkType(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Напиток',
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      hydrationFactor:
          (json['hydrationFactor'] as num?)?.toDouble().clamp(0, 1) ?? 1.0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  static const waterId = 'water';

  static List<DrinkType> defaultTypes() => [
        const DrinkType(
          id: waterId,
          name: 'Вода',
          colorValue: 0xFF2196F3,
          hydrationFactor: 1.0,
          isDefault: true,
        ),
        const DrinkType(
          id: 'tea',
          name: 'Чай',
          colorValue: 0xFF4CAF50,
          hydrationFactor: 0.9,
          isDefault: true,
        ),
        const DrinkType(
          id: 'coffee',
          name: 'Кофе',
          colorValue: 0xFF795548,
          hydrationFactor: 0.7,
          isDefault: true,
        ),
        const DrinkType(
          id: 'juice',
          name: 'Сок',
          colorValue: 0xFFFF9800,
          hydrationFactor: 0.9,
          isDefault: true,
        ),
        const DrinkType(
          id: 'soda',
          name: 'Газировка',
          colorValue: 0xFF9C27B0,
          hydrationFactor: 0.7,
          isDefault: true,
        ),
        const DrinkType(
          id: 'sport',
          name: 'Спорт-напиток',
          colorValue: 0xFF00BCD4,
          hydrationFactor: 0.8,
          isDefault: true,
        ),
        const DrinkType(
          id: 'energy',
          name: 'Энергетик',
          colorValue: 0xFFFF5252,
          hydrationFactor: 0.6,
          isDefault: true,
        ),
        const DrinkType(
          id: 'alcohol',
          name: 'Алкоголь',
          colorValue: 0xFF9E9E9E, // Алкоголь не засчитывается в прогресс.
          hydrationFactor: 0.0, // Алкоголь не засчитывается в прогресс.
          isDefault: true,
        ),
        const DrinkType(
          id: 'other',
          name: 'Другое',
          colorValue: 0xFF3F51B5,
          hydrationFactor: 0.8,
          isDefault: true,
        ),
      ];
}
