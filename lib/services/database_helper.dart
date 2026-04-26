import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/releve.dart';
import '../models/plant_observation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'planticator.db');
    return await openDatabase(
      path,
      version: 5, // ZMIANA: Wersja 4 dla modułu zielarskiego
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabela Obszarów
    await db.execute('''
      CREATE TABLE releves (
        id TEXT PRIMARY KEY,
        commonName TEXT NOT NULL,
        phytosociologicalName TEXT,
        type TEXT NOT NULL,
        pointsJson TEXT NOT NULL,
        parentId TEXT,
        date TEXT NOT NULL,
        habitatJson TEXT,
        FOREIGN KEY (parentId) REFERENCES releves (id) ON DELETE SET NULL
      )
    ''');

    // Tabela Obserwacji - KOMPLETNA LISTA KOLUMN
    await db.execute('''
      CREATE TABLE observations (
        id TEXT PRIMARY KEY,
        releveId TEXT,
        localName TEXT,
        latinName TEXT,
        polishName TEXT,
        family TEXT,
        subspecies TEXT,
        biologicalType TEXT,
        areaPurity TEXT,
        abundance TEXT,
        coverage TEXT,
        vitality TEXT,
        certainty TEXT,
        idDoubts TEXT,
        keyMorphologicalTraits TEXT,
        confusingSpecies TEXT,
        characteristicFeature TEXT,
        plantUsage TEXT,
        cultivation TEXT,
        observationDate TEXT,
        photoPathsJson TEXT,
        characteristicsJson TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        prefPhMin REAL,
        prefPhMax REAL,
        prefSubstrate TEXT,
        prefMoisture REAL,
        prefSunlight REAL,
        FOREIGN KEY (releveId) REFERENCES releves (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plant_knowledge (
        latinName TEXT PRIMARY KEY,
        polishName TEXT,
        associatedSyntaxaJson TEXT,
        preferredSubstratesJson TEXT,
        preferredMoistureMin REAL,
        preferredMoistureMax REAL,
        floweringStartMonth INTEGER,
        floweringEndMonth INTEGER,
        properties TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      final List<String> newCols = [
        'prefPhMin', 'prefPhMax', 'prefSubstrate', 'prefMoisture', 'prefSunlight'
      ];
      for (var col in newCols) {
        try { await db.execute('ALTER TABLE observations ADD COLUMN $col REAL'); } catch(e){}
      }

    }
  }

  // --- METODY CRUD  ---

  Future<void> insertReleve(Releve releve) async {
    final db = await database;
    await db.insert('releves', releve.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Releve>> getReleves() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('releves');
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<void> deleteReleve(String id) async {
    final db = await database;
    await db.delete('releves', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertObservation(PlantObservation obs, {String? releveId}) async {
    final db = await database;
    final map = obs.toMap();
    map['releveId'] = releveId;
    await db.insert('observations', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PlantObservation>> getObservations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('observations');
    return List.generate(maps.length, (i) => PlantObservation.fromMap(maps[i]));
  }

  Future<void> deleteObservation(String id) async {
    final db = await database;
    await db.delete('observations', where: 'id = ?', whereArgs: [id]);
  }
}