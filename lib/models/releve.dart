import 'package:google_maps_flutter/google_maps_flutter.dart';

class Releve {
  final String id;
  final String name;
  final String type; // "Zespół", "Związek", "Rząd", "Klasa"
  final List<LatLng> points; // Używamy nazwy 'points'
  final DateTime date;

  Releve({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'date': date.toIso8601String(),
    };
  }

  factory Releve.fromMap(Map<String, dynamic> map) {
    return Releve(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      points: (map['points'] as List)
          .map((p) => LatLng(p['lat'] as double, p['lng'] as double))
          .toList(),
      date: DateTime.parse(map['date']),
    );
  }
}