class Finca {
  final int? id;
  final String userId;
  final String nombre;
  final String? ubicacion;
  final double? tamanoHectareas;
  final DateTime fechaCreacion;
  final bool isSynced;
  final String? firebaseId;

  Finca({
    this.id,
    required this.userId,
    required this.nombre,
    this.ubicacion,
    this.tamanoHectareas,
    DateTime? fechaCreacion,
    this.isSynced = false,
    this.firebaseId,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'tamanoHectareas': tamanoHectareas,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory Finca.fromMap(Map<String, dynamic> map) {
    return Finca(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      nombre: map['nombre'] as String,
      ubicacion: map['ubicacion'] as String?,
      tamanoHectareas: (map['tamanoHectareas'] as num?)?.toDouble(),
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      isSynced: map['isSynced'] == 1,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'tamanoHectareas': tamanoHectareas,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'isSynced': true,
    };
  }

  Finca copyWith({
    int? id,
    String? userId,
    String? nombre,
    String? ubicacion,
    double? tamanoHectareas,
    DateTime? fechaCreacion,
    bool? isSynced,
    String? firebaseId,
  }) {
    return Finca(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      tamanoHectareas: tamanoHectareas ?? this.tamanoHectareas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
