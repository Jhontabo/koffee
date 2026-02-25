import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trabajador.dart';
import '../models/registro_recolector.dart';
import '../services/auth_service.dart';

class JornalerosProvider extends ChangeNotifier {
  List<Trabajador> _trabajadores = [];
  List<RegistroRecolector> _registros = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription? _authSubscription;

  final CollectionReference _trabajadoresCollection = FirebaseFirestore.instance
      .collection('trabajadores');
  final CollectionReference _registrosRecolectorCollection = FirebaseFirestore
      .instance
      .collection('registros_recolector');

  List<Trabajador> get trabajadores => _trabajadores;
  List<RegistroRecolector> get registros => _registros;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  bool get hasUser => _userId != null;

  JornalerosProvider() {
    _init();
  }

  void _init() {
    _authSubscription = AuthService.instance.authStateChanges.listen((
      user,
    ) async {
      if (user != null) {
        _userId = user.uid;
        await loadTrabajadores();
        await loadRegistros();
      } else {
        _userId = null;
        _trabajadores = [];
        _registros = [];
        notifyListeners();
      }
    });

    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) {
      _userId = currentUser.uid;
      loadTrabajadores();
      loadRegistros();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadTrabajadores() async {
    if (_userId == null) return;

    try {
      final snapshot = await _trabajadoresCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('nombre', descending: false)
          .get();

      _trabajadores = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Trabajador(
          id: null,
          userId: data['userId'] as String? ?? '',
          nombre: data['nombre'] as String? ?? '',
          telefono: data['telefono'] as String?,
          isSynced: true,
          firebaseId: doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      _error = 'Error cargando trabajadores: $e';
      notifyListeners();
    }
  }

  Future<void> addTrabajador(Trabajador trabajador) async {
    if (_userId == null) return;

    try {
      final existingSnapshot = await _trabajadoresCollection
          .where('userId', isEqualTo: _userId)
          .where('nombre', isEqualTo: trabajador.nombre.toUpperCase())
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        _error = 'Ya existe un trabajador con ese nombre';
        notifyListeners();
        return;
      }

      final nuevoTrabajador = trabajador.copyWith(
        userId: _userId,
        nombre: trabajador.nombre.toUpperCase(),
      );
      await _trabajadoresCollection.add(nuevoTrabajador.toFirestore());

      await loadTrabajadores();
    } catch (e) {
      _error = 'Error guardando trabajador: $e';
      notifyListeners();
    }
  }

  Future<void> updateTrabajador(Trabajador trabajador) async {
    if (_userId == null || trabajador.firebaseId == null) return;

    try {
      await _trabajadoresCollection
          .doc(trabajador.firebaseId)
          .update(trabajador.toFirestore());

      await loadTrabajadores();
    } catch (e) {
      _error = 'Error actualizando trabajador: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTrabajador(Trabajador trabajador) async {
    if (_userId == null || trabajador.firebaseId == null) return;

    try {
      await _trabajadoresCollection.doc(trabajador.firebaseId).delete();
      await loadTrabajadores();
    } catch (e) {
      _error = 'Error eliminando trabajador: $e';
      notifyListeners();
    }
  }

  Future<void> loadRegistros() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _registrosRecolectorCollection
          .where('userId', isEqualTo: _userId)
          .orderBy('fecha', descending: true)
          .get();

      _registros = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RegistroRecolector(
          id: null,
          userId: data['userId'] as String? ?? '',
          trabajadorId: data['trabajadorId'] as int? ?? 0,
          nombreTrabajador: data['nombreTrabajador'] as String? ?? '',
          fecha: data['fecha'] != null
              ? DateTime.parse(data['fecha'] as String)
              : DateTime.now(),
          kilos: (data['kilos'] as num?)?.toDouble() ?? 0,
          precioKilo: (data['precioKilo'] as num?)?.toDouble() ?? 0,
          total: (data['total'] as num?)?.toDouble() ?? 0,
          fibra: data['fibra'] as String? ?? '',
          estaPagado: data['estaPagado'] as bool? ?? false,
          isSynced: true,
          firebaseId: doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      _error = 'Error cargando registros: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRegistro(RegistroRecolector registro) async {
    if (_userId == null) return;

    try {
      final nuevoRegistro = registro.copyWith(userId: _userId);
      await _registrosRecolectorCollection.add(nuevoRegistro.toFirestore());

      await loadRegistros();
    } catch (e) {
      _error = 'Error guardando registro: $e';
      notifyListeners();
    }
  }

  Future<void> updateRegistro(RegistroRecolector registro) async {
    if (_userId == null || registro.firebaseId == null) return;

    try {
      await _registrosRecolectorCollection
          .doc(registro.firebaseId)
          .update(registro.toFirestore());

      await loadRegistros();
    } catch (e) {
      _error = 'Error actualizando registro: $e';
      notifyListeners();
    }
  }

  Future<void> deleteRegistro(RegistroRecolector registro) async {
    if (_userId == null || registro.firebaseId == null) return;

    try {
      await _registrosRecolectorCollection.doc(registro.firebaseId).delete();
      await loadRegistros();
    } catch (e) {
      _error = 'Error eliminando registro: $e';
      notifyListeners();
    }
  }

  Future<void> marcarComoPagado(RegistroRecolector registro) async {
    if (_userId == null || registro.firebaseId == null) return;

    try {
      await _registrosRecolectorCollection.doc(registro.firebaseId).update({
        'estaPagado': true,
      });

      await loadRegistros();
    } catch (e) {
      _error = 'Error marcando como pagado: $e';
      notifyListeners();
    }
  }

  List<RegistroRecolector> getRegistrosSemana(DateTime fechaReferencia) {
    final inicioSemana = fechaReferencia.subtract(
      Duration(days: fechaReferencia.weekday - 1),
    );
    final finSemana = inicioSemana.add(const Duration(days: 6));

    return _registros.where((reg) {
      return reg.fecha.isAfter(
            inicioSemana.subtract(const Duration(days: 1)),
          ) &&
          reg.fecha.isBefore(finSemana.add(const Duration(days: 1)));
    }).toList();
  }

  List<RegistroRecolector> getRegistrosPorTrabajador(
    String nombreTrabajador, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    return _registros.where((reg) {
      final nombreMatch =
          reg.nombreTrabajador.toUpperCase() == nombreTrabajador.toUpperCase();
      if (fechaInicio == null || fechaFin == null) {
        return nombreMatch;
      }
      return nombreMatch &&
          reg.fecha.isAfter(fechaInicio.subtract(const Duration(days: 1))) &&
          reg.fecha.isBefore(fechaFin.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalKilosPorTrabajador(
    String nombreTrabajador, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    final registros = getRegistrosPorTrabajador(
      nombreTrabajador,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    return registros.fold(0.0, (sum, reg) => sum + reg.kilos);
  }

  double getTotalPagoPorTrabajador(
    String nombreTrabajador, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    final registros = getRegistrosPorTrabajador(
      nombreTrabajador,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    return registros.fold(0.0, (sum, reg) => sum + reg.total);
  }

  Map<String, double> getKilosPorTrabajadorSemana(DateTime fechaReferencia) {
    final registrosSemana = getRegistrosSemana(fechaReferencia);
    final Map<String, double> kilosMap = {};

    for (final reg in registrosSemana) {
      if (kilosMap.containsKey(reg.nombreTrabajador)) {
        kilosMap[reg.nombreTrabajador] =
            kilosMap[reg.nombreTrabajador]! + reg.kilos;
      } else {
        kilosMap[reg.nombreTrabajador] = reg.kilos;
      }
    }

    return kilosMap;
  }
}
