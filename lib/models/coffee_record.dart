class CoffeeRecord {
  final int? id;
  final String userId;
  final DateTime date;
  final String farmName;
  final double redCoffeeKg;
  final double dryCoffeeKg;
  final double pricePerKg;
  final double total;
  final bool isSynced;
  final String? firebaseId;

  CoffeeRecord({
    this.id,
    this.userId = '',
    required this.date,
    required this.farmName,
    this.redCoffeeKg = 0,
    this.dryCoffeeKg = 0,
    this.pricePerKg = 0,
    this.total = 0,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'farmName': farmName,
      'redCoffeeKg': redCoffeeKg,
      'dryCoffeeKg': dryCoffeeKg,
      'pricePerKg': pricePerKg,
      'total': total,
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory CoffeeRecord.fromMap(Map<String, dynamic> map) {
    return CoffeeRecord(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      date: DateTime.tryParse((map['date'] ?? '') as String) ?? DateTime.now(),
      farmName: (map['farmName'] ?? '') as String,
      redCoffeeKg: (map['redCoffeeKg'] as num?)?.toDouble() ?? 0,
      dryCoffeeKg: (map['dryCoffeeKg'] as num?)?.toDouble() ?? 0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'farmName': farmName,
      'redCoffeeKg': redCoffeeKg,
      'dryCoffeeKg': dryCoffeeKg,
      'pricePerKg': pricePerKg,
      'total': total,
      'isSynced': true,
    };
  }

  CoffeeRecord copyWith({
    int? id,
    String? userId,
    DateTime? date,
    String? farmName,
    double? redCoffeeKg,
    double? dryCoffeeKg,
    double? pricePerKg,
    double? total,
    bool? isSynced,
    String? firebaseId,
  }) {
    return CoffeeRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      farmName: farmName ?? this.farmName,
      redCoffeeKg: redCoffeeKg ?? this.redCoffeeKg,
      dryCoffeeKg: dryCoffeeKg ?? this.dryCoffeeKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      total: total ?? this.total,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
