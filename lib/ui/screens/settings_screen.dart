import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/body_metrics.dart';
import '../../models/day_schedule.dart';
import '../../models/water_settings.dart';
import '../../providers/body_metrics_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/hydration_calculator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _goalController = TextEditingController(
    text: WaterSettings.defaultSettings.dailyGoal.toString(),
  );
  final _weightController = TextEditingController(
    text: BodyMetrics.defaults.weightKg.toStringAsFixed(0),
  );
  final List<TextEditingController> _quickControllers = [];
  MeasurementUnit _unit = MeasurementUnit.milliliters;
  ThemePreference _theme = ThemePreference.system;
  bool _notificationsEnabled = false;
  double _intervalHours = 2;
  CountingMode _countingMode = CountingMode.factors;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  ClimateCondition _climateCondition = ClimateCondition.normal;
  bool _hadWorkout = false;
  bool _initializedFromState = false;
  bool _metricsInitialized = false;
  bool _scheduleInitialized = false;
  int _morningPercent = DaySchedule.defaultSchedule.morningPercent;
  int _afternoonPercent = DaySchedule.defaultSchedule.afternoonPercent;
  int _eveningPercent = DaySchedule.defaultSchedule.eveningPercent;
  int? _selectedPresetIndex;

  @override
  void initState() {
    super.initState();
    _applySettingsToControllers(WaterSettings.defaultSettings, notify: false);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _weightController.dispose();
    for (final c in _quickControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final metricsAsync = ref.watch(bodyMetricsProvider);
    final scheduleAsync = ref.watch(scheduleProvider);

    settingsAsync.whenData((settings) {
      if (!_initializedFromState) {
        _applySettingsToControllers(settings);
        _initializedFromState = true;
      }
    });

    metricsAsync.whenData((metrics) {
      if (!_metricsInitialized) {
        _applyMetrics(metrics);
        _metricsInitialized = true;
      }
    });

    scheduleAsync.whenData((schedule) {
      if (!_scheduleInitialized) {
        _applySchedule(schedule);
        _scheduleInitialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: settingsAsync.when(
        data: (_) => metricsAsync.when(
          data: (_) => scheduleAsync.when(
            data: (_) => _buildForm(context),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Ошибка: $err')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Ошибка: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
    );
  }

  void _applyMetrics(BodyMetrics metrics) {
    _weightController.text = metrics.weightKg.toStringAsFixed(0);
    _activityLevel = metrics.activityLevel;
    _climateCondition = metrics.climateCondition;
    _hadWorkout = metrics.hadWorkoutToday;
  }

  void _applySchedule(DaySchedule schedule) {
    _morningPercent = schedule.morningPercent;
    _afternoonPercent = schedule.afternoonPercent;
    _eveningPercent = schedule.eveningPercent;
    _selectedPresetIndex = _findPresetIndex(schedule);
  }

  Widget _buildScheduleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дневной план-график',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(DaySchedule.presets.length, (index) {
            final preset = DaySchedule.presets[index];
            final selected = _selectedPresetIndex == index;
            final label = switch (index) {
              0 => 'Сбалансированный',
              1 => 'Ранний старт',
              2 => 'Ночной режим',
              _ => 'Пресет ${index + 1}',
            };
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _applySchedule(preset);
                  _scheduleInitialized = true;
                  _selectedPresetIndex = index;
                });
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        Text('Утро: $_morningPercent%'),
        Slider(
          min: 10,
          max: 70,
          divisions: 12,
          value: _morningPercent.toDouble(),
          label: '$_morningPercent%',
          onChanged: (value) {
            setState(() {
              _morningPercent = value.round();
              final maxAfternoon = 100 - _morningPercent - 10;
              if (_afternoonPercent > maxAfternoon) {
                _afternoonPercent = maxAfternoon.clamp(10, 70);
              }
              _eveningPercent = 100 - _morningPercent - _afternoonPercent;
              _selectedPresetIndex = null;
            });
          },
        ),
        const SizedBox(height: 8),
        Text('День: $_afternoonPercent%'),
        Slider(
          min: 10,
          max: (100 - _morningPercent - 10).toDouble(),
          divisions: 12,
          value: _afternoonPercent.toDouble().clamp(
                10,
                (100 - _morningPercent - 10).toDouble(),
              ),
          label: '$_afternoonPercent%',
          onChanged: (value) {
            setState(() {
              _afternoonPercent = value.round();
              _eveningPercent = 100 - _morningPercent - _afternoonPercent;
              _selectedPresetIndex = null;
            });
          },
        ),
        const SizedBox(height: 8),
        Text('Вечер: $_eveningPercent%'),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _goalController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Дневная цель (мл)',
              helperText: 'Автоматический расчёт по параметрам тела',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Параметры тела',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Вес (кг)',
              hintText: 'Например, 70',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            // ignore: deprecated_member_use
            value: _activityLevel,
            items: ActivityLevel.values
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(_activityLabel(level)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _activityLevel = value);
            },
            decoration: const InputDecoration(labelText: 'Уровень активности'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ClimateCondition>(
            // ignore: deprecated_member_use
            value: _climateCondition,
            items: ClimateCondition.values
                .map(
                  (climate) => DropdownMenuItem(
                    value: climate,
                    child: Text(_climateLabel(climate)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _climateCondition = value);
            },
            decoration: const InputDecoration(labelText: 'Климат'),
          ),
          SwitchListTile(
            value: _hadWorkout,
            onChanged: (val) => setState(() => _hadWorkout = val),
            title: const Text('Сегодня тренировка'),
          ),
          const SizedBox(height: 12),
          Text(
            'Режим подсчёта напитков',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...CountingMode.values.map(
            (mode) => RadioListTile<CountingMode>(
              title: Text(_countingModeLabel(mode)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: _countingMode,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) setState(() => _countingMode = val);
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildScheduleSection(context),
          const SizedBox(height: 12),
          DropdownButtonFormField<ThemePreference>(
            // ignore: deprecated_member_use
            value: _theme,
            items: ThemePreference.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_themeLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _theme = value);
            },
            decoration: const InputDecoration(labelText: 'Тема'),
          ),
          const SizedBox(height: 20),
          Text(
            'Быстрые кнопки',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._buildQuickFields(),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            title: const Text('Напоминания каждые N часов'),
            subtitle: const Text('Отключаются при достижении цели'),
          ),
          if (_notificationsEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Интервал (часов): ${_intervalHours.toStringAsFixed(0)}'),
                Slider(
                  min: 1,
                  max: 6,
                  divisions: 5,
                  value: _intervalHours,
                  label: _intervalHours.toStringAsFixed(0),
                  onChanged: (v) => setState(() => _intervalHours = v),
                ),
              ],
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MeasurementUnit>(
            // ignore: deprecated_member_use
            value: _unit,
            items: MeasurementUnit.values
                .map(
                  (unit) => DropdownMenuItem(
                    value: unit,
                    child: Text(_unitLabel(unit)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _unit = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Единицы измерения',
              helperText:
                  'Сейчас используется только мл, но структура готова к унциям.',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuickFields() {
    return List.generate(_quickControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: _quickControllers[index],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Кнопка ${index + 1} (мл)'),
        ),
      );
    });
  }

  void _applySettingsToControllers(
    WaterSettings settings, {
    bool notify = true,
  }) {
    _goalController.text = settings.dailyGoal.toString();
    _unit = settings.unit;
    _theme = settings.themePreference;
    _notificationsEnabled = settings.notificationsEnabled;
    _intervalHours = settings.notificationIntervalHours.toDouble();
    _countingMode = settings.countingMode;

    _quickControllers.clear();
    for (final option in settings.quickAddOptions) {
      _quickControllers.add(TextEditingController(text: option.toString()));
    }
    // Guarantee at least 3 fields.
    while (_quickControllers.length < 3) {
      _quickControllers.add(TextEditingController(text: '0'));
    }
    if (notify && mounted) {
      setState(() {});
    }
  }

  Future<void> _saveSettings() async {
    final weight = double.tryParse(_weightController.text) ?? 70;
    final newMetrics = BodyMetrics(
      weightKg: weight.clamp(35, 200),
      activityLevel: _activityLevel,
      climateCondition: _climateCondition,
      hadWorkoutToday: _hadWorkout,
    );
    await ref.read(bodyMetricsProvider.notifier).updateMetrics(newMetrics);
    final recalculatedGoal =
        HydrationCalculator.calculateDailyGoal(newMetrics);

    final quickValues = _quickControllers
        .map((c) => int.tryParse(c.text) ?? 0)
        .where((v) => v > 0)
        .toList();

    final currentSettings = await ref.read(settingsProvider.future);
    final updated = currentSettings.copyWith(
      quickAddOptions:
          quickValues.isNotEmpty ? quickValues : const [200, 250, 300],
      unit: _unit,
      notificationsEnabled: _notificationsEnabled,
      notificationIntervalHours: _intervalHours.round().clamp(1, 12),
      themePreference: _theme,
      countingMode: _countingMode,
    );

    await ref.read(scheduleProvider.notifier).updateSchedule(
          DaySchedule(
            morningPercent: _morningPercent,
            afternoonPercent: _afternoonPercent,
            eveningPercent: _eveningPercent,
          ),
        );
    await ref.read(settingsProvider.notifier).saveSettings(updated);
    _goalController.text = recalculatedGoal.toString();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Настройки сохранены')));
      Navigator.of(context).pop();
    }
  }

  String _unitLabel(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.milliliters:
        return 'Миллилитры';
      case MeasurementUnit.ounces:
        return 'Унции (готово к будущему)';
    }
  }

  String _themeLabel(ThemePreference pref) {
    switch (pref) {
      case ThemePreference.system:
        return 'Системная';
      case ThemePreference.light:
        return 'Светлая';
      case ThemePreference.dark:
        return 'Тёмная';
    }
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Сидячий образ';
      case ActivityLevel.moderate:
        return 'Средняя активность';
      case ActivityLevel.intense:
        return 'Интенсивная активность';
    }
  }

  String _climateLabel(ClimateCondition climate) {
    switch (climate) {
      case ClimateCondition.cold:
        return 'Холодный климат';
      case ClimateCondition.normal:
        return 'Нормальный климат';
      case ClimateCondition.hot:
        return 'Жаркий климат';
    }
  }

  String _countingModeLabel(CountingMode mode) {
    switch (mode) {
      case CountingMode.factors:
        return 'Все напитки с коэффициентами';
      case CountingMode.waterOnly:
        return 'В зачёт только вода';
      case CountingMode.ignoreSugary:
        return 'Игнорировать соки и газировку';
    }
  }

  int? _findPresetIndex(DaySchedule schedule) {
    for (var i = 0; i < DaySchedule.presets.length; i++) {
      final preset = DaySchedule.presets[i];
      if (preset.morningPercent == schedule.morningPercent &&
          preset.afternoonPercent == schedule.afternoonPercent &&
          preset.eveningPercent == schedule.eveningPercent) {
        return i;
      }
    }
    return null;
  }
}
