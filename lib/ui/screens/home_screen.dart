import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/drink_entry.dart';
import '../../models/drink_type.dart';
import '../../models/water_settings.dart';
import '../../providers/drink_types_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/today_drinks_provider.dart';
import '../../providers/services_provider.dart';
import '../widgets/add_water_buttons.dart';
import '../widgets/animated_progress_liquid.dart';
import '../widgets/drink_card_today.dart';
import '../widgets/drink_chip.dart';
import '../../widgets/yandex_banner.dart';
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
            onPressed: () => _openScreenWithAd(DrinksScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _openScreenWithAd(StatsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _openScreenWithAd(HistoryScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed(
              SettingsScreen.routeName,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const YandexStickyBanner(),
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
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, value, _) => AnimatedProgressLiquid(
                progress: value,
              ),
              onEnd: () => _lastPercent = currentPercent,
            );
            _lastPercent = currentPercent;

            final perDrink = _groupTodayEntries(today.entries, drinkTypes);
            final modeHint = _countingModeHint(settings.countingMode);

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
                    const SizedBox(height: 8),
                    _CaffeineSugarRow(
                      caffeineMg: today.totalCaffeine,
                      sugarGr: today.totalSugar,
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
                        'План на сейчас: ${today.plannedHydrationMl} мл',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (modeHint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          modeHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.orange),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 8),
                    _PlanDeviationBanner(deviation: today.deviationPercent),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Дата: ${_formatDate(today.date)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (modeHint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          modeHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.orange),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _DrinkChipScroller(
                      drinkTypes: drinkTypes,
                      selectedId: today.selectedDrinkTypeId,
                      onSelect: (id) => ref
                          .read(todayDrinksProvider.notifier)
                          .selectDrinkType(id),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 12),
                    AddWaterButtons(
                      options: settings.quickAddOptions,
                      onAdd: (amount) =>
                          ref.read(todayDrinksProvider.notifier).addDrink(amount),
                      onAddCustom: () =>
                          _showCustomAmountDialog(context, ref),
                    ),
                    const SizedBox(height: 32),
                    const Text('Сегодня',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (perDrink.isEmpty)
                      const Text('Добавьте первый напиток.')
                    else
                      Column(
                        children: [
                          for (final summary in perDrink)
                            DrinkCardToday(summary: summary),
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

  Future<void> _openScreenWithAd(String routeName) async {
    final interstitial = ref.read(interstitialAdServiceProvider);
    await interstitial.show();
    if (!mounted) return;
    await Navigator.of(context).pushNamed(routeName);
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

  List<DrinkSummary> _groupTodayEntries(
    List<DrinkEntry> entries,
    List<DrinkType> drinkTypes,
  ) {
    const fallback = DrinkType(
      id: 'deleted',
      name: 'Удалённый напиток',
      colorValue: 0xFF9E9E9E,
      hydrationFactor: 0,
      caffeineMg: 0,
      sugarGr: 0,
      category: DrinkCategory.other,
    );
    final summaries = <String, DrinkSummary>{};
    for (final entry in entries) {
      final drink = drinkTypes.firstWhere(
        (t) => t.id == entry.drinkTypeId,
        orElse: () => fallback.copyWith(id: entry.drinkTypeId),
      );
      final summary = summaries.putIfAbsent(
        drink.id,
        () => DrinkSummary(type: drink),
      );
      summary.totalVolume += entry.volumeMl;
      summary.effectiveVolume += entry.effectiveHydrationMl;
    }
    final list = summaries.values.toList()
      ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    return list;
  }
}

class _PlanDeviationBanner extends StatelessWidget {
  const _PlanDeviationBanner({required this.deviation});

  final double deviation;

  @override
  Widget build(BuildContext context) {
    String text;
    Color? color;
    if (deviation > 0.1) {
      text = 'Вы опережаете график на ${(deviation * 100).abs().toStringAsFixed(0)}%';
      color = Colors.green;
    } else if (deviation < -0.1) {
      text = 'Вы отстаёте на ${(deviation * -100).toStringAsFixed(0)}%';
      color = Colors.orange;
    } else {
      text = 'Вы идёте по графику';
      color = Colors.blueGrey;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

class _DrinkChipScroller extends StatelessWidget {
  const _DrinkChipScroller({
    required this.drinkTypes,
    required this.selectedId,
    required this.onSelect,
  });

  final List<DrinkType> drinkTypes;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final drink = drinkTypes[index];
          return DrinkChip(
            drink: drink,
            selected: drink.id == selectedId,
            onTap: () => onSelect(drink.id),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: drinkTypes.length,
      ),
    );
  }
}

class _CaffeineSugarRow extends StatelessWidget {
  const _CaffeineSugarRow({
    required this.caffeineMg,
    required this.sugarGr,
  });

  final int caffeineMg;
  final int sugarGr;

  static const int caffeineLimit = 400;
  static const int sugarLimit = 50;

  @override
  Widget build(BuildContext context) {
    final caffeineText =
        'Кофеина сегодня: $caffeineMg мг (из $caffeineLimit)';
    final sugarText = 'Сахара сегодня: $sugarGr г (из $sugarLimit)';
    final caffeineColor =
        caffeineMg > caffeineLimit ? Colors.orange : Colors.blueGrey;
    final sugarColor =
        sugarGr > sugarLimit ? Colors.orange : Colors.blueGrey;
    return Column(
      children: [
        Text(
          caffeineText,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: caffeineColor),
        ),
        const SizedBox(height: 4),
        Text(
          sugarText,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: sugarColor),
        ),
      ],
    );
  }
}

String? _countingModeHint(CountingMode mode) {
  switch (mode) {
    case CountingMode.factors:
      return null;
    case CountingMode.waterOnly:
      return 'В зачёт идёт только вода';
    case CountingMode.ignoreSugary:
      return 'Соки и газировка не увеличивают прогресс';
  }
}
