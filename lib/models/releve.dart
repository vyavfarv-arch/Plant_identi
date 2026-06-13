// lib/models/releve.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'habitat_info.dart';
import 'dart:convert';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Reprezentuje zdjęcie fitosocjologiczne / płat roślinny wyznaczany za pomocą
 * współrzędnych wielokąta. Agreguje dane środowiskowe oraz mapę predykcji ML.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku 'habitat_info.dart':
 * - Klasa [HabitatInfo]: Używana jako pole strukturalne `habitat` do pełnego
 * opisu właściwości fizjograficzno-glebowych siedliska oraz ich serializacji do bazy SQL.
 * ============================================================================
 */
class Releve {
  final String id;
  final String commonName;
  final String phytosociologicalName;
  final String type;
  final List<LatLng> points;
  final DateTime date;
  final String? parentId; // FIX: final
  final HabitatInfo? habitat; // FIX: final
  final Map<String, double> mlPredictions; // FIX: final

  Releve({required this.id, required this.commonName, required this.phytosociologicalName, required this.type, required this.points, required this.date, this.parentId, this.habitat, this.mlPredictions = const {}});

  // NOWOŚĆ: Metoda copyWith dla bezpiecznych aktualizacji w ViewModelach
  Releve copyWith({
    String? commonName, String? phytosociologicalName, String? type, List<LatLng>? points, DateTime? date,
    String? parentId, HabitatInfo? habitat, Map<String, double>? mlPredictions,
  }) {
    return Releve(
      id: this.id,
      commonName: commonName ?? this.commonName,
      phytosociologicalName: phytosociologicalName ?? this.phytosociologicalName,
      type: type ?? this.type,
      points: points ?? this.points,
      date: date ?? this.date,
      parentId: parentId ?? this.parentId,
      habitat: habitat ?? this.habitat,
      mlPredictions: mlPredictions ?? this.mlPredictions,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'commonName': commonName, 'phytosociologicalName': phytosociologicalName, 'type': type,
    'pointsJson': jsonEncode(points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()), 'parentId': parentId, 'date': date.toIso8601String(),
    'habitatJson': habitat != null ? jsonEncode(habitat!.toMap()) : null, 'mlPredictionsJson': jsonEncode(mlPredictions),
  };

  factory Releve.fromMap(Map<String, dynamic> map) {
    List<dynamic> pointsData = map['pointsJson'] != null ? jsonDecode(map['pointsJson']) : [];
    Map<String, double> decodedPredictions = {};
    if (map['mlPredictionsJson'] != null) {
      try { (jsonDecode(map['mlPredictionsJson']) as Map).forEach((k, v) => decodedPredictions[k] = (v as num).toDouble()); } catch (_) {}
    }
    return Releve(
      id: map['id'], commonName: map['commonName'] ?? '', phytosociologicalName: map['phytosociologicalName'] ?? '', type: map['type'],
      points: pointsData.map((p) => LatLng(p['lat'], p['lng'])).toList(), date: DateTime.parse(map['date']), parentId: map['parentId'],
      habitat: map['habitatJson'] != null ? HabitatInfo.fromMap(jsonDecode(map['habitatJson'])) : null, mlPredictions: decodedPredictions,
    );
  }
}