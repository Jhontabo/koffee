import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_finca.dart';
import '../models/finca.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final CollectionReference _registrosCollection = FirebaseFirestore.instance
      .collection('registros');
  final CollectionReference _fincasCollection = FirebaseFirestore.instance
      .collection('fincas');

  SyncService._init();

  void startListening(VoidCallback onConnectivityChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      if (result.isNotEmpty && result.first != ConnectivityResult.none) {
        onConnectivityChanged();
      }
    });
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && result.first != ConnectivityResult.none;
  }

  Future<void> syncUnsyncedRecords() async {
    if (!await hasInternetConnection()) {
      return;
    }

    final unsyncedRecords = await DatabaseHelper.instance
        .getUnsyncedRegistros();

    for (final registro in unsyncedRecords) {
      try {
        final docRef = await _registrosCollection.add(registro.toFirestore());
        await DatabaseHelper.instance.markAsSynced(registro.id!, docRef.id);
      } catch (e) {
        print('Error syncing record ${registro.id} to Firebase: $e');
        continue;
      }
    }
  }

  Future<void> syncFromFirebase() async {
    if (!await hasInternetConnection()) {
      return;
    }

    try {
      final snapshot = await _registrosCollection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Adapt Firestore data to local model
        // Firestore stores bool for isSynced, but local expects int 1/0?
        // Actually RegistroFinca.fromMap expects map['isSynced'] == 1.
        // But regardless, we are creating a model to pass to upsert.
        // UPSERT manages the isSynced flag locally.

        final registro = RegistroFinca(
          fecha: DateTime.parse(data['fecha'] as String),
          finca: data['finca'] as String,
          kilosRojo: (data['kilosRojo'] as num?)?.toDouble() ?? 0.0,
          kilosSeco: (data['kilosSeco'] as num?)?.toDouble() ?? 0.0,
          valorUnitario: (data['valorUnitario'] as num?)?.toDouble() ?? 0.0,
          total: (data['total'] as num?)?.toDouble() ?? 0.0,
          // We don't care about isSynced/id here as upsert handles it
          firebaseId: doc.id,
        );

        await DatabaseHelper.instance.upsertRegistro(registro);
      }
    } catch (e) {
      print('Error syncing from Firebase: $e');
    }
  }

  Future<void> syncAllRecords() async {
    if (await hasInternetConnection()) {
      await syncUnsyncedRecords();
      await syncFromFirebase();
      await syncUnsyncedFincas();
      await syncFincasFromFirebase();
    }
  }

  Future<void> syncUnsyncedFincas() async {
    if (!await hasInternetConnection()) {
      return;
    }

    final unsyncedFincas = await DatabaseHelper.instance.getUnsyncedFincas();

    for (final fibra in unsyncedFincas) {
      try {
        final docRef = await _fincasCollection.add(fibra.toFirestore());
        await DatabaseHelper.instance.markFincaAsSynced(fibra.id!, docRef.id);
      } catch (e) {
        print('Error syncing fibra ${fibra.id} to Firebase: $e');
        continue;
      }
    }
  }

  Future<void> syncFincasFromFirebase() async {
    if (!await hasInternetConnection()) {
      return;
    }

    try {
      final snapshot = await _fincasCollection.get();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final fibra = Finca(
          userId: data['userId'] as String? ?? '',
          nombre: data['nombre'] as String? ?? '',
          ubicacion: data['ubicacion'] as String?,
          tamanoHectareas: (data['tamanoHectareas'] as num?)?.toDouble(),
          fechaCreacion: data['fechaCreacion'] != null
              ? DateTime.parse(data['fechaCreacion'] as String)
              : DateTime.now(),
          firebaseId: doc.id,
        );

        await DatabaseHelper.instance.upsertFinca(fibra);
      }
    } catch (e) {
      print('Error syncing fincas from Firebase: $e');
    }
  }
}

typedef VoidCallback = void Function();
