// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/releve.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../models/sought_plant.dart';
import '../models/recipe.dart';
import '../models/app_reminder.dart';

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
      version: 19, // WERSJA 18: Naprawa brakującej kolumny stepsJson w przepisach
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE releves (
        id TEXT PRIMARY KEY, commonName TEXT NOT NULL, phytosociologicalName TEXT,
        type TEXT NOT NULL, pointsJson TEXT NOT NULL, parentId TEXT, date TEXT NOT NULL,
        habitatJson TEXT, mlPredictionsJson TEXT, FOREIGN KEY (parentId) REFERENCES releves (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE plant_species (
        speciesID TEXT PRIMARY KEY, latinName TEXT, polishName TEXT, family TEXT, biologicalType TEXT,
        prefPhMin REAL, prefPhMax REAL, prefSubstrateJson TEXT, prefMoisture REAL, prefSunlight REAL,
        prefAreaTypesJson TEXT, prefExposuresJson TEXT, prefCanopyCoversJson TEXT, prefWaterDynamicsJson TEXT,
        prefSoilDepthsJson TEXT, prefSlopeAnglesJson TEXT, prefLitterThicknessesJson TEXT,
        prefDistancesToWaterJson TEXT, prefDeadWoodJson TEXT, prefLandUseHistoryJson TEXT,
        plantUsage TEXT, cultivation TEXT, properties TEXT, associatedSyntaxaJson TEXT, harvestSeasonsJson TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE observations (
        id TEXT PRIMARY KEY, releveId TEXT, speciesId TEXT, localName TEXT, subspecies TEXT,
        tempBiologicalType TEXT, photoPathsJson TEXT, latitude REAL, longitude REAL, timestamp TEXT,
        characteristicsJson TEXT, observationDate TEXT, phenologicalStage TEXT, abundance TEXT, coverage TEXT,
        vitality TEXT, certainty TEXT, idDoubts TEXT, keyMorphologicalTraits TEXT, confusingSpecies TEXT,
        characteristicFeature TEXT, customHarvestSeasonsJson TEXT,
        FOREIGN KEY (releveId) REFERENCES releves (id) ON DELETE CASCADE, FOREIGN KEY (speciesId) REFERENCES plant_species (speciesID) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sought_plants (
        id TEXT PRIMARY KEY, polishName TEXT, latinName TEXT, prefPhMin REAL, prefPhMax REAL,
        prefSubstrateJson TEXT, prefMoisture REAL, prefSunlight REAL, prefAreaTypesJson TEXT,
        prefExposuresJson TEXT, prefCanopyCoversJson TEXT, prefWaterDynamicsJson TEXT, prefSoilDepthsJson TEXT,
        prefSlopeAnglesJson TEXT, prefLitterThicknessesJson TEXT, prefDistancesToWaterJson TEXT,
        prefDeadWoodJson TEXT, prefLandUseHistoryJson TEXT, targetMaterial TEXT, reminderMonthsJson TEXT,
        harvestSeasonsJson TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY, title TEXT, type TEXT, ingredientsJson TEXT,
        instructions TEXT, createdAt TEXT, timersJson TEXT, stepsJson TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_reminders (
        id TEXT PRIMARY KEY, title TEXT, body TEXT, scheduledTime TEXT,
        relatedId TEXT, type TEXT, isCompleted INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Od v16 dodawane były Timery i Przypomnienia
    if (oldVersion < 19) {
      try {
        await db.execute('ALTER TABLE app_reminders ADD COLUMN endDate TEXT');
        await db.execute('ALTER TABLE app_reminders ADD COLUMN isMuted INTEGER DEFAULT 0');
      } catch (e) { print("Błąd v19: $e"); }
    }
    // Naprawa błędu "no column named stepsJson"
    if (oldVersion < 18) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN stepsJson TEXT');
      } catch (e) { print("Błąd migracji bazy do v18: $e"); }
    }
  }

  // --- STANDARDOWY CRUD ---
  Future<void> insertReleve(Releve releve) async { final db = await database; await db.insert('releves', releve.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<Releve>> getReleves() async { final db = await database; final maps = await db.query('releves'); return List.generate(maps.length, (i) => Releve.fromMap(maps[i])); }
  Future<void> deleteReleve(String id) async { final db = await database; await db.delete('releves', where: 'id = ?', whereArgs: [id]); }

  Future<void> insertObservation(PlantObservation obs) async { final db = await database; await db.insert('observations', obs.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<PlantObservation>> getObservations() async { final db = await database; final maps = await db.query('observations'); return List.generate(maps.length, (i) => PlantObservation.fromMap(maps[i])); }
  Future<void> deleteObservation(String id) async { final db = await database; await db.delete('observations', where: 'id = ?', whereArgs: [id]); }

  Future<void> insertSpecies(PlantSpecies species) async { final db = await database; await db.insert('plant_species', species.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<PlantSpecies>> getSpecies() async { final db = await database; final maps = await db.query('plant_species'); return List.generate(maps.length, (i) => PlantSpecies.fromMap(maps[i])); }

  Future<void> insertSoughtPlant(SoughtPlant plant) async { final db = await database; await db.insert('sought_plants', plant.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<SoughtPlant>> getSoughtPlants() async { final db = await database; final maps = await db.query('sought_plants'); return List.generate(maps.length, (i) => SoughtPlant.fromMap(maps[i])); }
  Future<void> deleteSoughtPlant(String id) async { final db = await database; await db.delete('sought_plants', where: 'id = ?', whereArgs: [id]); }

  Future<void> insertRecipe(Recipe recipe) async { final db = await database; await db.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<Recipe>> getRecipes() async { final db = await database; final maps = await db.query('recipes'); return List.generate(maps.length, (i) => Recipe.fromMap(maps[i])); }
  Future<void> deleteRecipe(String id) async { final db = await database; await db.delete('recipes', where: 'id = ?', whereArgs: [id]); }

  Future<void> insertReminder(AppReminder reminder) async { final db = await database; await db.insert('app_reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<List<AppReminder>> getReminders() async { final db = await database; final maps = await db.query('app_reminders', orderBy: 'scheduledTime ASC'); return List.generate(maps.length, (i) => AppReminder.fromMap(maps[i])); }
  Future<void> updateReminderStatus(String id, bool isCompleted) async { final db = await database; await db.update('app_reminders', {'isCompleted': isCompleted ? 1 : 0}, where: 'id = ?', whereArgs: [id]); }
  Future<void> deleteReminder(String id) async { final db = await database; await db.delete('app_reminders', where: 'id = ?', whereArgs: [id]); }
}