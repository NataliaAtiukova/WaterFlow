import 'package:flutter/material.dart';

enum DrinkCategory { water, caffeinated, sugary, sports, alcohol, other }
/// Describes a type of drink selectable in the UI.
class DrinkType {
  const DrinkType({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.hydrationFactor,
    required this.caffeineMg,
    required this.sugarGr,
    required this.category,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final int colorValue;

  /// Portion of the drink that counts towards hydration progress.
  /// 1.0 means full volume is credited, 0.0 means it is ignored.
  final double hydrationFactor;
  final int caffeineMg;
  final int sugarGr;
  final DrinkCategory category;
  final bool isDefault;

  Color get color => Color(colorValue);

  DrinkType copyWith({
    String? id,
    String? name,
    int? colorValue,
    double? hydrationFactor,
    int? caffeineMg,
    int? sugarGr,
    DrinkCategory? category,
    bool? isDefault,
  }) {
    return DrinkType(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      hydrationFactor: hydrationFactor ?? this.hydrationFactor,
      caffeineMg: caffeineMg ?? this.caffeineMg,
      sugarGr: sugarGr ?? this.sugarGr,
      category: category ?? this.category,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'hydrationFactor': hydrationFactor,
        'caffeineMg': caffeineMg,
        'sugarGr': sugarGr,
        'category': category.name,
        'isDefault': isDefault,
      };

  factory DrinkType.fromJson(Map<String, dynamic> json) {
    return DrinkType(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Напиток',
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      hydrationFactor:
          (json['hydrationFactor'] as num?)?.toDouble().clamp(0, 1) ?? 1.0,
      caffeineMg: (json['caffeineMg'] as num?)?.toInt() ?? 0,
      sugarGr: (json['sugarGr'] as num?)?.toInt() ?? 0,
      category: DrinkCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String? ?? DrinkCategory.other.name),
        orElse: () => DrinkCategory.other,
      ),
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
          caffeineMg: 0,
          sugarGr: 0,
          category: DrinkCategory.water,
          isDefault: true,
        ),
        const DrinkType(
          id: 'tea',
          name: 'Чай',
          colorValue: 0xFF4CAF50,
          hydrationFactor: 0.9,
          caffeineMg: 40,
          sugarGr: 0,
          category: DrinkCategory.caffeinated,
          isDefault: true,
        ),
        const DrinkType(
          id: 'coffee',
          name: 'Кофе',
          colorValue: 0xFF795548,
          hydrationFactor: 0.7,
          caffeineMg: 95,
          sugarGr: 0,
          category: DrinkCategory.caffeinated,
          isDefault: true,
        ),
        const DrinkType(
          id: 'juice',
          name: 'Сок',
          colorValue: 0xFFFF9800,
          hydrationFactor: 0.9,
          caffeineMg: 0,
          sugarGr: 20,
          category: DrinkCategory.sugary,
          isDefault: true,
        ),
        const DrinkType(
          id: 'soda',
          name: 'Газировка',
          colorValue: 0xFF9C27B0,
          hydrationFactor: 0.7,
          caffeineMg: 0,
          sugarGr: 25,
          category: DrinkCategory.sugary,
          isDefault: true,
        ),
        const DrinkType(
          id: 'sport',
          name: 'Спорт-напиток',
          colorValue: 0xFF00BCD4,
          hydrationFactor: 0.8,
          caffeineMg: 0,
          sugarGr: 15,
          category: DrinkCategory.sports,
          isDefault: true,
        ),
        const DrinkType(
          id: 'energy',
          name: 'Энергетик',
          colorValue: 0xFFFF5252,
          hydrationFactor: 0.6,
          caffeineMg: 80,
          sugarGr: 28,
          category: DrinkCategory.caffeinated,
          isDefault: true,
        ),
        const DrinkType(
          id: 'alcohol',
          name: 'Алкоголь',
          colorValue: 0xFF9E9E9E, // Алкоголь не засчитывается в прогресс.
          hydrationFactor: 0.0, // Алкоголь не засчитывается в прогресс.
          caffeineMg: 0,
          sugarGr: 0,
          category: DrinkCategory.alcohol,
          isDefault: true,
        ),
        const DrinkType(
          id: 'other',
          name: 'Другое',
          colorValue: 0xFF3F51B5,
          hydrationFactor: 0.8,
          caffeineMg: 0,
          sugarGr: 0,
          category: DrinkCategory.other,
          isDefault: true,
        ),
      ];
}
