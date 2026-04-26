// lib/services/data_export_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Dodaj do pubspec.yaml: share_plus: ^7.2.1
import 'database_helper.dart';

class DataExportService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> exportDataForML() async {
    final observations = await _db.getObservations();
    final releves = await _db.getReleves();

    // 1. Nagłówek dla danych roślin (Etykiety/Klasy)
    String plantCsv = "id,name,latin_name,family,pref_ph_min,pref_ph_max,pref_moisture,pref_sunlight,pref_substrate\n";

    for (var obs in observations.where((o) => o.isComplete)) {
      plantCsv += "${obs.id},"
          "${obs.displayName},"
          "${obs.latinName ?? ''},"
          "${obs.family ?? ''},"
          "${obs.prefPhMin ?? ''},"
          "${obs.prefPhMax ?? ''},"
          "${obs.prefMoisture ?? ''},"
          "${obs.prefSunlight ?? ''},"
          "\"${obs.prefSubstrate.join(';')}\"\n";
    }

    // 2. Nagłówek dla danych siedlisk (Cechy wejściowe)
    String habitatCsv = "id,common_name,type,moisture,ph,sunlight,pollution,substrates\n";

    for (var rel in releves) {
      final h = rel.habitat;
      if (h != null) {
        habitatCsv += "${rel.id},"
            "${rel.commonName},"
            "${rel.type},"
            "${h.moisture},"
            "${h.ph ?? ''},"
            "${h.sunlight},"
            "${h.pollution},"
            "\"${h.substrateType.join(';')}\"\n";
      }
    }

    // Zapisywanie plików
    final directory = await getTemporaryDirectory();
    final plantFile = File('${directory.path}/observations_ml.csv');
    final habitatFile = File('${directory.path}/habitats_ml.csv');

    await plantFile.writeAsString(plantCsv);
    await habitatFile.writeAsString(habitatCsv);

    // Udostępnienie plików (do wysłania na maila/chmurę/laptopa)
    await Share.shareXFiles(
      [XFile(plantFile.path), XFile(habitatFile.path)],
      text: 'Dane ML z Plantyfikatora - ${DateTime.now().toIso8601String()}',
    );
  }
}