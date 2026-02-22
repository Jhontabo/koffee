import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_finca.dart';
import '../models/finca.dart';
import '../services/auth_service.dart';
import '../services/usuario_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

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
  final CollectionReference _registrosRojoCollection = FirebaseFirestore
      .instance
      .collection('registros_rojo');
  final CollectionReference _registrosSecoCollection = FirebaseFirestore
      .instance
      .collection('registros_seco');
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
        await SyncService.instance.syncAllRecords();
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
      // Cargar de Firebase directamente
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

      // Guardar en SQLite como backup
      for (final fibra in _fincas) {
        await DatabaseHelper.instance.upsertFinca(fibra);
      }

      _fincasNames = _fincas.map((f) => f.nombre).toList();
      notifyListeners();
    } catch (e) {
      // Si falla Firebase, cargar de SQLite
      try {
        _fincas = await DatabaseHelper.instance.getAllFincas(_userId!);
        _fincasNames = _fincas.map((f) => f.nombre).toList();
      } catch (e2) {
        print('Error cargando fincas: $e');
      }
      notifyListeners();
    }
  }

  Future<void> addFinca(Finca nuevaFinca) async {
    if (_userId == null) return;

    try {
      // Verificar si ya existe en Firebase
      final snapshot = await _fincasCollection
          .where('userId', isEqualTo: _userId)
          .where('nombre', isEqualTo: nuevaFinca.nombre.toUpperCase())
          .get();

      if (snapshot.docs.isNotEmpty) {
        return;
      }

      // Guardar primero en Firebase
      final fibra = nuevaFinca.copyWith(
        userId: _userId,
        nombre: nuevaFinca.nombre.toUpperCase(),
      );
      final docRef = await _fincasCollection.add(fibra.toFirestore());

      // Guardar en SQLite
      final fibraConId = fibra.copyWith(firebaseId: docRef.id, isSynced: true);
      await DatabaseHelper.instance.insertFinca(fibraConId);

      await loadFincas();
    } catch (e) {
      print('Error guardando finca: $e');
    }
  }

  Future<void> updateFinca(Finca fibra) async {
    if (_userId == null) return;

    try {
      // Actualizar en Firebase
      if (fibra.firebaseId != null) {
        await _fincasCollection
            .doc(fibra.firebaseId)
            .update(fibra.toFirestore());
      }

      // Actualizar en SQLite
      await DatabaseHelper.instance.updateFinca(fibra);

      await loadFincas();
    } catch (e) {
      print('Error actualizando finca: $e');
    }
  }

  Future<void> removeFinca(Finca fibra) async {
    if (_userId == null) return;

    try {
      // Eliminar de Firebase
      if (fibra.firebaseId != null) {
        await _fincasCollection.doc(fibra.firebaseId).delete();
      }

      // Eliminar de SQLite
      if (fibra.id != null) {
        await DatabaseHelper.instance.deleteFinca(fibra.id!);
      }

      await loadFincas();
    } catch (e) {
      print('Error eliminando finca: $e');
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
      // Cargar de Firebase directamente (online-first)
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
          kilosSeco: (data['kilosSeco'] as num?)?.toDouble() ?? 0.0,
          valorUnitario: (data['valorUnitario'] as num?)?.toDouble() ?? 0.0,
          total: (data['total'] as num?)?.toDouble() ?? 0.0,
          isSynced: true,
        );
      }).toList();

      // Guardar en SQLite como backup
      for (final registro in _registros) {
        if (registro.firebaseId != null) {
          await DatabaseHelper.instance.upsertRegistro(registro);
        }
      }

      _registros.sort((a, b) => b.fecha.compareTo(a.fecha));
      _calculateKilosByFinca();
    } catch (e) {
      // Si falla Firebase, intentar cargar de SQLite como backup
      _error = 'Sin conexión: mostrando datos locales';
      try {
        _registros = await DatabaseHelper.instance.getAllRegistros(_userId!);
        _registros.sort((a, b) => b.fecha.compareTo(a.fecha));
        _calculateKilosByFinca();
      } catch (e2) {
        _error = 'Error cargando datos: $e';
      }
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
      // Guardar primero en Firebase
      final registroConUserId = registro.copyWith(userId: _userId);
      final docRef = await _registrosCollection.add(
        registroConUserId.toFirestore(),
      );

      // Guardar en SQLite como backup
      final registroConId = registroConUserId.copyWith(
        firebaseId: docRef.id,
        isSynced: true,
      );
      await DatabaseHelper.instance.insertRegistro(registroConId);

      // Recargar
      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      print('Error guardando registro: $e');
      notifyListeners();
    }
  }

  Future<void> deleteRegistro(String firebaseId, String tipo) async {
    try {
      // Eliminar de la colección correcta según el tipo
      final collection = tipo == 'rojo'
          ? _registrosRojoCollection
          : _registrosSecoCollection;
      await collection.doc(firebaseId).delete();

      // Eliminar de SQLite usando firebaseId
      await DatabaseHelper.instance.deleteRegistro(
        null,
        firebaseId: firebaseId,
      );

      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRegistro(RegistroFinca registro) async {
    try {
      // Actualizar en Firebase
      if (registro.firebaseId != null) {
        await _registrosCollection
            .doc(registro.firebaseId)
            .update(registro.toFirestore());
      }

      // Actualizar en SQLite
      await DatabaseHelper.instance.updateRegistro(registro);

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
      final totalKilos = registro.kilosSeco + registro.kilosRojo;
      if (_kilosByFinca.containsKey(registro.finca)) {
        _kilosByFinca[registro.finca] =
            _kilosByFinca[registro.finca]! + totalKilos;
      } else {
        _kilosByFinca[registro.finca] = totalKilos;
      }
    }
  }
}
