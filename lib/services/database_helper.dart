// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/releve.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../models/sought_plant.dart';

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
      version: 1, // Świeża wersja po wielkim refaktorze
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Tabela Płatów (Releves)
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
        mlPredictionsJson TEXT, -- Tabela trzyma wyniki ML
        FOREIGN KEY (parentId) REFERENCES releves (id) ON DELETE SET NULL
      )
    ''');

    // 2. Tabela Gatunków (Słownik / Ghost Plants)
    await db.execute('''
      CREATE TABLE plant_species (
        speciesID TEXT PRIMARY KEY,
        latinName TEXT,
        polishName TEXT,
        family TEXT,
        biologicalType TEXT,
        prefPhMin REAL,
        prefPhMax REAL,
        prefSubstrateJson TEXT,
        prefMoisture REAL,
        prefSunlight REAL,
        plantUsage TEXT,
        cultivation TEXT,
        properties TEXT,
        associatedSyntaxaJson TEXT,
        harvestSeasonsJson TEXT
      )
    ''');

    // 3. Tabela Obserwacji (Fizyczne okazy)
    await db.execute('''
      CREATE TABLE observations (
        id TEXT PRIMARY KEY,
        releveId TEXT,
        speciesId TEXT,
        localName TEXT,
        subspecies TEXT,
        tempBiologicalType TEXT,
        photoPathsJson TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        characteristicsJson TEXT,
        observationDate TEXT,
        areaPurity TEXT,
        abundance TEXT,
        coverage TEXT,
        vitality TEXT,
        certainty TEXT,
        idDoubts TEXT,
        keyMorphologicalTraits TEXT,
        confusingSpecies TEXT,
        characteristicFeature TEXT,
        FOREIGN KEY (releveId) REFERENCES releves (id) ON DELETE CASCADE,
        FOREIGN KEY (speciesId) REFERENCES plant_species (speciesID) ON DELETE SET NULL
      )
    ''');

    // 4. Tabela Poszukiwań (Moduł: Szukaj roślin)
    await db.execute('''
      CREATE TABLE sought_plants (
        id TEXT PRIMARY KEY,
        polishName TEXT,
        latinName TEXT,
        prefPhMin REAL,
        prefPhMax REAL,
        prefSubstrateJson TEXT,
        prefMoisture REAL,
        prefSunlight REAL
      )
    ''');
  }

  // --- RELEVES CRUD ---
  Future<void> insertReleve(Releve releve) async {
    final db = await database;
    await db.insert('releves', releve.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Releve>> getReleves() async {
    final db = await database;
    final maps = await db.query('releves');
    return List.generate(maps.length, (i) => Releve.fromMap(maps[i]));
  }

  Future<void> deleteReleve(String id) async {
    final db = await database;
    await db.delete('releves', where: 'id = ?', whereArgs: [id]);
  }

  // --- OBSERVATIONS CRUD ---
  Future<void> insertObservation(PlantObservation obs) async {
    final db = await database;
    await db.insert('observations', obs.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PlantObservation>> getObservations() async {
    final db = await database;
    final maps = await db.query('observations');
    return List.generate(maps.length, (i) => PlantObservation.fromMap(maps[i]));
  }

  Future<void> deleteObservation(String id) async {
    final db = await database;
    await db.delete('observations', where: 'id = ?', whereArgs: [id]);
  }

  // --- SPECIES (GHOST PLANTS) CRUD ---
  Future<void> insertSpecies(PlantSpecies species) async {
    final db = await database;
    await db.insert('plant_species', species.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PlantSpecies>> getSpecies() async {
    final db = await database;
    final maps = await db.query('plant_species');
    return List.generate(maps.length, (i) => PlantSpecies.fromMap(maps[i]));
  }

  // --- SOUGHT PLANTS CRUD ---
  Future<void> insertSoughtPlant(SoughtPlant plant) async {
    final db = await database;
    await db.insert('sought_plants', plant.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SoughtPlant>> getSoughtPlants() async {
    final db = await database;
    final maps = await db.query('sought_plants');
    return List.generate(maps.length, (i) => SoughtPlant.fromMap(maps[i]));
  }

  Future<void> deleteSoughtPlant(String id) async {
    final db = await database;
    await db.delete('sought_plants', where: 'id = ?', whereArgs: [id]);
  }
}