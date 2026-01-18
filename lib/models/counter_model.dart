import 'package:cloud_firestore/cloud_firestore.dart';

class Counter {
  final String id;
  final String name;
  final String collectionName; // Sanitized name for Firebase collection
  final bool archived;
  final int displayOrder;
  final DateTime createdAt;

  Counter({
    required this.id,
    required this.name,
    String? collectionName,
    this.archived = false,
    this.displayOrder = 0,
    DateTime? createdAt,
  }) : collectionName = collectionName ?? _sanitizeName(name),
       createdAt = createdAt ?? DateTime.now();

  // Sanitize name for Firebase collection (remove spaces, special chars)
  static String _sanitizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  factory Counter.fromJson(Map<String, dynamic> data) {
    return Counter(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Counter',
      collectionName: data['collectionName'],
      archived: data['archived'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
    );
  }

  factory Counter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Counter';
    return Counter(
      id: doc.id,
      name: name,
      collectionName: data['collectionName'] ?? _sanitizeName(name),
      archived: data['archived'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'collectionName': collectionName,
      'archived': archived,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Counter copyWith({
    String? id,
    String? name,
    String? collectionName,
    bool? archived,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return Counter(
      id: id ?? this.id,
      name: name ?? this.name,
      collectionName: collectionName ?? this.collectionName,
      archived: archived ?? this.archived,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CounterEntry {
  final String id;
  final String counterId;
  final int value;
  final DateTime createdAt;

  CounterEntry({
    required this.id,
    required this.counterId,
    this.value = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CounterEntry.fromJson(Map<String, dynamic> data) {
    return CounterEntry(
      id: data['id'] ?? '',
      counterId: data['counterId'] ?? '',
      value: data['value'] ?? 1,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
    );
  }

  factory CounterEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CounterEntry(
      id: doc.id,
      counterId: data['counterId'] ?? '',
      value: data['value'] ?? 1,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // For new structure where counterId is derived from collection name
  factory CounterEntry.fromFirestoreSimple(DocumentSnapshot doc, String counterId) {
    final data = doc.data() as Map<String, dynamic>;
    return CounterEntry(
      id: doc.id,
      counterId: counterId,
      value: data['value'] ?? 1,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counterId': counterId,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
