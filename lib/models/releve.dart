// lib/models/releve.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'habitat_info.dart';
import 'dart:convert';

class Releve {
  final String id;
  final String commonName;
  final String phytosociologicalName;
  final String type;
  final List<LatLng> points;
  final DateTime date;
  String? parentId;
  HabitatInfo? habitat;

  // NOWE: Przechowuje wyniki ML (Nazwa gatunku -> Prawdopodobieństwo %)
  Map<String, double> mlPredictions;

  Releve({
    required this.id,
    required this.commonName,
    required this.phytosociologicalName,
    required this.type,
    required this.points,
    required this.date,
    this.parentId,
    this.habitat,
    this.mlPredictions = const {}, // Domyślnie puste
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'commonName': commonName,
      'phytosociologicalName': phytosociologicalName,
      'type': type,
      'pointsJson': jsonEncode(points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList()),
      'parentId': parentId,
      'date': date.toIso8601String(),
      'habitatJson': habitat != null ? jsonEncode(habitat!.toMap()) : null,
      'mlPredictionsJson': jsonEncode(mlPredictions), // Zapis do JSON
    };
  }

  factory Releve.fromMap(Map<String, dynamic> map) {
    List<dynamic> pointsData = [];
    if (map.containsKey('pointsJson') && map['pointsJson'] != null) {
      pointsData = jsonDecode(map['pointsJson']);
    } else if (map.containsKey('points')) {
      pointsData = map['points'] as List;
    }

    Map<String, double> decodedPredictions = {};
    if (map['mlPredictionsJson'] != null) {
      try {
        final rawMap = jsonDecode(map['mlPredictionsJson']) as Map<String, dynamic>;
        rawMap.forEach((k, v) => decodedPredictions[k] = (v as num).toDouble());
      } catch (e) {
        print("Błąd dekodowania predykcji ML: $e");
      }
    }

    return Releve(
      id: map['id'],
      commonName: map['commonName'] ?? '',
      phytosociologicalName: map['phytosociologicalName'] ?? '',
      type: map['type'],
      points: pointsData.map((p) => LatLng(p['lat'], p['lng'])).toList(),
      date: DateTime.parse(map['date']),
      parentId: map['parentId'],
      habitat: map['habitatJson'] != null ? HabitatInfo.fromMap(jsonDecode(map['habitatJson'])) : null,
      mlPredictions: decodedPredictions, // Odczyt z JSON
    );
  }
}