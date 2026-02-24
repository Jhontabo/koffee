class Trabajador {
  final int? id;
  final String userId;
  final String nombre;
  final String? telefono;
  final bool isSynced;
  final String? firebaseId;

  Trabajador({
    this.id,
    required this.userId,
    required this.nombre,
    this.telefono,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nombre': nombre,
      'telefono': telefono,
      'isSynced': isSynced ? 1 : 0,
      'firebaseId': firebaseId,
    };
  }

  factory Trabajador.fromMap(Map<String, dynamic> map) {
    return Trabajador(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String?,
      isSynced: map['isSynced'] == 1,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'nombre': nombre,
      'telefono': telefono,
      'isSynced': true,
    };
  }

  Trabajador copyWith({
    int? id,
    String? userId,
    String? nombre,
    String? telefono,
    bool? isSynced,
    String? firebaseId,
  }) {
    return Trabajador(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
