// lib/services/data_export_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Zarządza pełnymi kopiami zapasowymi lokalnej bazy SQLite Planticatora.
class DataExportService {
  final DatabaseHelper _db = DatabaseHelper();

  static const String _databaseName = 'planticator.db';
  static const Set<String> _requiredTables = {
    'releves',
    'plant_species',
    'observations',
    'sought_plants',
    'recipes',
    'app_reminders',
  };

  /// Tworzy spójną kopię całej bazy i otwiera systemowe okno udostępniania/zapisu.
  Future<void> backupDatabase() async {
    final dbPath = join(await getDatabasesPath(), _databaseName);
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Nie znaleziono bazy danych aplikacji.');
    }

    // Zapisujemy transakcje WAL do głównego pliku przed wykonaniem kopii.
    final database = await _db.database;
    try {
      await database.rawQuery('PRAGMA wal_checkpoint(FULL)');
    } catch (e) {
      debugPrint('Nie udało się wykonać WAL checkpoint: $e');
    }

    final directory = await getTemporaryDirectory();
    final backupPath = join(
      directory.path,
      'planticator_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );

    await dbFile.copy(backupPath);

    await Share.shareXFiles(
      [XFile(backupPath)],
      text: 'Kopia zapasowa bazy danych Planticatora - ${DateTime.now().toIso8601String()}',
    );
  }

  /// Pozwala wybrać plik, sprawdza jego rzeczywistą strukturę SQLite
  /// i dopiero po potwierdzeniu, że jest bazą Planticatora, zastępuje
  /// aktywną bazę aplikacji.
  Future<bool> restoreDatabase() async {
    String? safetyCopyPath;
    final dbPath = join(await getDatabasesPath(), _databaseName);

    try {
      // Android nie na każdym urządzeniu obsługuje niestandardowy filtr ".db".
      // Pozwalamy więc wybrać dowolny plik, ale NIE ufamy rozszerzeniu:
      // plik jest później otwierany jako SQLite i walidowany na podstawie
      // integralności oraz wymaganych tabel Planticatora.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      // Anulowanie wyboru nie jest błędem.
      if (result == null || result.files.isEmpty) return false;

      final selectedPath = result.files.single.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) {
        throw Exception('Nie udało się uzyskać dostępu do wybranego pliku.');
      }

      final backupFile = File(selectedPath);
      if (!await backupFile.exists()) {
        throw Exception('Wybrany plik nie istnieje.');
      }
      if (await backupFile.length() == 0) {
        throw Exception('Wybrany plik bazy danych jest pusty.');
      }

      // Najważniejsze zabezpieczenie: rozszerzenie .db nie wystarcza.
      // Sprawdzamy, czy SQLite potrafi otworzyć plik i czy zawiera tabele Planticatora.
      await _validatePlanticatorDatabase(selectedPath);

      final currentDbFile = File(dbPath);

      // Zabezpieczamy aktualny stan przed nadpisaniem.
      if (await currentDbFile.exists()) {
        final database = await _db.database;
        try {
          await database.rawQuery('PRAGMA wal_checkpoint(FULL)');
        } catch (e) {
          debugPrint('Nie udało się wykonać WAL checkpoint przed restore: $e');
        }

        await _db.closeDatabase();

        final directory = await getTemporaryDirectory();
        safetyCopyPath = join(
          directory.path,
          'planticator_before_restore_${DateTime.now().millisecondsSinceEpoch}.db',
        );
        await currentDbFile.copy(safetyCopyPath);
      } else {
        await _db.closeDatabase();
      }

      try {
        await backupFile.copy(dbPath);

        // Otwieramy przez DatabaseHelper, aby uruchomić konfigurację/migracje aplikacji.
        await _db.database;
        return true;
      } catch (e) {
        // Jeśli podmiana lub ponowne otwarcie zawiedzie, odzyskujemy poprzednią bazę.
        await _db.closeDatabase();
        if (safetyCopyPath != null && await File(safetyCopyPath).exists()) {
          await File(safetyCopyPath).copy(dbPath);
          await _db.database;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Błąd podczas przywracania bazy danych: $e');
      rethrow;
    }
  }

  Future<void> _validatePlanticatorDatabase(String path) async {
    Database? candidateDb;
    try {
      candidateDb = await openDatabase(
        path,
        readOnly: true,
        singleInstance: false,
      );

      final integrityRows = await candidateDb.rawQuery('PRAGMA integrity_check');
      final integrityResult = integrityRows.isNotEmpty
          ? integrityRows.first.values.first?.toString().toLowerCase()
          : null;
      if (integrityResult != 'ok') {
        throw Exception('Plik SQLite jest uszkodzony lub niespójny.');
      }

      final tableRows = await candidateDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tables = tableRows
          .map((row) => row['name']?.toString())
          .whereType<String>()
          .toSet();

      final missingTables = _requiredTables.difference(tables);
      if (missingTables.isNotEmpty) {
        throw Exception(
          'Wybrany plik nie jest prawidłową kopią bazy Planticatora. '
          'Brak wymaganych tabel: ${missingTables.join(', ')}.',
        );
      }
    } on DatabaseException catch (e) {
      throw Exception('Wybrany plik nie jest prawidłową bazą SQLite: $e');
    } finally {
      await candidateDb?.close();
    }
  }
}
