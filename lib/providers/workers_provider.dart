import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/worker.dart';
import '../models/worker_record.dart';
import '../services/auth_service.dart';
import '../services/firestore_migration_service.dart';

class WorkersProvider extends ChangeNotifier {
  final CollectionReference _workersCollection = FirebaseFirestore.instance
      .collection('workers');
  final CollectionReference _workerRecordsCollection = FirebaseFirestore
      .instance
      .collection('worker_records');

  List<Worker> _workers = [];
  List<WorkerRecord> _records = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription? _authSubscription;

  List<Worker> get workers => _workers;
  List<WorkerRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  bool get hasUser => _userId != null;

  WorkersProvider() {
    _init();
  }

  void _init() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null) {
      _loadUserData(currentUser.uid);
    }

    _authSubscription = AuthService.instance.authStateChanges.listen((
      user,
    ) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userId = null;
        _workers = [];
        _records = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    _userId = userId;
    notifyListeners();
    await FirestoreMigrationService.instance.ensureUserMigrated(userId);
    await loadWorkers();
    await loadRecords();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadWorkers() async {
    if (_userId == null) return;

    try {
      _error = null;
      final snapshot = await _workersCollection
          .where('userId', isEqualTo: _userId)
          .get();

      _workers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Worker(
          id: null,
          userId: data['userId'] as String? ?? '',
          name: (data['name'] ?? '') as String,
          phone: data['phone'] as String?,
          isSynced: true,
          firebaseId: doc.id,
        );
      }).toList()..sort((a, b) => a.name.compareTo(b.name));

      notifyListeners();
    } catch (e) {
      _error = 'Error loading workers: $e';
      notifyListeners();
    }
  }

  Future<void> addWorker(Worker worker) async {
    if (_userId == null) return;

    try {
      final normalizedName = worker.name.trim().toUpperCase();
      final existing = await _workersCollection
          .where('userId', isEqualTo: _userId)
          .where('name', isEqualTo: normalizedName)
          .get();

      if (existing.docs.isNotEmpty) {
        _error = 'A worker with that name already exists';
        notifyListeners();
        return;
      }

      final newWorker = worker.copyWith(userId: _userId, name: normalizedName);
      await _workersCollection.add(newWorker.toFirestore());
      await loadWorkers();
    } catch (e) {
      _error = 'Error saving worker: $e';
      notifyListeners();
    }
  }

  Future<void> updateWorker(Worker worker) async {
    if (_userId == null || worker.firebaseId == null) return;

    try {
      await _workersCollection
          .doc(worker.firebaseId)
          .update(worker.toFirestore());
      await loadWorkers();
    } catch (e) {
      _error = 'Error updating worker: $e';
      notifyListeners();
    }
  }

  Future<void> deleteWorker(Worker worker) async {
    if (_userId == null || worker.firebaseId == null) return;

    try {
      await _workersCollection.doc(worker.firebaseId).delete();
      await loadWorkers();
    } catch (e) {
      _error = 'Error deleting worker: $e';
      notifyListeners();
    }
  }

  Future<void> loadRecords() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _workerRecordsCollection
          .where('userId', isEqualTo: _userId)
          .get();

      _records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WorkerRecord(
          id: null,
          userId: data['userId'] as String? ?? '',
          workerId: (data['workerId'] ?? '').toString(),
          workerName: (data['workerName'] ?? '') as String,
          date:
              DateTime.tryParse((data['date'] ?? '') as String) ??
              DateTime.now(),
          kilograms: (data['kilograms'] as num?)?.toDouble() ?? 0,
          pricePerKg: (data['pricePerKg'] as num?)?.toDouble() ?? 0,
          total: (data['total'] as num?)?.toDouble() ?? 0,
          farmName: (data['farmName'] ?? '') as String,
          isPaid: data['isPaid'] == true,
          isSynced: true,
          firebaseId: doc.id,
        );
      }).toList()..sort((a, b) => b.date.compareTo(a.date));

      notifyListeners();
    } catch (e) {
      _error = 'Error loading records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(WorkerRecord record) async {
    if (_userId == null) return;

    try {
      final newRecord = record.copyWith(userId: _userId);
      await _workerRecordsCollection.add(newRecord.toFirestore());
      await loadRecords();
    } catch (e) {
      _error = 'Error saving record: $e';
      notifyListeners();
    }
  }

  Future<void> updateRecord(WorkerRecord record) async {
    if (_userId == null || record.firebaseId == null) return;

    try {
      await _workerRecordsCollection
          .doc(record.firebaseId)
          .update(record.toFirestore());
      await loadRecords();
    } catch (e) {
      _error = 'Error updating record: $e';
      notifyListeners();
    }
  }

  Future<void> deleteRecord(WorkerRecord record) async {
    if (_userId == null || record.firebaseId == null) return;

    try {
      await _workerRecordsCollection.doc(record.firebaseId).delete();
      await loadRecords();
    } catch (e) {
      _error = 'Error deleting record: $e';
      notifyListeners();
    }
  }

  Future<void> markAsPaid(WorkerRecord record) async {
    if (_userId == null || record.firebaseId == null) return;

    try {
      await _workerRecordsCollection.doc(record.firebaseId).update({
        'isPaid': true,
      });
      await loadRecords();
    } catch (e) {
      _error = 'Error marking as paid: $e';
      notifyListeners();
    }
  }

  List<WorkerRecord> getWeeklyRecords(DateTime referenceDate) {
    final startOfWeek = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _records.where((record) {
      return record.date.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          record.date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  List<WorkerRecord> getRecordsByWorker(
    String workerName, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _records.where((record) {
      final sameWorker =
          record.workerName.toUpperCase() == workerName.toUpperCase();
      if (startDate == null || endDate == null) {
        return sameWorker;
      }
      return sameWorker &&
          record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalKilogramsByWorker(
    String workerName, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final records = getRecordsByWorker(
      workerName,
      startDate: startDate,
      endDate: endDate,
    );
    return records.fold(0.0, (acc, record) => acc + record.kilograms);
  }

  double getTotalPaymentByWorker(
    String workerName, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final records = getRecordsByWorker(
      workerName,
      startDate: startDate,
      endDate: endDate,
    );
    return records.fold(0.0, (acc, record) => acc + record.total);
  }

  Future<void> refresh() async {
    await loadWorkers();
    await loadRecords();
  }

  Map<String, double> getWeeklyKilogramsByWorker(DateTime referenceDate) {
    final weeklyRecords = getWeeklyRecords(referenceDate);
    final result = <String, double>{};

    for (final record in weeklyRecords) {
      result[record.workerName] =
          (result[record.workerName] ?? 0) + record.kilograms;
    }

    return result;
  }
}
