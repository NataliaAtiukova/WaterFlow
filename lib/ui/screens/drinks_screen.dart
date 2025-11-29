import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/drink_type.dart';
import '../../providers/drink_types_provider.dart';

class DrinksScreen extends ConsumerStatefulWidget {
  const DrinksScreen({super.key});

  static const routeName = '/drinks';

  @override
  ConsumerState<DrinksScreen> createState() => _DrinksScreenState();
}

class _DrinksScreenState extends ConsumerState<DrinksScreen> {
  @override
  Widget build(BuildContext context) {
    final drinksAsync = ref.watch(drinkTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Напитки')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDrinkDialog(context),
        label: const Text('Добавить'),
        icon: const Icon(Icons.add),
      ),
      body: drinksAsync.when(
        data: (drinks) {
          if (drinks.isEmpty) {
            return const Center(child: Text('Список напитков пуст'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drinks.length,
            itemBuilder: (context, index) {
              final drink = drinks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: drink.color),
                  title: Text(drink.name),
                  subtitle: Text(
                    '${_categoryLabel(drink.category)} · '
                    'В зачёт: ${(drink.hydrationFactor * 100).round()}% · '
                    'Кофеин: ${drink.caffeineMg} мг · Сахар: ${drink.sugarGr} г',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showDrinkDialog(context, drink: drink),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: drink.isDefault
                            ? null
                            : () => _deleteDrink(context, drink),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }

  Future<void> _deleteDrink(BuildContext context, DrinkType drink) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Удалить "${drink.name}"?'),
            content: const Text(
              'Прошлые записи будут перенесены в категорию "Вода".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    await ref.read(drinkTypesProvider.notifier).deleteDrinkType(drink.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${drink.name}" удалён')),
    );
  }

  Future<void> _showDrinkDialog(
    BuildContext context, {
    DrinkType? drink,
  }) async {
    final nameController = TextEditingController(text: drink?.name ?? '');
    double hydrationPercent = (drink?.hydrationFactor ?? 1.0) * 100;
    int colorValue = drink?.colorValue ?? 0xFF2196F3;
    final caffeineController =
        TextEditingController(text: (drink?.caffeineMg ?? 0).toString());
    final sugarController =
        TextEditingController(text: (drink?.sugarGr ?? 0).toString());
    DrinkCategory category = drink?.category ?? DrinkCategory.other;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(drink == null ? 'Новый напиток' : 'Редактирование'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Название'),
                    ),
                    const SizedBox(height: 16),
                    Text('Гидратация: ${hydrationPercent.round()}%'),
                    Slider(
                      value: hydrationPercent,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) {
                        setState(() => hydrationPercent = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: caffeineController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Кофеин (мг на 250 мл)',
                        hintText: 'Например, 40',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sugarController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Сахар (г на 250 мл)',
                        hintText: 'Например, 20',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DrinkCategory>(
                      // ignore: deprecated_member_use
                      value: category,
                      items: DrinkCategory.values
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(_categoryLabel(cat)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => category = value);
                      },
                      decoration:
                          const InputDecoration(labelText: 'Категория'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Цвет'),
                    Wrap(
                      spacing: 8,
                      children: _colorOptions.map((color) {
                        final selected = color == colorValue;
                        return GestureDetector(
                          onTap: () => setState(() => colorValue = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    selected ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !context.mounted) {
      nameController.dispose();
      caffeineController.dispose();
      sugarController.dispose();
      return;
    }

    final caffeine =
        (int.tryParse(caffeineController.text) ?? 0).clamp(0, 1000);
    final sugar = (int.tryParse(sugarController.text) ?? 0).clamp(0, 200);

    final newDrink = DrinkType(
      id: drink?.id ??
          'custom_${DateTime.now().millisecondsSinceEpoch.toString()}',
      name: nameController.text.trim(),
      colorValue: colorValue,
      hydrationFactor: (hydrationPercent / 100).clamp(0, 1),
      caffeineMg: caffeine,
      sugarGr: sugar,
      category: category,
      isDefault: drink?.isDefault ?? false,
    );
    await ref.read(drinkTypesProvider.notifier).saveDrinkType(newDrink);
    nameController.dispose();
    caffeineController.dispose();
    sugarController.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          drink == null ? 'Напиток добавлен' : 'Изменения сохранены',
        ),
      ),
    );
  }

  static const _colorOptions = [
    0xFF2196F3,
    0xFF4CAF50,
    0xFFFF9800,
    0xFFF44336,
    0xFF9C27B0,
    0xFF009688,
    0xFF795548,
    0xFF3F51B5,
    0xFF9E9E9E,
  ];

  String _categoryLabel(DrinkCategory category) {
    switch (category) {
      case DrinkCategory.water:
        return 'Вода';
      case DrinkCategory.caffeinated:
        return 'Кофеиновые';
      case DrinkCategory.sugary:
        return 'Сладкие';
      case DrinkCategory.sports:
        return 'Спортивные';
      case DrinkCategory.alcohol:
        return 'Алкоголь';
      case DrinkCategory.other:
        return 'Другое';
    }
  }
}
