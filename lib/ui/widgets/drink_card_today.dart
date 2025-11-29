import 'package:flutter/material.dart';

import '../../models/drink_type.dart';

class DrinkCardToday extends StatelessWidget {
  const DrinkCardToday({
    super.key,
    required this.summary,
  });

  final DrinkSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = summary.type.color;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              leading: Icon(Icons.local_drink, color: color),
              title: Text(summary.type.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Объём: ${summary.totalVolume} мл'),
                  Text('Зачтено: ${summary.effectiveVolume} мл'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrinkSummary {
  DrinkSummary({required this.type});

  final DrinkType type;
  int totalVolume = 0;
  int effectiveVolume = 0;
}
