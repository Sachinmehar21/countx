import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/counter_model.dart';

class LocalStorageService {
  static const String _countersKey = 'counters';
  static const String _entriesKey = 'counter_entries';

  // ==================== COUNTERS ====================

  // Get all active counters (not archived)
  Stream<List<Counter>> getCounters() async* {
    final counters = await _getCountersList();
    yield counters.where((c) => !c.archived).toList();
  }

  Future<List<Counter>> _getCountersList() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_countersKey);
    if (data == null) return [];
    
    final List<dynamic> list = json.decode(data);
    return list.map((e) => Counter.fromJson(e)).toList();
  }

  Future<void> _saveCountersList(List<Counter> counters) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(counters.map((c) => c.toJson()).toList());
    await prefs.setString(_countersKey, data);
  }

  // Get archived counters
  Stream<List<Counter>> getArchivedCounters() async* {
    final counters = await _getCountersList();
    yield counters.where((c) => c.archived).toList();
  }

  // Add a new counter
  Future<String> addCounter(String name) async {
    final counters = await _getCountersList();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final counter = Counter(
      id: id,
      name: name,
      archived: false,
      displayOrder: counters.length,
      createdAt: DateTime.now(),
    );
    counters.add(counter);
    await _saveCountersList(counters);
    return id;
  }

  // Update counter name
  Future<void> updateCounterName(String counterId, String newName) async {
    final counters = await _getCountersList();
    final index = counters.indexWhere((c) => c.id == counterId);
    if (index != -1) {
      counters[index] = counters[index].copyWith(name: newName);
      await _saveCountersList(counters);
    }
  }

  // Archive a counter
  Future<void> archiveCounter(String counterId) async {
    final counters = await _getCountersList();
    final index = counters.indexWhere((c) => c.id == counterId);
    if (index != -1) {
      counters[index] = counters[index].copyWith(archived: true);
      await _saveCountersList(counters);
    }
  }

  // Unarchive a counter
  Future<void> unarchiveCounter(String counterId) async {
    final counters = await _getCountersList();
    final index = counters.indexWhere((c) => c.id == counterId);
    if (index != -1) {
      counters[index] = counters[index].copyWith(archived: false);
      await _saveCountersList(counters);
    }
  }

  // Delete a counter and all its entries
  Future<void> deleteCounter(String counterId) async {
    final counters = await _getCountersList();
    counters.removeWhere((c) => c.id == counterId);
    await _saveCountersList(counters);
    
    // Also delete entries
    final entries = await _getEntriesList();
    entries.removeWhere((e) => e.counterId == counterId);
    await _saveEntriesList(entries);
  }

  // ==================== COUNTER ENTRIES ====================

  Future<List<CounterEntry>> _getEntriesList() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_entriesKey);
    if (data == null) return [];
    
    final List<dynamic> list = json.decode(data);
    return list.map((e) => CounterEntry.fromJson(e)).toList();
  }

  Future<void> _saveEntriesList(List<CounterEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, data);
  }

  // Add a new entry (increment counter)
  Future<void> addEntry(String counterId, {int value = 1}) async {
    final entries = await _getEntriesList();
    final entry = CounterEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      counterId: counterId,
      value: value,
      createdAt: DateTime.now(),
    );
    entries.add(entry);
    await _saveEntriesList(entries);
  }

  // Remove last entry (decrement counter)
  Future<void> removeLastEntry(String counterId) async {
    final entries = await _getEntriesList();
    // Find last entry for this counter
    for (int i = entries.length - 1; i >= 0; i--) {
      if (entries[i].counterId == counterId) {
        entries.removeAt(i);
        break;
      }
    }
    await _saveEntriesList(entries);
  }

  // Get count for a specific year
  Future<int> getYearCount(String counterId, int year) async {
    final entries = await _getEntriesList();
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    int total = 0;
    for (var entry in entries) {
      if (entry.counterId == counterId &&
          entry.createdAt.isAfter(startOfYear.subtract(const Duration(seconds: 1))) &&
          entry.createdAt.isBefore(endOfYear)) {
        total += entry.value;
      }
    }
    return total;
  }

  // Get count for a specific month
  Future<int> getMonthCount(String counterId, int year, int month) async {
    final entries = await _getEntriesList();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    int total = 0;
    for (var entry in entries) {
      if (entry.counterId == counterId &&
          entry.createdAt.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          entry.createdAt.isBefore(endOfMonth)) {
        total += entry.value;
      }
    }
    return total;
  }

  // Stream for year count (real-time updates)
  Stream<int> streamYearCount(String counterId, int year) async* {
    yield await getYearCount(counterId, year);
  }

  // Stream for month count (real-time updates)
  Stream<int> streamMonthCount(String counterId, int year, int month) async* {
    yield await getMonthCount(counterId, year, month);
  }

  // Get all entries for a counter (for stats/heatmap)
  Stream<List<CounterEntry>> getEntriesForCounter(String counterId) async* {
    final entries = await _getEntriesList();
    yield entries.where((e) => e.counterId == counterId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get entries for a specific date range (for heatmap)
  Future<List<CounterEntry>> getEntriesForDateRange(
      String counterId, DateTime start, DateTime end) async {
    final entries = await _getEntriesList();
    return entries
        .where((e) =>
            e.counterId == counterId &&
            e.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            e.createdAt.isBefore(end))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // Get daily counts for a month (for heatmap)
  Future<Map<int, int>> getDailyCountsForMonth(
      String counterId, int year, int month) async {
    final entries = await getEntriesForDateRange(
      counterId,
      DateTime(year, month, 1),
      DateTime(year, month + 1, 1),
    );

    Map<int, int> dailyCounts = {};
    for (var entry in entries) {
      final day = entry.createdAt.day;
      dailyCounts[day] = (dailyCounts[day] ?? 0) + entry.value;
    }
    return dailyCounts;
  }

  // Get monthly counts for a year (for bar graph)
  Future<Map<int, int>> getMonthlyCountsForYear(String counterId, int year) async {
    Map<int, int> monthlyCounts = {};
    for (int month = 1; month <= 12; month++) {
      monthlyCounts[month] = await getMonthCount(counterId, year, month);
    }
    return monthlyCounts;
  }

  // Get daily counts for entire year (for heatmap)
  Future<Map<DateTime, int>> getDailyCountsForYear(String counterId, int year) async {
    final entries = await getEntriesForDateRange(
      counterId,
      DateTime(year, 1, 1),
      DateTime(year + 1, 1, 1),
    );

    Map<DateTime, int> dailyCounts = {};
    for (var entry in entries) {
      final date = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      dailyCounts[date] = (dailyCounts[date] ?? 0) + entry.value;
    }
    return dailyCounts;
  }
}
