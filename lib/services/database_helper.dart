import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/registro_finca.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE registros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
  }

  Future<int> insertRegistro(RegistroFinca registro) async {
    final db = await database;
    final map = registro.toMap();
    map.remove('id');
    return await db.insert('registros', map);
  }

  Future<List<RegistroFinca>> getAllRegistros() async {
    final db = await database;
    final result = await db.query('registros', orderBy: 'fecha DESC');
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
    return await db.update(
      'registros',
      registro.toMap(),
      where: 'id = ?',
      whereArgs: [registro.id],
    );
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

  Future<int> deleteRegistro(int id) async {
    final db = await database;
    return await db.delete(
      'registros',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getKilosByFinca() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT finca, SUM(kilosSeco + kilosRojo) as totalKilos FROM registros GROUP BY finca',
    );
    final Map<String, double> kilosMap = {};
    for (final row in result) {
      kilosMap[row['finca'] as String] = (row['totalKilos'] as num).toDouble();
    }
    return kilosMap;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
