import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/drink_entry.dart';
import '../../models/drink_type.dart';
import '../../models/water_settings.dart';
import '../../providers/drink_types_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/today_drinks_provider.dart';
import '../widgets/add_water_buttons.dart';
import '../widgets/progress_circle.dart';
import 'drinks_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _lastPercent = 0;

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayDrinksProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final drinkTypesAsync = ref.watch(drinkTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Трекер жидкостей'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_drink_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(DrinksScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () =>
                Navigator.of(context).pushNamed(StatsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed(
              HistoryScreen.routeName,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(
              SettingsScreen.routeName,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: todayAsync.when(
          data: (today) {
            if (drinkTypesAsync.hasError) {
              return Center(
                  child: Text('Ошибка загрузки напитков: ${drinkTypesAsync.error}'));
            }
            final drinkTypes = drinkTypesAsync.value;
            if (drinkTypes == null || drinkTypes.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final settings =
                settingsAsync.value ?? WaterSettings.defaultSettings;
            final percentVal = today.toDailyProgress().percent;
            final double currentPercent = percentVal.clamp(0.0, 1.0).toDouble();

            final animated = TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: _lastPercent, end: currentPercent),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) => ProgressCircle(
                progress: value,
                percentageText: '${(value * 100).toStringAsFixed(0)}%',
              ),
              onEnd: () => _lastPercent = currentPercent,
            );
            _lastPercent = currentPercent;

            final perDrink = _groupTodayEntries(today.entries, drinkTypes);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(todayDrinksProvider);
                await ref.read(todayDrinksProvider.future);
                await ref.read(drinkTypesProvider.notifier).reload();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: animated),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Зачтено: ${today.effectiveHydrationMl} мл / ${today.target} мл',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Всего выпито: ${today.totalVolumeMl} мл',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Дата: ${_formatDate(today.date)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (settings.countOnlyWater)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'В зачёт идёт только вода',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.orange),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Выберите напиток',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final drink = drinkTypes[index];
                          final selected =
                              drink.id == today.selectedDrinkTypeId;
                          return ChoiceChip(
                            label: Text(drink.name),
                            avatar: CircleAvatar(
                              backgroundColor: drink.color,
                              radius: 8,
                            ),
                            selected: selected,
                            onSelected: (_) => ref
                                .read(todayDrinksProvider.notifier)
                                .selectDrinkType(drink.id),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: drinkTypes.length,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Добавить объём',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    AddWaterButtons(
                      options: settings.quickAddOptions,
                      onAdd: (amount) =>
                          ref.read(todayDrinksProvider.notifier).addDrink(amount),
                      onAddCustom: () =>
                          _showCustomAmountDialog(context, ref),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Сегодня',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (perDrink.isEmpty)
                      const Text(
                        'Добавьте первый напиток — он появится здесь.',
                      )
                    else
                      Column(
                        children: [
                          for (final summary in perDrink)
                            ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: summary.type.color,
                                child: Text(
                                  summary.type.name.isNotEmpty
                                      ? summary.type.name.characters.first
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(summary.type.name),
                              subtitle: Text(
                                  '${summary.totalVolume} мл · зачтено ${summary.effectiveVolume} мл'),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Не удалось загрузить данные'),
                Text(err.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomAmountDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Другой объём'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Миллилитры',
              hintText: 'Например, 180',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );

    if (amount != null && amount > 0) {
      await ref.read(todayDrinksProvider.notifier).addCustomDrink(amount);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  List<_DrinkSummary> _groupTodayEntries(
    List<DrinkEntry> entries,
    List<DrinkType> drinkTypes,
  ) {
    const fallback = DrinkType(
      id: 'deleted',
      name: 'Удалённый напиток',
      colorValue: 0xFF9E9E9E,
      hydrationFactor: 0,
    );
    final summaries = <String, _DrinkSummary>{};
    for (final entry in entries) {
      final drink = drinkTypes.firstWhere(
        (t) => t.id == entry.drinkTypeId,
        orElse: () => fallback.copyWith(id: entry.drinkTypeId),
      );
      final summary = summaries.putIfAbsent(
        drink.id,
        () => _DrinkSummary(type: drink),
      );
      summary.totalVolume += entry.volumeMl;
      summary.effectiveVolume += entry.effectiveHydrationMl;
    }
    final list = summaries.values.toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    return list;
  }
}

class _DrinkSummary {
  _DrinkSummary({required this.type});

  final DrinkType type;
  int totalVolume = 0;
  int effectiveVolume = 0;
}
