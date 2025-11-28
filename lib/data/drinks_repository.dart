import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_progress.dart';
import '../models/drink_entry.dart';
import '../models/drink_type.dart';
import '../models/water_settings.dart';

class DrinksRepository {
  DrinksRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _settingsKey = 'settings';
  static const _drinkTypesKey = 'drink_types_v1';
  static const _entriesKey = 'drink_entries_v1';
  static const _migrationFlagKey = 'hydration_migrated_v1';
  static const _historyRetentionDays = 30;

  Future<WaterSettings> loadSettings() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) {
      await saveSettings(WaterSettings.defaultSettings);
      return WaterSettings.defaultSettings;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return WaterSettings.fromJson(decoded);
    } catch (_) {
      return WaterSettings.defaultSettings;
    }
  }

  Future<void> saveSettings(WaterSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<List<DrinkType>> loadDrinkTypes() async {
    await _ensureDrinkTypesInitialized();
    final raw = _prefs.getString(_drinkTypesKey);
    if (raw == null) return DrinkType.defaultTypes();
    try {
      final decoded = (jsonDecode(raw) as List)
          .map((e) => DrinkType.fromJson(e as Map<String, dynamic>))
          .toList();
      return decoded;
    } catch (_) {
      return DrinkType.defaultTypes();
    }
  }

  Future<void> saveDrinkTypes(List<DrinkType> types) async {
    await _prefs.setString(
      _drinkTypesKey,
      jsonEncode(types.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> upsertDrinkType(DrinkType type) async {
    final types = await loadDrinkTypes();
    final idx = types.indexWhere((t) => t.id == type.id);
    if (idx == -1) {
      types.add(type);
    } else {
      types[idx] = type;
    }
    await saveDrinkTypes(types);
  }

  Future<void> deleteDrinkType(
    String id, {
    String fallbackId = DrinkType.waterId,
  }) async {
    final types = await loadDrinkTypes();
    final targetIdx = types.indexWhere((t) => t.id == id);
    if (targetIdx == -1) return;
    if (types[targetIdx].isDefault) {
      // Default types stay forever to prevent losing references.
      return;
    }
    types.removeAt(targetIdx);
    await saveDrinkTypes(types);
    await _reassignEntries(id, fallbackId);
  }

  Future<List<DrinkEntry>> loadEntriesForDay(DateTime day) async {
    final entries = await _loadAllEntries();
    return entries
        .where((e) => DateUtils.isSameDay(e.dateTime, day))
        .toList();
  }

  Future<List<DrinkEntry>> _loadAllEntries() async {
    await _ensureDrinkTypesInitialized();
    await _ensureMigration();
    final raw = _prefs.getString(_entriesKey);
    if (raw == null) return [];
    try {
      return _decodeEntries(raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(DrinkEntry entry) async {
    final entries = await _loadAllEntries();
    entries.add(entry);
    await _saveEntries(_trimEntries(entries));
  }

  Future<void> replaceEntriesForDay(
    DateTime day,
    List<DrinkEntry> dayEntries,
  ) async {
    final entries = await _loadAllEntries();
    entries.removeWhere((e) => DateUtils.isSameDay(e.dateTime, day));
    entries.addAll(dayEntries);
    await _saveEntries(_trimEntries(entries));
  }

  Future<List<DailyProgress>> loadDailySummaries({
    required int days,
    required int target,
    required bool countWaterOnly,
  }) async {
    final entries = await _loadAllEntries();
    final today = DateUtils.dateOnly(DateTime.now());
    final summaries = <DailyProgress>[];
    for (var offset = 0; offset < days; offset++) {
      final date = DateUtils.dateOnly(today.subtract(Duration(days: offset)));
      final dayEntries = entries
          .where((e) => DateUtils.isSameDay(e.dateTime, date))
          .toList();
      final totalVolume =
          dayEntries.fold(0, (sum, e) => sum + e.volumeMl).clamp(0, 1 << 31);
      final effective = dayEntries.fold<int>(0, (sum, e) {
        if (countWaterOnly && e.drinkTypeId != DrinkType.waterId) {
          return sum;
        }
        return sum + e.effectiveHydrationMl;
      }).clamp(0, 1 << 31);
      summaries.add(
        DailyProgress(
          date: date,
          target: target,
          effectiveMl: effective,
          totalVolumeMl: totalVolume,
        ),
      );
    }
    return summaries;
  }

  Future<Map<String, DrinkTotals>> totalsByDrinkForDay(DateTime day) async {
    final entries = await loadEntriesForDay(day);
    final map = <String, DrinkTotals>{};
    for (final entry in entries) {
      final current = map[entry.drinkTypeId];
      if (current == null) {
        map[entry.drinkTypeId] = DrinkTotals(
          volumeMl: entry.volumeMl,
          effectiveMl: entry.effectiveHydrationMl,
        );
      } else {
        map[entry.drinkTypeId] = DrinkTotals(
          volumeMl: current.volumeMl + entry.volumeMl,
          effectiveMl: current.effectiveMl + entry.effectiveHydrationMl,
        );
      }
    }
    return map;
  }

  Future<void> _saveEntries(List<DrinkEntry> entries) async {
    await _prefs.setString(
      _entriesKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  List<DrinkEntry> _trimEntries(List<DrinkEntry> entries) {
    final cutoff = DateTime.now().subtract(
      const Duration(days: _historyRetentionDays),
    );
    return entries
        .where((e) => e.dateTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _ensureDrinkTypesInitialized() async {
    final raw = _prefs.getString(_drinkTypesKey);
    if (raw == null) {
      await saveDrinkTypes(DrinkType.defaultTypes());
      return;
    }
    try {
      final stored = _decodeTypes(raw);
      final defaults = DrinkType.defaultTypes();
      final ids = stored.map((e) => e.id).toSet();
      var changed = false;
      for (final def in defaults) {
        if (!ids.contains(def.id)) {
          stored.add(def);
          changed = true;
        }
      }
      if (changed) {
        await saveDrinkTypes(stored);
      }
    } catch (_) {
      await saveDrinkTypes(DrinkType.defaultTypes());
    }
  }

  // Migrates legacy single-value progress into hydrated entries treated as water
  // with hydrationFactor = 1.0 for backwards compatibility.
  Future<void> _ensureMigration() async {
    final migrated = _prefs.getBool(_migrationFlagKey) ?? false;
    if (migrated) return;

    final List<DrinkEntry> entries = [];
    final todayRaw = _prefs.getString('today_progress');
    if (todayRaw != null) {
      try {
        final legacy =
            DailyProgress.fromJson(jsonDecode(todayRaw) as Map<String, dynamic>);
        if (legacy.effectiveMl > 0) {
          entries.add(
            DrinkEntry(
              id: 'legacy-${legacy.date.toIso8601String()}',
              drinkTypeId: DrinkType.waterId,
              volumeMl: legacy.totalVolumeMl,
              dateTime:
                  DateTime(legacy.date.year, legacy.date.month, legacy.date.day),
              effectiveHydrationMl: legacy.effectiveMl,
            ),
          );
        }
      } catch (_) {
        // ignore invalid legacy data.
      }
      await _prefs.remove('today_progress');
    }

    final historyRaw = _prefs.getString('history');
    if (historyRaw != null) {
      try {
        final decoded = jsonDecode(historyRaw) as List<dynamic>;
        for (final item in decoded) {
          final legacy = DailyProgress.fromJson(item as Map<String, dynamic>);
          if (legacy.effectiveMl <= 0) continue;
          entries.add(
            DrinkEntry(
              id: 'legacy-${legacy.date.toIso8601String()}',
              drinkTypeId: DrinkType.waterId,
              volumeMl: legacy.totalVolumeMl,
              dateTime:
                  DateTime(legacy.date.year, legacy.date.month, legacy.date.day),
              effectiveHydrationMl: legacy.effectiveMl,
            ),
          );
        }
      } catch (_) {
        // ignore invalid data.
      }
      await _prefs.remove('history');
    }

    if (entries.isNotEmpty) {
      final existingRaw = _prefs.getString(_entriesKey);
      final existing =
          existingRaw == null ? <DrinkEntry>[] : _decodeEntries(existingRaw);
      existing.addAll(entries);
      await _saveEntries(_trimEntries(existing));
    }

    await _prefs.setBool(_migrationFlagKey, true);
  }

  Future<void> _reassignEntries(String fromId, String toId) async {
    final entries = await _loadAllEntries();
    final updated = entries
        .map(
          (e) => e.drinkTypeId == fromId
              ? e.copyWith(drinkTypeId: toId)
              : e,
        )
        .toList();
    await _saveEntries(updated);
  }

  List<DrinkType> _decodeTypes(String raw) {
    return (jsonDecode(raw) as List)
        .map((e) => DrinkType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<DrinkEntry> _decodeEntries(String raw) {
    return (jsonDecode(raw) as List)
        .map((e) => DrinkEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class DrinkTotals {
  const DrinkTotals({
    required this.volumeMl,
    required this.effectiveMl,
  });

  final int volumeMl;
  final int effectiveMl;
}
