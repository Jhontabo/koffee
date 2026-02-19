import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_finca.dart';
import '../services/auth_service.dart';
import '../services/usuario_service.dart';

class RegistroProvider extends ChangeNotifier {
  List<RegistroFinca> _registros = [];
  Map<String, double> _kilosByFinca = {};
  List<String> _fincas = [];
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
  List<String> get fincas => _fincas;
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
        loadRegistros();
        loadFincas();
      } else {
        _userId = null;
        _rol = 'usuario';
        _registros = [];
        _fincas = [];
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

      _fincas = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return null;
            return data['nombre'] as String?;
          })
          .whereType<String>()
          .toSet()
          .toList();

      final fincasFromRegistros = _registros
          .map((r) => r.finca)
          .where((f) => f.isNotEmpty && !_fincas.contains(f))
          .toSet()
          .toList();

      for (final nombre in fincasFromRegistros) {
        final existing = await _fincasCollection
            .where('userId', isEqualTo: _userId)
            .where('nombre', isEqualTo: nombre)
            .get();

        if (existing.docs.isEmpty) {
          await _fincasCollection.add({'userId': _userId, 'nombre': nombre});
          _fincas.add(nombre);
        }
      }

      _fincas = _fincas.toSet().toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando fincas: $e');
    }
  }

  Future<void> addFinca(String nombre) async {
    if (_userId == null || nombre.trim().isEmpty) return;

    try {
      final trimmed = nombre.trim().toUpperCase();

      final existing = await _fincasCollection
          .where('userId', isEqualTo: _userId)
          .where('nombre', isEqualTo: trimmed)
          .get();

      if (existing.docs.isNotEmpty) {
        if (!_fincas.contains(trimmed)) {
          _fincas.add(trimmed);
          notifyListeners();
        }
        return;
      }

      await _fincasCollection.add({'userId': _userId, 'nombre': trimmed});

      _fincas.add(trimmed);
      notifyListeners();
    } catch (e) {
      print('Error guardando finca: $e');
    }
  }

  Future<void> removeFinca(String nombre) async {
    if (_userId == null) return;

    try {
      final snapshot = await _fincasCollection
          .where('userId', isEqualTo: _userId)
          .where('nombre', isEqualTo: nombre)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _fincas.remove(nombre);
      notifyListeners();
    } catch (e) {
      print('Error eliminando finca: $e');
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
          .orderBy('fecha', descending: true)
          .get();

      _registros = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RegistroFinca(
          id: null,
          userId: data['userId'] as String? ?? '',
          firebaseId: doc.id,
          fecha: DateTime.parse(data['fecha'] as String),
          finca: data['finca'] as String,
          kilosRojo: (data['kilosRojo'] as num?)?.toDouble() ?? 0.0,
          kilosSeco: (data['kilosSeco'] as num?)?.toDouble() ?? 0.0,
          valorUnitario: (data['valorUnitario'] as num?)?.toDouble() ?? 0.0,
          total: (data['total'] as num?)?.toDouble() ?? 0.0,
          isSynced: true,
        );
      }).toList();

      _calculateKilosByFinca();
    } catch (e) {
      _error = e.toString();
      print('Error cargando de Firebase: $e');
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
      print('Error guardando en Firebase: $e');
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

  Future<void> syncRecords() async {
    // En modo online-first, sync es simplemente recargar
    await loadRegistros();
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
