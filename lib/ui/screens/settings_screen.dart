import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/water_settings.dart';
import '../../providers/settings_provider.dart';

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
  final List<TextEditingController> _quickControllers = [];
  MeasurementUnit _unit = MeasurementUnit.milliliters;
  ThemePreference _theme = ThemePreference.system;
  bool _notificationsEnabled = false;
  double _intervalHours = 2;
  bool _countOnlyWater = false;
  bool _initializedFromState = false;

  @override
  void initState() {
    super.initState();
    _applySettingsToControllers(WaterSettings.defaultSettings, notify: false);
  }

  @override
  void dispose() {
    _goalController.dispose();
    for (final c in _quickControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    settingsAsync.whenData((settings) {
      if (!_initializedFromState) {
        _applySettingsToControllers(settings);
        _initializedFromState = true;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: settingsAsync.when(
        data: (_) => _buildForm(context),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
      ),
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
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Дневная цель (мл)',
              hintText: 'Например, 2000',
            ),
          ),
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
            value: _countOnlyWater,
            onChanged: (val) => setState(() => _countOnlyWater = val),
            title: const Text('Считать только воду в прогрессе'),
            subtitle: const Text(
                'Остальные напитки учитываются только в статистике объёма.'),
          ),
          const SizedBox(height: 12),
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
    _countOnlyWater = settings.countOnlyWater;

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
    final goal = int.tryParse(_goalController.text) ?? 2000;
    if (goal < 500 || goal > 7000) {
      final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Непривычная цель'),
              content: const Text(
                  'Рекомендуемый диапазон 500–7000 мл. Всё равно сохранить?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ) ??
          false;
      if (!proceed) return;
    }

    final quickValues = _quickControllers
        .map((c) => int.tryParse(c.text) ?? 0)
        .where((v) => v > 0)
        .toList();

    final settings = WaterSettings(
      dailyGoal: goal > 0 ? goal : 2000,
      quickAddOptions:
          quickValues.isNotEmpty ? quickValues : const [200, 250, 300],
      unit: _unit,
      notificationsEnabled: _notificationsEnabled,
      notificationIntervalHours: _intervalHours.round().clamp(1, 12),
      themePreference: _theme,
      countOnlyWater: _countOnlyWater,
    );

    await ref.read(settingsProvider.notifier).saveSettings(settings);
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
}
