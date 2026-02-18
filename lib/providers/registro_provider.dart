import 'package:flutter/foundation.dart';
import '../models/registro_finca.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class RegistroProvider extends ChangeNotifier {
  List<RegistroFinca> _registros = [];
  Map<String, double> _kilosByFinca = {};
  bool _isLoading = false;
  String? _error;

  List<RegistroFinca> get registros => _registros;
  Map<String, double> get kilosByFinca => _kilosByFinca;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RegistroProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadRegistros();
    SyncService.instance.startListening(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    syncRecords();
  }

  Future<void> loadRegistros() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _registros = await DatabaseHelper.instance.getAllRegistros();
      _kilosByFinca = await DatabaseHelper.instance.getKilosByFinca();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRegistro(RegistroFinca registro) async {
    try {
      final id = await DatabaseHelper.instance.insertRegistro(registro);
      final newRegistro = registro.copyWith(id: id);
      _registros.insert(0, newRegistro);
      _updateKilosByFinca(newRegistro);
      notifyListeners();

      await syncRecords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRegistro(int id) async {
    try {
      await DatabaseHelper.instance.deleteRegistro(id);
      _registros.removeWhere((r) => r.id == id);
      _kilosByFinca = await DatabaseHelper.instance.getKilosByFinca();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> syncRecords() async {
    try {
      await SyncService.instance.syncUnsyncedRecords();
      await loadRegistros();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _updateKilosByFinca(RegistroFinca registro) {
    final totalKilos = registro.kilosSeco + registro.kilosRojo;
    if (_kilosByFinca.containsKey(registro.finca)) {
      _kilosByFinca[registro.finca] =
          _kilosByFinca[registro.finca]! + totalKilos;
    } else {
      _kilosByFinca[registro.finca] = totalKilos;
    }
  }

  @override
  void dispose() {
    SyncService.instance.stopListening();
    super.dispose();
  }
}
