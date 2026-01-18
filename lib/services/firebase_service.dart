import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/counter_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _countersRef => _firestore.collection('counters');
  
  // Get entries collection for a specific counter (using counter name)
  CollectionReference _getEntriesRefByName(String collectionName) {
    return _firestore.collection(collectionName);
  }

  // Helper to sanitize name for collection
  String _sanitizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // ==================== COUNTERS ====================

  // Get all active counters (not archived)
  Stream<List<Counter>> getCounters() {
    print('[Firebase] getCounters() called');
    return _countersRef
        .where('archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          print('[Firebase] Got snapshot with ${snapshot.docs.length} counters');
          return snapshot.docs.map((doc) => Counter.fromFirestore(doc)).toList();
        })
        .handleError((error) {
          print('[Firebase Error] getCounters failed: $error');
        });
  }

  // Get archived counters
  Stream<List<Counter>> getArchivedCounters() {
    return _countersRef
        .where('archived', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Counter.fromFirestore(doc)).toList());
  }

  // Add a new counter (creates a new collection for its entries)
  Future<String> addCounter(String name) async {
    final collectionName = _sanitizeName(name);
    final doc = await _countersRef.add({
      'name': name,
      'collectionName': collectionName,
      'archived': false,
      'displayOrder': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('[Firebase] Created new counter: ${doc.id}');
    print('[Firebase] Entries will be stored in collection: $collectionName');
    return doc.id;
  }

  // Update counter name (note: collection name stays same to preserve data)
  Future<void> updateCounterName(String counterId, String newName) async {
    await _countersRef.doc(counterId).update({'name': newName});
  }

  // Archive a counter
  Future<void> archiveCounter(String counterId) async {
    await _countersRef.doc(counterId).update({'archived': true});
  }

  // Unarchive a counter
  Future<void> unarchiveCounter(String counterId) async {
    await _countersRef.doc(counterId).update({'archived': false});
  }

  // Delete a counter and all its entries (deletes the entire collection)
  Future<void> deleteCounter(String counterId, String collectionName) async {
    // Delete all entries in the counter's own collection
    final entriesRef = _getEntriesRefByName(collectionName);
    final entries = await entriesRef.get();
    
    final batch = _firestore.batch();
    for (var doc in entries.docs) {
      batch.delete(doc.reference);
    }
    // Delete the counter document
    batch.delete(_countersRef.doc(counterId));
    await batch.commit();
    print('[Firebase] Deleted counter $counterId and collection $collectionName');
  }

  // ==================== COUNTER ENTRIES ====================

  // Add a new entry (increment counter) - adds to counter's own collection
  Future<void> addEntry(String collectionName, {int value = 1}) async {
    await _getEntriesRefByName(collectionName).add({
      'value': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove last entry (decrement counter)
  Future<void> removeLastEntry(String collectionName) async {
    final lastEntry = await _getEntriesRefByName(collectionName)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    
    if (lastEntry.docs.isNotEmpty) {
      await lastEntry.docs.first.reference.delete();
    }
  }

  // Get count for a specific year
  Future<int> getYearCount(String collectionName, int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _getEntriesRefByName(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfYear))
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['value'] as int? ?? 1;
    }
    return total;
  }

  // Get count for a specific month
  Future<int> getMonthCount(String collectionName, int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _getEntriesRefByName(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['value'] as int? ?? 1;
    }
    return total;
  }

  // Stream for year count (real-time updates)
  Stream<int> streamYearCount(String collectionName, int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    return _getEntriesRefByName(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfYear))
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map<String, dynamic>)['value'] as int? ?? 1;
      }
      return total;
    });
  }

  // Stream for month count (real-time updates)
  Stream<int> streamMonthCount(String collectionName, int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    return _getEntriesRefByName(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map<String, dynamic>)['value'] as int? ?? 1;
      }
      return total;
    });
  }

  // Get all entries for a counter (for stats/heatmap)
  Stream<List<CounterEntry>> getEntriesForCounter(String collectionName) {
    return _getEntriesRefByName(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CounterEntry.fromFirestoreSimple(doc, collectionName)).toList());
  }

  // Get entries for a specific date range (for heatmap)
  Future<List<CounterEntry>> getEntriesForDateRange(
      String collectionName, DateTime start, DateTime end) async {
    final snapshot = await _getEntriesRefByName(collectionName)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) => CounterEntry.fromFirestoreSimple(doc, collectionName)).toList();
  }

  // Get daily counts for a month (for heatmap)
  Future<Map<int, int>> getDailyCountsForMonth(
      String collectionName, int year, int month) async {
    final entries = await getEntriesForDateRange(
      collectionName,
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
  Future<Map<int, int>> getMonthlyCountsForYear(String collectionName, int year) async {
    Map<int, int> monthlyCounts = {};
    for (int month = 1; month <= 12; month++) {
      monthlyCounts[month] = await getMonthCount(collectionName, year, month);
    }
    return monthlyCounts;
  }

  // Get daily counts for entire year (for heatmap)
  Future<Map<DateTime, int>> getDailyCountsForYear(String collectionName, int year) async {
    final entries = await getEntriesForDateRange(
      collectionName,
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
