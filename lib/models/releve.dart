import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'habitat_info.dart';
import 'dart:convert';

class Releve {
  final String id;
  final String commonName;           // Nazwa orientacyjna (np. "Przy rzece")
  final String phytosociologicalName; // Nazwa naukowa do powiązań (np. "Alnion glutinosae")
  final String type;                 // Zespół, Związek, Rząd, Klasa
  final List<LatLng> points;
  final DateTime date;
  String? parentId;
  HabitatInfo? habitat;

  Releve({
    required this.id,
    required this.commonName,
    required this.phytosociologicalName,
    required this.type,
    required this.points,
    required this.date,
    this.parentId,
    this.habitat,
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
    };
  }

  factory Releve.fromMap(Map<String, dynamic> map) {
    // Rozwiązanie crasha: bezpieczne dekodowanie pointsJson z SQLite
    List<dynamic> pointsData = [];
    if (map.containsKey('pointsJson') && map['pointsJson'] != null) {
      pointsData = jsonDecode(map['pointsJson']);
    } else if (map.containsKey('points')) {
      pointsData = map['points'] as List; // Fallback dla starych danych z RAM
    }

    return Releve(
      id: map['id'],
      commonName: map['commonName'] ?? '',
      phytosociologicalName: map['phytosociologicalName'] ?? '',
      type: map['type'],
      points: pointsData.map((p) => LatLng(p['lat'], p['lng'])).toList(),
      date: DateTime.parse(map['date']),
      parentId: map['parentId'],
      // Bezpieczne dekodowanie habitatu z JSON
      habitat: map['habitatJson'] != null
          ? HabitatInfo.fromMap(jsonDecode(map['habitatJson']))
          : null,
    );
  }
}