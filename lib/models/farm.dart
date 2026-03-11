class Farm {
  final int? id;
  final String userId;
  final String name;
  final String? location;
  final double? hectares;
  final DateTime createdAt;
  final bool isSynced;
  final String? firebaseId;

  Farm({
    this.id,
    required this.userId,
    required this.name,
    this.location,
    this.hectares,
    DateTime? createdAt,
    this.isSynced = false,
    this.firebaseId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'location': location,
      'hectares': hectares,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      name: (map['name'] ?? '') as String,
      location: map['location'] as String?,
      hectares: (map['hectares'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '') as String) ??
          DateTime.now(),
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'location': location,
      'hectares': hectares,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': true,
    };
  }

  Farm copyWith({
    int? id,
    String? userId,
    String? name,
    String? location,
    double? hectares,
    DateTime? createdAt,
    bool? isSynced,
    String? firebaseId,
  }) {
    return Farm(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      location: location ?? this.location,
      hectares: hectares ?? this.hectares,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
