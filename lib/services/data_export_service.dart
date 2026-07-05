// lib/services/data_export_service.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Moduł przygotowania danych pod kątem Machine Learning oraz zarządzania kopiami
 * zapasowymi. Odpowiada za konsolidację danych, parowanie obserwacji z opisem
 * płatów, eksport do CSV, tworzenie kopii zapasowej bazy (.db) oraz przywracanie jej.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku 'database_helper.dart':
 * - Klasa [DatabaseHelper]: Służy do wyciągnięcia list obserwacji, płatów oraz bazy gatunków.
 * ============================================================================
 */
class DataExportService {
  final DatabaseHelper _db = DatabaseHelper();

  String _escapeCsvField(String? text) {
    if (text == null) return '';
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      final escapedText = text.replaceAll('"', '""');
      return '"$escapedText"';
    }
    return text;
  }

  // POPRAWKA LOGIKI ML: Nagłówek CSV ma teraz dokładnie 13 kolumn, odpowiadających wstrzykiwanemu ciału danych!
  Future<void> exportDataForML() async {
    final observations = await _db.getObservations();
    final releves = await _db.getReleves();
    final allSpecies = await _db.getSpecies();

    String csv = "obs_id,releve_id,canopy_density,ph,water_movement,hydrological_context,area_type,slope_angle,soil_surface_cover,human_impact,substrates,target_latin_name,target_local_name\n";

    for (var obs in observations.where((o) => o.isComplete && o.releveId != null)) {
      final releveIndex = releves.indexWhere((r) => r.id == obs.releveId);
      if (releveIndex == -1) continue;

      final speciesIndex = allSpecies.indexWhere((s) => s.speciesID == obs.speciesId);
      if (speciesIndex == -1) continue;

      final releve = releves[releveIndex];
      final species = allSpecies[speciesIndex];

      if (releve.habitat != null) {
        final h = releve.habitat!;
        csv += "${obs.id},"
            "${releve.id},"
            "${h.canopyDensity},"
            "${h.ph ?? ''},"
            "${_escapeCsvField(h.waterMovement)},"
            "${_escapeCsvField(h.hydrologicalContext)},"
            "${_escapeCsvField(h.areaType)},"
            "${_escapeCsvField(h.slopeAngle)},"
            "${_escapeCsvField(h.soilSurfaceCover)},"
            "${_escapeCsvField(h.humanImpact)},"
            "${_escapeCsvField(h.substrateType.join(';'))},"
            "${_escapeCsvField(species.latinName)},"
            "${_escapeCsvField(species.polishName)}\n";
      }
    }

    final directory = await getTemporaryDirectory();
    final mlFile = File('${directory.path}/training_data.csv');
    await mlFile.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(mlFile.path)],
      text: 'Złączone dane treningowe ML z Plantyfikatora - ${DateTime.now().toIso8601String()}',
    );
  }

  // NOWOŚĆ: Kopia zapasowa pełnego pliku bazy danych i wysłanie jej systemem Share
  Future<void> backupDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'planticator.db');
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      final directory = await getTemporaryDirectory();
      final backupPath = join(directory.path, 'planticator_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await dbFile.copy(backupPath);

      await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'Kopia zapasowa bazy danych Plantyfikatora - ${DateTime.now().toIso8601String()}',
      );
    }
  }

  // NOWOŚĆ: Wczytanie wybranego pliku bazy danych i podmienienie go w pamięci aplikacji
  Future<bool> restoreDatabase() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final selectedPath = result.files.single.path!;
        final dbPath = join(await getDatabasesPath(), 'planticator.db');

        await _db.closeDatabase();

        final backupFile = File(selectedPath);
        await backupFile.copy(dbPath);

        await _db.database;
        return true;
      }
    } catch (e) {
      debugPrint("Błąd podczas przywracania bazy danych: $e");
    }
    return false;
  }
}