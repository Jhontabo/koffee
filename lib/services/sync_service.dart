import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final CollectionReference _registrosCollection =
      FirebaseFirestore.instance.collection('registros');

  SyncService._init();

  void startListening(VoidCallback onConnectivityChanged) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        if (result != ConnectivityResult.none) {
          onConnectivityChanged();
        }
      },
    );
  }

  void stopListening() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncUnsyncedRecords() async {
    if (!await hasInternetConnection()) {
      return;
    }

    final unsyncedRecords =
        await DatabaseHelper.instance.getUnsyncedRegistros();

    for (final registro in unsyncedRecords) {
      try {
        final docRef = await _registrosCollection.add(registro.toFirestore());
        await DatabaseHelper.instance.markAsSynced(registro.id!, docRef.id);
      } catch (e) {
        continue;
      }
    }
  }

  Future<void> syncAllRecords() async {
    if (await hasInternetConnection()) {
      await syncUnsyncedRecords();
    }
  }
}

typedef VoidCallback = void Function();
