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

    // Tworzymy JEDEN zbiorczy plik CSV dla modelu Random Forest
    // Cechy (X): moisture, ph, sunlight, pollution, substrates
    // Target (y): target_latin_name, target_local_name
    String csv = "obs_id,releve_id,moisture,ph,sunlight,pollution,substrates,target_latin_name,target_local_name\n";

    for (var obs in observations.where((o) => o.isComplete && o.releveId != null)) {
      // Szukamy obszaru, z którym powiązana jest ta roślina
      final releveIndex = releves.indexWhere((r) => r.id == obs.releveId);
      if (releveIndex == -1) continue; // Roślina bez przypisanego obszaru odpada

      final releve = releves[releveIndex];

      // Jeżeli obszar ma zdefiniowane siedlisko, dodajemy wiersz do pliku treningowego
      if (releve.habitat != null) {
        final h = releve.habitat!;
        csv += "${obs.id},"
            "${releve.id},"
            "${h.moisture},"
            "${h.ph ?? ''},"
            "${h.sunlight},"
            "${h.pollution},"
            "${_escapeCsvField(h.substrateType.join(';'))},"
            "${_escapeCsvField(obs.latinName)},"
            "${_escapeCsvField(obs.localName)}\n";
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