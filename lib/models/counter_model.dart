class Counter {
  final String id;
  final String name;
  final bool archived;
  final int displayOrder;
  final DateTime createdAt;

  Counter({
    required this.id,
    required this.name,
    this.archived = false,
    this.displayOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Counter.fromJson(Map<String, dynamic> data) {
    return Counter(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Counter',
      archived: data['archived'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'archived': archived,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Counter copyWith({
    String? id,
    String? name,
    bool? archived,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return Counter(
      id: id ?? this.id,
      name: name ?? this.name,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'counterId': counterId,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
