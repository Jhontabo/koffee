class RegistroRecolector {
  final int? id;
  final String userId;
  final int trabajadorId;
  final String nombreTrabajador;
  final DateTime fecha;
  final double kilos;
  final double precioKilo;
  final double total;
  final String fibra;
  final bool estaPagado;
  final bool isSynced;
  final String? firebaseId;

  RegistroRecolector({
    this.id,
    required this.userId,
    required this.trabajadorId,
    required this.nombreTrabajador,
    required this.fecha,
    required this.kilos,
    required this.precioKilo,
    required this.total,
    required this.fibra,
    this.estaPagado = false,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'trabajadorId': trabajadorId,
      'nombreTrabajador': nombreTrabajador,
      'fecha': fecha.toIso8601String(),
      'kilos': kilos,
      'precioKilo': precioKilo,
      'total': total,
      'fibra': this.fibra,
      'estaPagado': estaPagado ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory RegistroRecolector.fromMap(Map<String, dynamic> map) {
    return RegistroRecolector(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      trabajadorId: map['trabajadorId'] as int? ?? 0,
      nombreTrabajador: map['nombreTrabajador'] as String? ?? '',
      fecha: map['fecha'] != null
          ? DateTime.parse(map['fecha'] as String)
          : DateTime.now(),
      kilos: (map['kilos'] as num?)?.toDouble() ?? 0,
      precioKilo: (map['precioKilo'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      fibra: map['fibra'] as String? ?? '',
      estaPagado: map['estaPagado'] == 1,
      isSynced: map['isSynced'] == 1,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'trabajadorId': trabajadorId,
      'nombreTrabajador': nombreTrabajador,
      'fecha': fecha.toIso8601String(),
      'kilos': kilos,
      'precioKilo': precioKilo,
      'total': total,
      'fibra': fibra,
      'estaPagado': estaPagado,
      'isSynced': true,
    };
  }

  RegistroRecolector copyWith({
    int? id,
    String? userId,
    int? trabajadorId,
    String? nombreTrabajador,
    DateTime? fecha,
    double? kilos,
    double? precioKilo,
    double? total,
    String? fibra,
    bool? estaPagado,
    bool? isSynced,
    String? firebaseId,
  }) {
    return RegistroRecolector(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      nombreTrabajador: nombreTrabajador ?? this.nombreTrabajador,
      fecha: fecha ?? this.fecha,
      kilos: kilos ?? this.kilos,
      precioKilo: precioKilo ?? this.precioKilo,
      total: total ?? this.total,
      fibra: fibra ?? this.fibra,
      estaPagado: estaPagado ?? this.estaPagado,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
