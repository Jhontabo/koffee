import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/registro_finca.dart';
import '../models/finca.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('registros_finca.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE registros ADD COLUMN kilosRojo REAL NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE fincas ADD COLUMN ubicacion TEXT
      ''');
      await db.execute('''
        ALTER TABLE fincas ADD COLUMN tamanoHectareas REAL
      ''');
      await db.execute('''
        ALTER TABLE fincas ADD COLUMN fechaCreacion TEXT
      ''');
      await db.execute('''
        ALTER TABLE fincas ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE fincas ADD COLUMN firebaseId TEXT
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE registros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        fecha TEXT NOT NULL,
        finca TEXT NOT NULL,
        kilosRojo REAL NOT NULL DEFAULT 0,
        kilosSeco REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        total REAL NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        firebaseId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fincas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        nombre TEXT NOT NULL,
        ubicacion TEXT,
        tamanoHectareas REAL,
        fechaCreacion TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        firebaseId TEXT
      )
    ''');
  }

  Future<int> insertRegistro(RegistroFinca registro) async {
    final db = await database;
    final map = registro.toMap();
    map.remove('id');
    return await db.insert('registros', map);
  }

  Future<List<RegistroFinca>> getAllRegistros(String userId) async {
    final db = await database;
    final result = await db.query(
      'registros',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => RegistroFinca.fromMap(map)).toList();
  }

  Future<List<RegistroFinca>> getUnsyncedRegistros() async {
    final db = await database;
    final result = await db.query(
      'registros',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => RegistroFinca.fromMap(map)).toList();
  }

  Future<int> updateRegistro(RegistroFinca registro) async {
    final db = await database;

    if (registro.id != null) {
      return await db.update(
        'registros',
        registro.toMap(),
        where: 'id = ?',
        whereArgs: [registro.id],
      );
    } else if (registro.firebaseId != null) {
      // Buscar por firebaseId si no hay id local
      final existing = await db.query(
        'registros',
        where: 'firebaseId = ?',
        whereArgs: [registro.firebaseId],
      );
      if (existing.isNotEmpty) {
        final localId = existing.first['id'] as int;
        final map = registro.toMap();
        map['isSynced'] = 1;
        return await db.update(
          'registros',
          map,
          where: 'id = ?',
          whereArgs: [localId],
        );
      }
    }
    return 0;
  }

  Future<int> markAsSynced(int id, String firebaseId) async {
    final db = await database;
    return await db.update(
      'registros',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRegistro(int? id, {String? firebaseId}) async {
    final db = await database;

    if (id != null) {
      return await db.delete('registros', where: 'id = ?', whereArgs: [id]);
    } else if (firebaseId != null) {
      return await db.delete(
        'registros',
        where: 'firebaseId = ?',
        whereArgs: [firebaseId],
      );
    }
    return 0;
  }

  Future<Map<String, double>> getKilosByFinca(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT finca, SUM(kilosSeco + kilosRojo) as totalKilos FROM registros WHERE userId = ? GROUP BY finca',
      [userId],
    );
    final Map<String, double> kilosMap = {};
    for (final row in result) {
      kilosMap[row['finca'] as String] = (row['totalKilos'] as num).toDouble();
    }
    return kilosMap;
  }

  Future<void> upsertRegistro(RegistroFinca registro) async {
    final db = await database;

    // Check if exists by firebaseId
    if (registro.firebaseId != null) {
      final existing = await db.query(
        'registros',
        where: 'firebaseId = ?',
        whereArgs: [registro.firebaseId],
      );

      if (existing.isNotEmpty) {
        // Update
        final id = existing.first['id'] as int;
        final map = registro.toMap();
        map.remove('id'); // Don't change local ID
        map['isSynced'] = 1; // Mark as synced since it comes from cloud

        await db.update('registros', map, where: 'id = ?', whereArgs: [id]);
        return;
      }
    }

    // Insert new
    final map = registro.toMap();
    map.remove('id'); // Let autoincrement work
    map['isSynced'] = 1;
    await db.insert('registros', map);
  }

  Future<int> insertFinca(Finca finca) async {
    final db = await database;
    final map = finca.toMap();
    map.remove('id');
    return await db.insert('fincas', map);
  }

  Future<List<Finca>> getAllFincas(String userId) async {
    final db = await database;
    final result = await db.query(
      'fincas',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => Finca.fromMap(map)).toList();
  }

  Future<List<String>> getFincasNames(String userId) async {
    final db = await database;
    final result = await db.query(
      'fincas',
      where: 'userId = ?',
      whereArgs: [userId],
      columns: ['nombre'],
    );
    return result.map((map) => map['nombre'] as String).toList();
  }

  Future<int> updateFinca(Finca finca) async {
    final db = await database;
    return await db.update(
      'fincas',
      finca.toMap(),
      where: 'id = ?',
      whereArgs: [finca.id],
    );
  }

  Future<int> deleteFinca(int id) async {
    final db = await database;
    return await db.delete('fincas', where: 'id = ?', whereArgs: [id]);
  }

  Future<Finca?> getFincaByName(String userId, String nombre) async {
    final db = await database;
    final result = await db.query(
      'fincas',
      where: 'userId = ? AND nombre = ?',
      whereArgs: [userId, nombre],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Finca.fromMap(result.first);
  }

  Future<List<Finca>> getUnsyncedFincas() async {
    final db = await database;
    final result = await db.query(
      'fincas',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => Finca.fromMap(map)).toList();
  }

  Future<int> markFincaAsSynced(int id, String firebaseId) async {
    final db = await database;
    return await db.update(
      'fincas',
      {'isSynced': 1, 'firebaseId': firebaseId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertFinca(Finca nuevaFinca) async {
    final db = await database;

    if (nuevaFinca.firebaseId != null) {
      final existing = await db.query(
        'fincas',
        where: 'firebaseId = ?',
        whereArgs: [nuevaFinca.firebaseId],
      );

      if (existing.isNotEmpty) {
        final id = existing.first['id'] as int;
        final map = nuevaFinca.toMap();
        map.remove('id');
        map['isSynced'] = 1;

        await db.update('fincas', map, where: 'id = ?', whereArgs: [id]);
        return;
      }
    }

    final map = nuevaFinca.toMap();
    map.remove('id');
    map['isSynced'] = 1;
    await db.insert('fincas', map);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
