import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_finca.dart';
import '../models/finca.dart';
import '../services/auth_service.dart';
import '../services/usuario_service.dart';

class RegistroProvider extends ChangeNotifier {
  List<RegistroFinca> _registros = [];
  Map<String, double> _kilosByFinca = {};
  List<String> _fincasNames = [];
  List<Finca> _fincas = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  String _rol = 'usuario';
  StreamSubscription? _authSubscription;

  final CollectionReference _registrosCollection = FirebaseFirestore.instance
      .collection('registros');
  final CollectionReference _fincasCollection = FirebaseFirestore.instance
      .collection('fincas');

  List<RegistroFinca> get registros => _registros;
  Map<String, double> get kilosByFinca => _kilosByFinca;
  List<String> get fincas => _fincasNames;
  List<Finca> get fincasList => _fincas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  String get rol => _rol;

  RegistroProvider() {
    _init();
  }

  void _init() {
    _authSubscription = AuthService.instance.authStateChanges.listen((
      user,
    ) async {
      if (user != null) {
        _userId = user.uid;
        await _cargarUsuario();
        await loadRegistros();
        await loadFincas();
      } else {
        _userId = null;
        _rol = 'usuario';
        _registros = [];
        _fincas = [];
        _fincasNames = [];
        _kilosByFinca = {};
        notifyListeners();
      }
    });
  }

  Future<void> _cargarUsuario() async {
    if (_userId == null) return;
    final usuario = await UsuarioService.instance.getUsuario(_userId!);
    if (usuario != null) {
      _rol = usuario.rol;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadFincas() async {
    if (_userId == null) return;

    try {
      final snapshot = await _fincasCollection
          .where('userId', isEqualTo: _userId)
          .get();

      _fincas = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Finca(
          id: null,
          userId: data['userId'] as String? ?? '',
          nombre: data['nombre'] as String? ?? '',
          ubicacion: data['ubicacion'] as String?,
          tamanoHectareas: (data['tamanoHectareas'] as num?)?.toDouble(),
          fechaCreacion: data['fechaCreacion'] != null
              ? DateTime.parse(data['fechaCreacion'] as String)
              : DateTime.now(),
          isSynced: true,
          firebaseId: doc.id,
        );
      }).toList();

      _fincasNames = _fincas.map((f) => f.nombre).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Error cargando fincas: $e';
      notifyListeners();
    }
  }

  Future<void> addFinca(Finca nuevaFinca) async {
    if (_userId == null) return;

    try {
      final snapshot = await _fincasCollection
          .where('userId', isEqualTo: _userId)
          .where('nombre', isEqualTo: nuevaFinca.nombre.toUpperCase())
          .get();

      if (snapshot.docs.isNotEmpty) {
        return;
      }

      final fibra = nuevaFinca.copyWith(
        userId: _userId,
        nombre: nuevaFinca.nombre.toUpperCase(),
      );
      await _fincasCollection.add(fibra.toFirestore());

      await loadFincas();
    } catch (e) {
      _error = 'Error guardando finca: $e';
      notifyListeners();
    }
  }

  Future<void> updateFinca(Finca fibra) async {
    if (_userId == null) return;

    try {
      if (fibra.firebaseId != null) {
        await _fincasCollection
            .doc(fibra.firebaseId)
            .update(fibra.toFirestore());
      }

      await loadFincas();
    } catch (e) {
      _error = 'Error actualizando finca: $e';
      notifyListeners();
    }
  }

  Future<void> removeFinca(Finca fibra) async {
    if (_userId == null) return;

    try {
      if (fibra.firebaseId != null) {
        await _fincasCollection.doc(fibra.firebaseId).delete();
      }

      await loadFincas();
    } catch (e) {
      _error = 'Error eliminando finca: $e';
      notifyListeners();
    }
  }

  Finca? getFincaByName(String nombre) {
    try {
      return _fincas.firstWhere(
        (f) => f.nombre.toUpperCase() == nombre.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRegistros() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_userId == null) {
      _registros = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _registrosCollection
          .where('userId', isEqualTo: _userId)
          .get();

      _registros = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RegistroFinca(
          id: null,
          userId: data['userId'] as String? ?? '',
          firebaseId: doc.id,
          fecha: data['fecha'] != null
              ? DateTime.parse(data['fecha'] as String)
              : DateTime.now(),
          finca: data['finca'] as String? ?? '',
          kilosRojo: (data['kilosRojo'] as num?)?.toDouble() ?? 0.0,
          isSynced: true,
        );
      }).toList();

      _registros.sort((a, b) => b.fecha.compareTo(a.fecha));
      _calculateKilosByFinca();
    } catch (e) {
      _error = 'Error cargando datos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRegistro(RegistroFinca registro) async {
    if (_userId == null) {
      _error = 'Usuario no autenticado';
      notifyListeners();
      return;
    }

    try {
      final registroConUserId = registro.copyWith(userId: _userId);
      await _registrosCollection.add(registroConUserId.toFirestore());

      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRegistro(String firebaseId) async {
    try {
      await _registrosCollection.doc(firebaseId).delete();
      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRegistro(RegistroFinca registro) async {
    try {
      if (registro.firebaseId != null) {
        await _registrosCollection
            .doc(registro.firebaseId)
            .update(registro.toFirestore());
      }

      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> syncRecords() async {
    await loadRegistros();
    await loadFincas();
  }

  void _calculateKilosByFinca() {
    _kilosByFinca = {};
    for (final registro in _registros) {
      final totalKilos = registro.kilosRojo;
      if (_kilosByFinca.containsKey(registro.fibra)) {
        _kilosByFinca[registro.fibra] =
            _kilosByFinca[registro.fibra]! + totalKilos;
      } else {
        _kilosByFinca[registro.fibra] = totalKilos;
      }
    }
  }
}
