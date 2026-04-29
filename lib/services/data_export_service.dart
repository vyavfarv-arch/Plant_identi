// lib/services/data_export_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';

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

    // ZMIANA: Nagłówki odzwierciedlają nowe, zaawansowane cechy ekologiczne
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
            "${h.moisture},"
            "${h.ph ?? ''},"
            "${_escapeCsvField(h.canopyCover)},"
            "${_escapeCsvField(h.waterDynamics)},"
            "${_escapeCsvField(h.areaType)},"
            "${_escapeCsvField(h.soilDepth)},"
            "${_escapeCsvField(h.slopeAngle)},"
            "${_escapeCsvField(h.litterThickness)},"
            "${_escapeCsvField(h.distanceToWater)},"
            "${_escapeCsvField(h.deadWood)},"
            "${_escapeCsvField(h.landUseHistory)},"
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