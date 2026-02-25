class RegistroFinca {
  final int? id;
  final String userId;
  final DateTime fecha;
  final String fibra;
  final double kilosRojo;
  final double kilosSeco;
  final double precioKilo;
  final double total;
  final bool isSynced;
  final String? firebaseId;

  RegistroFinca({
    this.id,
    this.userId = '',
    required this.fecha,
    required this.fibra,
    this.kilosRojo = 0,
    this.kilosSeco = 0,
    this.precioKilo = 0,
    this.total = 0,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fecha': fecha.toIso8601String(),
      'fibra': fibra,
      'kilosRojo': kilosRojo,
      'kilosSeco': kilosSeco,
      'precioKilo': precioKilo,
      'total': total,
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory RegistroFinca.fromMap(Map<String, dynamic> map) {
    return RegistroFinca(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'] as String)
          : DateTime.now(),
      fibra: map['fibra'] as String? ?? '',
      kilosRojo: (map['kilosRojo'] as num?)?.toDouble() ?? 0,
      kilosSeco: (map['kilosSeco'] as num?)?.toDouble() ?? 0,
      precioKilo: (map['precioKilo'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      isSynced: map['isSynced'] == 1,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fecha': fecha.toIso8601String(),
      'fibra': fibra,
      'kilosRojo': kilosRojo,
      'kilosSeco': kilosSeco,
      'precioKilo': precioKilo,
      'total': total,
      'isSynced': true,
    };
  }

  RegistroFinca copyWith({
    int? id,
    String? userId,
    DateTime? fecha,
    String? fibra,
    double? kilosRojo,
    double? kilosSeco,
    double? precioKilo,
    double? total,
    bool? isSynced,
    String? firebaseId,
  }) {
    return RegistroFinca(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fecha: fecha ?? this.fecha,
      fibra: fibra ?? this.fibra,
      kilosRojo: kilosRojo ?? this.kilosRojo,
      kilosSeco: kilosSeco ?? this.kilosSeco,
      precioKilo: precioKilo ?? this.precioKilo,
      total: total ?? this.total,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
