class RegistroFinca {
  final int? id;
  final String userId;
  final DateTime fecha;
  final String finca;
  final double kilosRojo;
  final double kilosSeco;
  final double valorUnitario;
  final double total;
  final bool isSynced;
  final String? firebaseId;

  RegistroFinca({
    this.id,
    this.userId = '',
    required this.fecha,
    required this.finca,
    this.kilosRojo = 0,
    required this.kilosSeco,
    required this.valorUnitario,
    required this.total,
    this.isSynced = false,
    this.firebaseId,
  });

  // Getters para determinar tipo de registro
  bool get isRojo => kilosRojo > 0 && kilosSeco == 0;
  bool get isSeco => kilosSeco > 0 && kilosRojo == 0;
  bool get isMixto => kilosRojo > 0 && kilosSeco > 0;

  // Getter para kilos según tipo
  double get kilos => isRojo ? kilosRojo : kilosSeco;

  // Getter para el tipo como string
  String get tipo => isRojo ? 'rojo' : (isMixto ? 'mixto' : 'seco');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fecha': fecha.toIso8601String(),
      'finca': finca,
      'kilosRojo': kilosRojo,
      'kilosSeco': kilosSeco,
      'valorUnitario': valorUnitario,
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
      finca: map['finca'] as String? ?? '',
      kilosRojo: (map['kilosRojo'] as num?)?.toDouble() ?? 0,
      kilosSeco: (map['kilosSeco'] as num?)?.toDouble() ?? 0,
      valorUnitario: (map['valorUnitario'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      isSynced: map['isSynced'] == 1,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fecha': fecha.toIso8601String(),
      'finca': finca,
      'kilosRojo': kilosRojo,
      'kilosSeco': kilosSeco,
      'valorUnitario': valorUnitario,
      'total': total,
      'isSynced': true,
    };
  }

  RegistroFinca copyWith({
    int? id,
    String? userId,
    DateTime? fecha,
    String? finca,
    double? kilosRojo,
    double? kilosSeco,
    double? valorUnitario,
    double? total,
    bool? isSynced,
    String? firebaseId,
  }) {
    return RegistroFinca(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fecha: fecha ?? this.fecha,
      finca: finca ?? this.finca,
      kilosRojo: kilosRojo ?? this.kilosRojo,
      kilosSeco: kilosSeco ?? this.kilosSeco,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      total: total ?? this.total,
      isSynced: isSynced ?? this.isSynced,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }
}
