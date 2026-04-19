import 'dart:convert';

class PlantObservation {
  final String id;
  final List<String> photoPaths;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  // ZMIANA: Mapa przechowuje teraz listę tekstów zamiast pojedynczego tekstu
  final Map<String, List<String>> characteristics;

  String? biologicalType;
  String? phytosociologicalLayer;
  String? abundance;
  String? coverage;
  String? vitality;
  String? sociability;
  DateTime? observationDate;
  String? family;
  String? genus;
  String? species;
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
  String? phytosociologicalStatus;

  PlantObservation({
    required this.id,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
    this.biologicalType,
    this.phytosociologicalLayer,
    this.abundance,
    this.coverage,
    this.vitality,
    this.sociability,
    this.observationDate,
    this.family,
    this.genus,
    this.species,
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
    this.phytosociologicalStatus,
  });

  String get displayName => (localName != null && localName!.isNotEmpty)
      ? localName!
      : (polishName != null && polishName!.isNotEmpty) ? polishName! : "Nieznana roślina";

  bool get isComplete => localName != null && localName!.isNotEmpty && observationDate != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPaths': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      // Zapisujemy mapę list jako JSON
      'characteristics': jsonEncode(characteristics),
      'biologicalType': biologicalType,
      'phytosociologicalLayer': phytosociologicalLayer,
      'abundance': abundance,
      'coverage': coverage,
      'vitality': vitality,
      'sociability': sociability,
      'observationDate': observationDate?.toIso8601String(),
      'family': family,
      'genus': genus,
      'species': species,
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
      'phytosociologicalStatus': phytosociologicalStatus
    };
  }

  factory PlantObservation.fromMap(Map<String, dynamic> map) {
    // Odczyt i konwersja mapy list
    var rawChars = jsonDecode(map['characteristics'] ?? '{}');
    Map<String, List<String>> decodedChars = {};
    if (rawChars is Map) {
      rawChars.forEach((key, value) {
        decodedChars[key.toString()] = List<String>.from(value as List);
      });
    }

    return PlantObservation(
      id: map['id'] ?? '',
      photoPaths: List<String>.from(jsonDecode(map['photoPaths'] ?? '[]')),
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      characteristics: decodedChars,
      biologicalType: map['biologicalType'],
      phytosociologicalLayer: map['phytosociologicalLayer'],
      abundance: map['abundance'],
      coverage: map['coverage'],
      vitality: map['vitality'],
      sociability: map['sociability'],
      observationDate: map['observationDate'] != null ? DateTime.parse(map['observationDate']) : null,
      family: map['family'],
      genus: map['genus'],
      species: map['species'],
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
      phytosociologicalStatus: map['phytosociologicalStatus'],
    );
  }
}