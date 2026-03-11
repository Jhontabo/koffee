import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/coffee_record.dart';
import '../models/farm.dart';
import '../services/auth_service.dart';
import '../services/firestore_migration_service.dart';
import '../services/user_service.dart';

class RecordsProvider extends ChangeNotifier {
  final CollectionReference _recordsCollection = FirebaseFirestore.instance
      .collection('records');
  final CollectionReference _farmsCollection = FirebaseFirestore.instance
      .collection('farms');

  List<CoffeeRecord> _records = [];
  Map<String, double> _kilogramsByFarm = {};
  List<String> _farmNames = [];
  List<Farm> _farms = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  String _role = 'user';
  StreamSubscription? _authSubscription;

  List<CoffeeRecord> get records => _records;
  Map<String, double> get kilogramsByFarm => _kilogramsByFarm;
  List<String> get farmNames => _farmNames;
  List<Farm> get farms => _farms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  String get role => _role;

  RecordsProvider() {
    _init();
  }

  void _init() {
    _authSubscription = AuthService.instance.authStateChanges.listen((
      user,
    ) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userId = null;
        _role = 'user';
        _records = [];
        _farms = [];
        _farmNames = [];
        _kilogramsByFarm = {};
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    _userId = userId;
    await FirestoreMigrationService.instance.ensureUserMigrated(userId);
    await _loadUserProfile();
    await loadRecords();
    await loadFarms();
  }

  Future<void> _loadUserProfile() async {
    if (_userId == null) return;
    final userProfile = await UserService.instance.getUserProfile(_userId!);
    if (userProfile != null) {
      _role = userProfile.role;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadFarms() async {
    if (_userId == null) return;

    try {
      final snapshot = await _farmsCollection
          .where('userId', isEqualTo: _userId)
          .get();

      _farms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Farm(
          id: null,
          userId: data['userId'] as String? ?? '',
          name: (data['name'] ?? '') as String,
          location: data['location'] as String?,
          hectares: (data['hectares'] as num?)?.toDouble(),
          createdAt:
              DateTime.tryParse((data['createdAt'] ?? '') as String) ??
              DateTime.now(),
          isSynced: true,
          firebaseId: doc.id,
        );
      }).toList();

      _farmNames = _farms.map((farm) => farm.name).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Error loading farms: $e';
      notifyListeners();
    }
  }

  Future<void> addFarm(Farm farm) async {
    if (_userId == null) return;

    try {
      final normalizedName = farm.name.trim().toUpperCase();
      final snapshot = await _farmsCollection
          .where('userId', isEqualTo: _userId)
          .where('name', isEqualTo: normalizedName)
          .get();

      if (snapshot.docs.isNotEmpty) return;

      final farmWithUser = farm.copyWith(userId: _userId, name: normalizedName);
      await _farmsCollection.add(farmWithUser.toFirestore());
      await loadFarms();
    } catch (e) {
      _error = 'Error saving farm: $e';
      notifyListeners();
    }
  }

  Future<void> updateFarm(Farm farm) async {
    if (_userId == null || farm.firebaseId == null) return;

    try {
      await _farmsCollection.doc(farm.firebaseId).update(farm.toFirestore());
      await loadFarms();
    } catch (e) {
      _error = 'Error updating farm: $e';
      notifyListeners();
    }
  }

  Future<void> removeFarm(Farm farm) async {
    if (_userId == null || farm.firebaseId == null) return;

    try {
      await _farmsCollection.doc(farm.firebaseId).delete();
      await loadFarms();
    } catch (e) {
      _error = 'Error deleting farm: $e';
      notifyListeners();
    }
  }

  Farm? getFarmByName(String name) {
    try {
      return _farms.firstWhere(
        (farm) => farm.name.toUpperCase() == name.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_userId == null) {
      _records = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _recordsCollection
          .where('userId', isEqualTo: _userId)
          .get();

      _records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CoffeeRecord(
          id: null,
          userId: data['userId'] as String? ?? '',
          firebaseId: doc.id,
          date:
              DateTime.tryParse(data['date'] as String? ?? '') ??
              DateTime.now(),
          farmName: (data['farmName'] ?? '') as String,
          dryCoffeeKg: (data['dryCoffeeKg'] as num?)?.toDouble() ?? 0,
          redCoffeeKg: (data['redCoffeeKg'] as num?)?.toDouble() ?? 0,
          pricePerKg: (data['pricePerKg'] as num?)?.toDouble() ?? 0,
          total: (data['total'] as num?)?.toDouble() ?? 0,
          isSynced: true,
        );
      }).toList();

      _records.sort((a, b) => b.date.compareTo(a.date));
      _calculateKilogramsByFarm();
    } catch (e) {
      _error = 'Error loading records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecord(CoffeeRecord record) async {
    if (_userId == null) {
      _error = 'User is not authenticated';
      notifyListeners();
      return;
    }

    try {
      final recordWithUser = record.copyWith(userId: _userId);
      await _recordsCollection.add(recordWithUser.toFirestore());
      await loadRecords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRecord(String firebaseId) async {
    try {
      await _recordsCollection.doc(firebaseId).delete();
      await loadRecords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRecord(CoffeeRecord record) async {
    try {
      if (record.firebaseId != null) {
        await _recordsCollection
            .doc(record.firebaseId)
            .update(record.toFirestore());
      }
      await loadRecords();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadRecords();
    await loadFarms();
  }

  void _calculateKilogramsByFarm() {
    _kilogramsByFarm = {};
    for (final record in _records) {
      final totalKg = record.redCoffeeKg + record.dryCoffeeKg;
      _kilogramsByFarm[record.farmName] =
          (_kilogramsByFarm[record.farmName] ?? 0) + totalKg;
    }
  }
}
