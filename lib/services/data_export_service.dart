// lib/services/data_export_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Moduł przygotowania danych pod kątem Machine Learning. Odpowiada za konsolidację
 * lokalnych baz danych, parowanie kompletnych obserwacji terenowych z fizjograficznym
 * opisem płatów florystycznych, ujednolicanie ich struktur oraz eksport do pliku CSV
 * w celu zasilenia zewnętrznych modeli uczenia maszynowego.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku 'database_helper.dart':
 * - Klasa [DatabaseHelper]: Służy do asynchronicznego wyciągnięcia pełnych list
 * obserwacji, płatów (releves) oraz bazy gatunków z lokalnego motoru SQLite.
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

  Future<void> exportDataForML() async {
    final observations = await _db.getObservations();
    final releves = await _db.getReleves();
    final allSpecies = await _db.getSpecies();

    String csv = "obs_id,releve_id,moisture,ph,canopyCover,waterDynamics,areaType,soilDepth,slopeAngle,litterThickness,distanceToWater,deadWood,landUseHistory,substrates,target_latin_name,target_local_name\n";

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
}