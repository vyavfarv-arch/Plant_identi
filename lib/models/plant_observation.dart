import 'dart:convert';

class PlantObservation {
  final String id;
  final List<String> photoPaths;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final List<String> characteristics;

  // NOWE POLA:
  String? abundance;
  String? plantName;
  DateTime? observationDate;

  PlantObservation({
    required this.id,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
    this.abundance,
    this.plantName,
    this.observationDate,
  });

  // Czy roślina jest już w pełni opisana?
  bool get isComplete =>
      abundance != null &&
          plantName != null && plantName!.isNotEmpty &&
          observationDate != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPaths': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'characteristics': jsonEncode(characteristics),
      'abundance': abundance,
      'plantName': plantName,
      'observationDate': observationDate?.toIso8601String(),
    };
  }

  factory PlantObservation.fromMap(Map<String, dynamic> map) {
    return PlantObservation(
      id: map['id'] ?? '',
      photoPaths: List<String>.from(jsonDecode(map['photoPaths'])),
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      characteristics: List<String>.from(jsonDecode(map['characteristics'])),
      abundance: map['abundance'],
      plantName: map['plantName'],
      observationDate: map['observationDate'] != null
          ? DateTime.parse(map['observationDate'])
          : null,
    );
  }
}