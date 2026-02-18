class RegistroFinca {
  final int? id;
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
    required this.fecha,
    required this.finca,
    this.kilosRojo = 0,
    required this.kilosSeco,
    required this.valorUnitario,
    required this.total,
    this.isSynced = false,
    this.firebaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      fecha: DateTime.parse(map['fecha'] as String),
      finca: map['finca'] as String,
      kilosRojo: (map['kilosRojo'] as num?)?.toDouble() ?? 0,
      kilosSeco: (map['kilosSeco'] as num).toDouble(),
      valorUnitario: (map['valorUnitario'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      isSynced: map['isSynced'] == 1,
      firebaseId: map['firebaseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
