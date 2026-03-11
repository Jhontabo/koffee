class WorkerRecord {
  final int? id;
  final String userId;
  final String workerId;
  final String workerName;
  final DateTime date;
  final double kilograms;
  final double pricePerKg;
  final double total;
  final String farmName;
  final bool isPaid;
  final bool isSynced;
  final String? firebaseId;

  WorkerRecord({
    this.id,
    required this.userId,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.kilograms,
    required this.pricePerKg,
    required this.total,
    required this.farmName,
    this.isPaid = false,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workerId': workerId,
      'workerName': workerName,
      'date': date.toIso8601String(),
      'kilograms': kilograms,
      'pricePerKg': pricePerKg,
      'total': total,
      'farmName': farmName,
      'isPaid': isPaid ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory WorkerRecord.fromMap(Map<String, dynamic> map) {
    return WorkerRecord(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      workerId: (map['workerId'] ?? '').toString(),
      workerName: (map['workerName'] ?? '') as String,
      date: DateTime.tryParse((map['date'] ?? '') as String) ?? DateTime.now(),
      kilograms: (map['kilograms'] as num?)?.toDouble() ?? 0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      farmName: (map['farmName'] ?? '') as String,
      isPaid: map['isPaid'] == 1 || map['isPaid'] == true,
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'workerId': workerId,
      'workerName': workerName,
      'date': date.toIso8601String(),
      'kilograms': kilograms,
      'pricePerKg': pricePerKg,
      'total': total,
      'farmName': farmName,
      'isPaid': isPaid,
      'isSynced': true,
    };
  }

  WorkerRecord copyWith({
    int? id,
    String? userId,
    String? workerId,
    String? workerName,
    DateTime? date,
    double? kilograms,
    double? pricePerKg,
    double? total,
    String? farmName,
    bool? isPaid,
    bool? isSynced,
    String? firebaseId,
  }) {
    return WorkerRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      date: date ?? this.date,
      kilograms: kilograms ?? this.kilograms,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      total: total ?? this.total,
      farmName: farmName ?? this.farmName,
      isPaid: isPaid ?? this.isPaid,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
