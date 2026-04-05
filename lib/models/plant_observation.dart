import 'dart:convert';

class PlantObservation {
  final String id;
  final List<String> photoPaths; // Ścieżki do max 3 zdjęć w telefonie
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final List<String> characteristics; // Wybrane bloki cech (np. ["liście ząbkowane", "kwiaty czerwone"])

  PlantObservation({
    required this.id,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
  });

  // Metoda pomocnicza do zamiany obiektu na Mapę (potrzebne do zapisu np. w SQLite lub JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPaths': jsonEncode(photoPaths), // Zapisujemy listę jako tekst JSON
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'characteristics': jsonEncode(characteristics),
    };
  }

  // Metoda do tworzenia obiektu z Mapy (pobieranie z bazy danych)
  factory PlantObservation.fromMap(Map<String, dynamic> map) {
    return PlantObservation(
      id: map['id'] ?? '',
      photoPaths: List<String>.from(jsonDecode(map['photoPaths'])),
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      characteristics: List<String>.from(jsonDecode(map['characteristics'])),
    );
  }
}