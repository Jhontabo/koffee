class Worker {
  final int? id;
  final String userId;
  final String name;
  final String? phone;
  final bool isSynced;
  final String? firebaseId;

  Worker({
    this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      name: (map['name'] ?? '') as String,
      phone: map['phone'] as String?,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'userId': userId, 'name': name, 'phone': phone, 'isSynced': true};
  }

  Worker copyWith({
    int? id,
    String? userId,
    String? name,
    String? phone,
    bool? isSynced,
    String? firebaseId,
  }) {
    return Worker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
