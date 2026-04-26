// lib/models/plant_observation.dart
import 'dart:convert';

class PlantObservation {
  final String id;
  final List<String> photoPaths;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, List<String>> characteristics;

  String? biologicalType;
  String? areaPurity;
  String? abundance;
  String? coverage;
  String? vitality;
  DateTime? observationDate;
  String? family;
  String? subspecies;
  String? latinName;
  String? polishName;
  String? localName;
  String? certainty;
  String? idDoubts;
  String? keyMorphologicalTraits;
  String? confusingSpecies;
  String? characteristicFeature;
  String? plantUsage;
  String? cultivation;

  // NOWE: Preferencje środowiskowe (dla modelu Random Forest)
  double? prefPhMin;
  double? prefPhMax;
  String? prefSubstrate;
  double? prefMoisture;
  double? prefSunlight;

  PlantObservation({
    required this.id,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
    this.biologicalType,
    this.areaPurity,
    this.abundance,
    this.coverage,
    this.vitality,
    this.observationDate,
    this.family,
    this.subspecies,
    this.latinName,
    this.polishName,
    this.localName,
    this.certainty,
    this.idDoubts,
    this.keyMorphologicalTraits,
    this.confusingSpecies,
    this.characteristicFeature,
    this.plantUsage,
    this.cultivation,
    this.prefPhMin,
    this.prefPhMax,
    this.prefSubstrate,
    this.prefMoisture,
    this.prefSunlight,
  });

  String get displayName => (localName != null && localName!.isNotEmpty)
      ? localName!
      : (polishName != null && polishName!.isNotEmpty) ? polishName! : "Nieznana roślina";

  bool get isComplete => localName != null && localName!.isNotEmpty && observationDate != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPathsJson': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'characteristicsJson': jsonEncode(characteristics),
      'biologicalType': biologicalType,
      'areaPurity': areaPurity,
      'abundance': abundance,
      'coverage': coverage,
      'vitality': vitality,
      'observationDate': observationDate?.toIso8601String(),
      'family': family,
      'subspecies': subspecies,
      'latinName': latinName,
      'polishName': polishName,
      'localName': localName,
      'certainty': certainty,
      'idDoubts': idDoubts,
      'keyMorphologicalTraits': keyMorphologicalTraits,
      'confusingSpecies': confusingSpecies,
      'characteristicFeature': characteristicFeature,
      'plantUsage': plantUsage,
      'cultivation': cultivation,
      'prefPhMin': prefPhMin,
      'prefPhMax': prefPhMax,
      'prefSubstrate': prefSubstrate,
      'prefMoisture': prefMoisture,
      'prefSunlight': prefSunlight,
    };
  }

  factory PlantObservation.fromMap(Map<String, dynamic> map) {
    Map<String, List<String>> decodedChars = {};
    if (map['characteristicsJson'] != null) {
      try {
        final Map<String, dynamic> rawMap = jsonDecode(map['characteristicsJson']);
        rawMap.forEach((key, value) {
          decodedChars[key] = List<String>.from(value);
        });
      } catch (e) { print("Błąd dekodowania: $e"); }
    }

    return PlantObservation(
      id: map['id'] ?? '',
      photoPaths: map['photoPathsJson'] != null ? List<String>.from(jsonDecode(map['photoPathsJson'])) : [],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      characteristics: decodedChars,
      biologicalType: map['biologicalType'],
      areaPurity: map['areaPurity'],
      abundance: map['abundance'],
      coverage: map['coverage'],
      vitality: map['vitality'],
      observationDate: map['observationDate'] != null ? DateTime.parse(map['observationDate']) : null,
      family: map['family'],
      subspecies: map['subspecies'],
      latinName: map['latinName'],
      polishName: map['polishName'],
      localName: map['localName'],
      certainty: map['certainty'],
      idDoubts: map['idDoubts'],
      keyMorphologicalTraits: map['keyMorphologicalTraits'],
      confusingSpecies: map['confusingSpecies'],
      characteristicFeature: map['characteristicFeature'],
      plantUsage: map['plantUsage'],
      cultivation: map['cultivation'],
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      prefSubstrate: map['prefSubstrate'],
      prefMoisture: map['prefMoisture']?.toDouble(),
      prefSunlight: map['prefSunlight']?.toDouble(),
    );
  }
}