import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreMigrationService {
  FirestoreMigrationService._();

  static final FirestoreMigrationService instance =
      FirestoreMigrationService._();
  static const int _targetSchemaVersion = 3;
  static final Map<String, Future<void>> _runningMigrations = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _legacyUsers =>
      _firestore.collection('usuarios');

  Future<void> ensureUserMigrated(String userId) {
    return _runningMigrations.putIfAbsent(userId, () async {
      try {
        final userDoc = await _users.doc(userId).get();
        final schemaVersion =
            (userDoc.data()?['schemaVersion'] as num?)?.toInt() ?? 0;
        if (schemaVersion >= _targetSchemaVersion) return;

        if (schemaVersion < 2) {
          await _migrateUserProfile(userId);
          await _migrateFarms(userId);
          await _migrateCoffeeRecords(userId);
          await _migrateWorkers(userId);
          await _migrateWorkerRecords(userId);
        }

        if (schemaVersion < 3) {
          await _archiveAndCleanupLegacyData(userId);
        }

        await _users.doc(userId).set({
          'schemaVersion': _targetSchemaVersion,
          'migrationCompletedAt': DateTime.now().toIso8601String(),
          'legacyCleanupCompletedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error migrating Firestore schema: $e');
        rethrow;
      } finally {
        _runningMigrations.remove(userId);
      }
    });
  }

  Future<void> _migrateUserProfile(String userId) async {
    final legacyDoc = await _legacyUsers.doc(userId).get();
    if (!legacyDoc.exists) {
      await _users.doc(userId).set({
        'schemaVersion': 0,
      }, SetOptions(merge: true));
      return;
    }

    final data = legacyDoc.data() ?? {};
    final normalized = <String, dynamic>{
      'email': _asString(data['email']),
      'displayName': _asString(data['displayName'] ?? data['nombre']),
      'role': _asString(data['role'] ?? data['rol']) ?? 'user',
      'createdAt': _toIsoString(data['createdAt'] ?? data['fechaCreacion']),
      'lastLoginAt': _toIsoString(data['lastLoginAt'] ?? data['ultimoLogin']),
    };
    await _users
        .doc(userId)
        .set(_withoutNulls(normalized), SetOptions(merge: true));
  }

  Future<void> _migrateFarms(String userId) {
    return _migrateCollection(
      legacyCollection: 'fincas',
      targetCollection: 'farms',
      userId: userId,
      normalize: (data) => {
        'userId': _asString(data['userId']) ?? userId,
        'name': _asString(data['name'] ?? data['nombre']) ?? '',
        'location': _asString(data['location'] ?? data['ubicacion']),
        'hectares': _asDouble(data['hectares'] ?? data['tamanoHectareas']),
        'createdAt': _toIsoString(data['createdAt'] ?? data['fechaCreacion']),
        'isSynced': true,
      },
    );
  }

  Future<void> _migrateCoffeeRecords(String userId) {
    return _migrateCollection(
      legacyCollection: 'registros',
      targetCollection: 'records',
      userId: userId,
      normalize: (data) {
        final dryKg = _asDouble(data['dryCoffeeKg'] ?? data['kilosSeco']) ?? 0;
        final pricePerKg =
            _asDouble(data['pricePerKg'] ?? data['precioKilo']) ?? 0;
        return {
          'userId': _asString(data['userId']) ?? userId,
          'date': _toIsoString(data['date'] ?? data['fecha']),
          'farmName':
              _asString(data['farmName'] ?? data['finca'] ?? data['fibra']) ??
              '',
          'dryCoffeeKg': dryKg,
          'redCoffeeKg':
              _asDouble(data['redCoffeeKg'] ?? data['kilosRojo']) ?? 0,
          'pricePerKg': pricePerKg,
          'total': _asDouble(data['total']) ?? (dryKg * pricePerKg),
          'isSynced': true,
        };
      },
    );
  }

  Future<void> _migrateWorkers(String userId) {
    return _migrateCollection(
      legacyCollection: 'trabajadores',
      targetCollection: 'workers',
      userId: userId,
      normalize: (data) => {
        'userId': _asString(data['userId']) ?? userId,
        'name': _asString(data['name'] ?? data['nombre']) ?? '',
        'phone': _asString(data['phone'] ?? data['telefono']),
        'isSynced': true,
      },
    );
  }

  Future<void> _migrateWorkerRecords(String userId) {
    return _migrateCollection(
      legacyCollection: 'registros_recolector',
      targetCollection: 'worker_records',
      userId: userId,
      normalize: (data) {
        final kilograms = _asDouble(data['kilograms'] ?? data['kilos']) ?? 0;
        final pricePerKg =
            _asDouble(data['pricePerKg'] ?? data['precioKilo']) ?? 0;
        return {
          'userId': _asString(data['userId']) ?? userId,
          'workerId': _asString(data['workerId'] ?? data['trabajadorId']) ?? '',
          'workerName':
              _asString(
                data['workerName'] ??
                    data['nombreTrabajador'] ??
                    data['nombreWorker'],
              ) ??
              '',
          'date': _toIsoString(data['date'] ?? data['fecha']),
          'kilograms': kilograms,
          'pricePerKg': pricePerKg,
          'total': _asDouble(data['total']) ?? (kilograms * pricePerKg),
          'farmName':
              _asString(data['farmName'] ?? data['finca'] ?? data['fibra']) ??
              '',
          'isPaid': _asBool(data['isPaid'] ?? data['estaPagado']),
          'isSynced': true,
        };
      },
    );
  }

  Future<void> _migrateCollection({
    required String legacyCollection,
    required String targetCollection,
    required String userId,
    required Map<String, dynamic> Function(Map<String, dynamic> data) normalize,
  }) async {
    final query = await _firestore
        .collection(legacyCollection)
        .where('userId', isEqualTo: userId)
        .get();

    if (query.docs.isEmpty) return;

    WriteBatch batch = _firestore.batch();
    var writesInBatch = 0;

    for (final legacyDoc in query.docs) {
      final normalized = _withoutNulls(normalize(legacyDoc.data()));
      final targetDoc = _firestore
          .collection(targetCollection)
          .doc(legacyDoc.id);
      batch.set(targetDoc, normalized, SetOptions(merge: true));
      writesInBatch++;

      if (writesInBatch == 400) {
        await batch.commit();
        batch = _firestore.batch();
        writesInBatch = 0;
      }
    }

    if (writesInBatch > 0) {
      await batch.commit();
    }
  }

  Future<void> _archiveAndCleanupLegacyData(String userId) async {
    await _archiveAndDeleteLegacyUser(userId);

    await _archiveAndDeleteCollection(
      userId: userId,
      legacyCollection: 'fincas',
      targetCollection: 'farms',
    );
    await _archiveAndDeleteCollection(
      userId: userId,
      legacyCollection: 'registros',
      targetCollection: 'records',
    );
    await _archiveAndDeleteCollection(
      userId: userId,
      legacyCollection: 'trabajadores',
      targetCollection: 'workers',
    );
    await _archiveAndDeleteCollection(
      userId: userId,
      legacyCollection: 'registros_recolector',
      targetCollection: 'worker_records',
    );
  }

  Future<void> _archiveAndDeleteLegacyUser(String userId) async {
    final legacyDoc = await _legacyUsers.doc(userId).get();
    if (!legacyDoc.exists) return;

    final migratedUserDoc = await _users.doc(userId).get();
    if (!migratedUserDoc.exists) {
      throw StateError('Cannot clean legacy user profile before migration.');
    }

    final archiveRef = _users
        .doc(userId)
        .collection('legacy_usuarios')
        .doc('profile');

    await _firestore.runTransaction((transaction) async {
      transaction.set(archiveRef, {
        'sourceCollection': 'usuarios',
        'archivedAt': DateTime.now().toIso8601String(),
        'data': legacyDoc.data(),
      });
      transaction.delete(_legacyUsers.doc(userId));
    });
  }

  Future<void> _archiveAndDeleteCollection({
    required String userId,
    required String legacyCollection,
    required String targetCollection,
  }) async {
    final legacyQuery = await _firestore
        .collection(legacyCollection)
        .where('userId', isEqualTo: userId)
        .get();
    if (legacyQuery.docs.isEmpty) return;

    final targetQuery = await _firestore
        .collection(targetCollection)
        .where('userId', isEqualTo: userId)
        .get();

    if (targetQuery.docs.length < legacyQuery.docs.length) {
      throw StateError(
        'Safety check failed for $legacyCollection. '
        'Target collection has fewer docs than legacy.',
      );
    }

    WriteBatch batch = _firestore.batch();
    var writesInBatch = 0;
    final archiveCollection = _users
        .doc(userId)
        .collection('legacy_$legacyCollection');

    for (final legacyDoc in legacyQuery.docs) {
      batch.set(archiveCollection.doc(legacyDoc.id), {
        'sourceCollection': legacyCollection,
        'archivedAt': DateTime.now().toIso8601String(),
        'data': legacyDoc.data(),
      });
      batch.delete(legacyDoc.reference);
      writesInBatch += 2;

      if (writesInBatch >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        writesInBatch = 0;
      }
    }

    if (writesInBatch > 0) {
      await batch.commit();
    }
  }

  static Map<String, dynamic> _withoutNulls(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value != null) result[key] = value;
    });
    return result;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static String? _toIsoString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}
