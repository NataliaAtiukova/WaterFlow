import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/drinks_repository.dart';
import '../../models/daily_progress.dart';
import '../../models/drink_type.dart';
import '../../providers/drink_types_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/settings_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  static const routeName = '/stats';

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedIndex = 0;
  DateTime? _breakdownDate;
  Map<String, DrinkTotals> _breakdown = const {};
  bool _loadingBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);
    final drinkTypesAsync = ref.watch(drinkTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика')),
      body: historyAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Нет данных'));
          }
          if (_selectedIndex >= items.length) _selectedIndex = 0;
          final selectedDay = items[_selectedIndex];
          if (_breakdownDate == null ||
              !DateUtils.isSameDay(_breakdownDate, selectedDay.date)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadBreakdown(selectedDay.date);
            });
          }
          final maxY = _calculateMaxY(items);
          final drinkTypes = drinkTypesAsync.value ?? DrinkType.defaultTypes();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(historyProvider.notifier).reload();
              await ref.read(drinkTypesProvider.notifier).reload();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildChart(items, maxY),
                  const SizedBox(height: 24),
                  _buildDayCards(items),
                  const SizedBox(height: 24),
                  Text(
                    'Распределение (${_formatDate(selectedDay.date)})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_loadingBreakdown)
                    const Center(child: CircularProgressIndicator())
                  else if (_breakdown.isEmpty)
                    const Text('Нет данных.')
                  else ...[
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 48,
                          sections: _buildPieSections(
                            drinkTypes,
                            _breakdown,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildBreakdownWidgets(
                      drinkTypes,
                      _breakdown,
                      selectedDay,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }

  Widget _buildChart(List<DailyProgress> items, double maxY) {
    return SizedBox(
      height: 280,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              if (response?.spot == null) return;
              final index = response!.spot!.touchedBarGroupIndex;
              if (index == _selectedIndex) return;
              setState(() {
                _selectedIndex = index;
              });
              _loadBreakdown(items[index].date);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final date = items[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${date.day}.${date.month}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].effectiveMl.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                    color: i == _selectedIndex
                        ? Colors.blueAccent
                        : Colors.blueAccent.withValues(alpha: 0.4),
                  ),
                ],
              ),
          ],
          maxY: maxY,
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildDayCards(List<DailyProgress> items) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.8, initialPage: 0),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
          _loadBreakdown(items[index].date);
        },
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: index == _selectedIndex ? 1 : 0.94,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isToday() ? 'Сегодня' : _formatDate(item.date),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Зачтено: ${item.effectiveMl} мл'),
                    Text('Всего: ${item.totalVolumeMl} мл'),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '${(item.percent * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<DrinkType> drinkTypes,
    Map<String, DrinkTotals> data,
  ) {
    final total = data.values.fold<int>(0, (sum, e) => sum + e.volumeMl);
    if (total == 0) return [];
    return data.entries.map((entry) {
      final drink = drinkTypes.firstWhere(
        (d) => d.id == entry.key,
        orElse: () => DrinkType(
          id: entry.key,
          name: 'Удалённый',
          colorValue: 0xFF9E9E9E,
          hydrationFactor: 0,
          caffeineMg: 0,
          sugarGr: 0,
          category: DrinkCategory.other,
          isDefault: false,
        ),
      );
      final percent = entry.value.volumeMl / total * 100;
      return PieChartSectionData(
        value: percent,
        title: '${percent.toStringAsFixed(0)}%',
        color: drink.color,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();
  }

  List<Widget> _buildBreakdownWidgets(
    List<DrinkType> drinkTypes,
    Map<String, DrinkTotals> data,
    DailyProgress day,
  ) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.volumeMl.compareTo(a.value.volumeMl));
    return entries.map((entry) {
      final drink = drinkTypes.firstWhere(
        (d) => d.id == entry.key,
        orElse: () => DrinkType(
          id: entry.key,
          name: 'Удалённый',
          colorValue: 0xFF9E9E9E,
          hydrationFactor: 0,
          caffeineMg: 0,
          sugarGr: 0,
          category: DrinkCategory.other,
          isDefault: false,
        ),
      );
      final percent = day.totalVolumeMl == 0
          ? 0.0
          : (entry.value.volumeMl / day.totalVolumeMl * 100);
      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: drink.color,
          child: Text(
            drink.name.isNotEmpty ? drink.name.characters.first : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(drink.name),
        subtitle: Text(
          '${entry.value.volumeMl} мл · зачтено ${entry.value.effectiveMl} мл',
        ),
        trailing: Text('${percent.toStringAsFixed(0)}%'),
      );
    }).toList();
  }

  double _calculateMaxY(List<DailyProgress> items) {
    final maxEffective = items
        .map((e) => e.effectiveMl)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);
    return (maxEffective * 1.2).clamp(500, 8000).toDouble();
  }

  Future<void> _loadBreakdown(DateTime date) async {
    setState(() {
      _loadingBreakdown = true;
    });
    final repo = await ref.read(drinksRepositoryProvider.future);
    final totals = await repo.totalsByDrinkForDay(date);
    if (!mounted) return;
    setState(() {
      _breakdownDate = date;
      _breakdown = totals;
      _loadingBreakdown = false;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
