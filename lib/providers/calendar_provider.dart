import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_entry.dart';
import '../repositories/calendar_repository.dart';
import 'block_provider.dart';

final calendarRepositoryProvider = Provider((ref) {
  return CalendarRepository(ref.watch(sharedPreferencesProvider));
});

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  void updateDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

final selectedDateStringProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
});

class CalendarNotifier extends Notifier<List<CalendarEntry>> {
  late final CalendarRepository _repo;
  late String _date;

  @override
  List<CalendarEntry> build() {
    _repo = ref.watch(calendarRepositoryProvider);
    _date = ref.watch(selectedDateStringProvider);
    return _repo.getEntriesForDate(_date);
  }

  void addEntry(CalendarEntry entry) async {
    await _repo.addEntry(entry);
    state = _repo.getEntriesForDate(_date);
  }

  void updateEntry(CalendarEntry entry) async {
    await _repo.updateEntry(entry);
    state = _repo.getEntriesForDate(_date);
  }

  void deleteEntry(String id) async {
    await _repo.deleteEntry(_date, id);
    state = _repo.getEntriesForDate(_date);
  }

  void reload() {
    state = _repo.getEntriesForDate(_date);
  }
}

final calendarProvider = NotifierProvider<CalendarNotifier, List<CalendarEntry>>(() {
  return CalendarNotifier();
});
