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
      _fincas = await DatabaseHelper.instance.getAllFincas(_userId!);
      _fincasNames = _fincas.map((f) => f.nombre).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando fincas: $e');
    }
  }

  Future<void> addFinca(Finca nuevaFinca) async {
    if (_userId == null) return;

    try {
      final existing = await DatabaseHelper.instance.getFincaByName(
        _userId!,
        nuevaFinca.nombre.toUpperCase(),
      );

      if (existing != null) {
        return;
      }

      final fibra = nuevaFinca.copyWith(
        userId: _userId,
        nombre: nuevaFinca.nombre.toUpperCase(),
      );

      await DatabaseHelper.instance.insertFinca(fibra);
      await SyncService.instance.syncUnsyncedFincas();
      await loadFincas();
    } catch (e) {
      print('Error guardando finca: $e');
    }
  }

  Future<void> updateFinca(Finca fibra) async {
    if (_userId == null) return;

    try {
      await DatabaseHelper.instance.updateFinca(fibra);
      await SyncService.instance.syncUnsyncedFincas();
      await loadFincas();
    } catch (e) {
      print('Error actualizando finca: $e');
    }
  }

  Future<void> removeFinca(Finca fibra) async {
    if (_userId == null || fibra.id == null) return;

    try {
      await DatabaseHelper.instance.deleteFinca(fibra.id!);
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
      _registros = await DatabaseHelper.instance.getAllRegistros(_userId!);
      _registros.sort((a, b) => b.fecha.compareTo(a.fecha));
      _calculateKilosByFinca();
    } catch (e) {
      _error = e.toString();
      print('Error cargando registros: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRegistro(RegistroFinca registro) async {
    if (_userId == null) {
      _error = 'Usuario no autenticado';
      print('Error: Usuario no autenticado');
      notifyListeners();
      return;
    }

    try {
      final registroConUserId = registro.copyWith(userId: _userId);
      await DatabaseHelper.instance.insertRegistro(registroConUserId);
      await SyncService.instance.syncUnsyncedRecords();
      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      print('Error guardando registro: $e');
      notifyListeners();
    }
  }

  Future<void> deleteRegistro(int id) async {
    try {
      await DatabaseHelper.instance.deleteRegistro(id);
      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRegistro(RegistroFinca registro) async {
    try {
      if (registro.id == null) return;
      await DatabaseHelper.instance.updateRegistro(registro);
      await SyncService.instance.syncUnsyncedRecords();
      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> syncRecords() async {
    await SyncService.instance.syncAllRecords();
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
