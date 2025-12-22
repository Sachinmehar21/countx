import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/counter_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _countersRef => _firestore.collection('counters');
  CollectionReference get _entriesRef => _firestore.collection('counter_entries');

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

  // Add a new counter
  Future<String> addCounter(String name) async {
    final doc = await _countersRef.add({
      'name': name,
      'archived': false,
      'displayOrder': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // Update counter name
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

  // Delete a counter and all its entries
  Future<void> deleteCounter(String counterId) async {
    // Delete all entries for this counter
    final entries = await _entriesRef
        .where('counterId', isEqualTo: counterId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in entries.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_countersRef.doc(counterId));
    await batch.commit();
  }

  // ==================== COUNTER ENTRIES ====================

  // Add a new entry (increment counter)
  Future<void> addEntry(String counterId, {int value = 1}) async {
    await _entriesRef.add({
      'counterId': counterId,
      'value': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove last entry (decrement counter)
  Future<void> removeLastEntry(String counterId) async {
    final lastEntry = await _entriesRef
        .where('counterId', isEqualTo: counterId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    
    if (lastEntry.docs.isNotEmpty) {
      await lastEntry.docs.first.reference.delete();
    }
  }

  // Get count for a specific year
  Future<int> getYearCount(String counterId, int year) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _entriesRef
        .where('counterId', isEqualTo: counterId)
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
  Future<int> getMonthCount(String counterId, int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _entriesRef
        .where('counterId', isEqualTo: counterId)
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
  Stream<int> streamYearCount(String counterId, int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    return _entriesRef
        .where('counterId', isEqualTo: counterId)
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
  Stream<int> streamMonthCount(String counterId, int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    return _entriesRef
        .where('counterId', isEqualTo: counterId)
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
  Stream<List<CounterEntry>> getEntriesForCounter(String counterId) {
    return _entriesRef
        .where('counterId', isEqualTo: counterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CounterEntry.fromFirestore(doc)).toList());
  }

  // Get entries for a specific date range (for heatmap)
  Future<List<CounterEntry>> getEntriesForDateRange(
      String counterId, DateTime start, DateTime end) async {
    final snapshot = await _entriesRef
        .where('counterId', isEqualTo: counterId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) => CounterEntry.fromFirestore(doc)).toList();
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
}
