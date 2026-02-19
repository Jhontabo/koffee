import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_finca.dart';
import '../services/auth_service.dart';

class RegistroProvider extends ChangeNotifier {
  List<RegistroFinca> _registros = [];
  Map<String, double> _kilosByFinca = {};
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription? _authSubscription;

  final CollectionReference _registrosCollection = FirebaseFirestore.instance
      .collection('registros');

  List<RegistroFinca> get registros => _registros;
  Map<String, double> get kilosByFinca => _kilosByFinca;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;

  RegistroProvider() {
    _init();
  }

  void _init() {
    _authSubscription = AuthService.instance.authStateChanges.listen((user) {
      if (user != null) {
        _userId = user.uid;
        loadRegistros();
      } else {
        _userId = null;
        _registros = [];
        _kilosByFinca = {};
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
