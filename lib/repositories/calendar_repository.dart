import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_entry.dart';

class CalendarRepository {
  final SharedPreferences _prefs;
  static const _prefix = 'calendar_v1_';

  CalendarRepository(this._prefs);

  String _key(String date) => '$_prefix$date';

  List<CalendarEntry> getEntriesForDate(String date) {
    final raw = _prefs.getString(_key(date));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.plannedStartMinutes.compareTo(b.plannedStartMinutes));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntriesForDate(String date, List<CalendarEntry> entries) async {
    await _prefs.setString(
      _key(date),
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addEntry(CalendarEntry entry) async {
    final entries = getEntriesForDate(entry.date)..add(entry);
    await saveEntriesForDate(entry.date, entries);
  }

  Future<void> updateEntry(CalendarEntry updated) async {
    final entries = getEntriesForDate(updated.date)
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    await saveEntriesForDate(updated.date, entries);
  }

  Future<void> deleteEntry(String date, String id) async {
    final entries = getEntriesForDate(date).where((e) => e.id != id).toList();
    await saveEntriesForDate(date, entries);
  }

  /// Returns all preference keys that belong to the calendar.
  List<String> getAllCalendarKeys() {
    return _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
  }

  /// Full export: all calendar keys as JSON map.
  Map<String, dynamic> exportAll() {
    final result = <String, dynamic>{};
    for (final key in getAllCalendarKeys()) {
      result[key] = _prefs.getString(key);
    }
    return result;
  }
}
