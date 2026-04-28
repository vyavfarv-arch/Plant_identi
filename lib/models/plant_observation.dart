import 'dart:convert';

class PlantObservation {
  final String id;
  final String? releveId;
  final List<String> photoPaths;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, List<String>> characteristics;
  final bool isSought;
  final List<String> analyzedAreaIds;
  final int lastAnalysisAreaCount;
  final bool isPotential;
  final double? predictionProbability;

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

  double? prefPhMin;
  double? prefPhMax;
  List<String> prefSubstrate;
  double? prefMoisture;
  double? prefSunlight;

  PlantObservation({
    required this.id,
    this.releveId,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
    this.isSought = false,
    this.isPotential = false,
    this.predictionProbability,
    this.analyzedAreaIds = const [],
    this.lastAnalysisAreaCount = 0,
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
    this.prefSubstrate = const [],
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
      'releveId': releveId,
      'photoPathsJson': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'characteristicsJson': jsonEncode(characteristics),
      'biologicalType': biologicalType,
      'isSought': isSought ? 1 : 0,
      'isPotential': isPotential ? 1 : 0,
      'predictionProbability': predictionProbability,
      'areaPurity': areaPurity,
      'abundance': abundance,
      'coverage': coverage,
      'vitality': vitality,
      'observationDate': observationDate?.toIso8601String(),
      'family': family,
      'subspecies': subspecies,
      'latinName': latinName,
      'analyzedAreaIdsJson': jsonEncode(analyzedAreaIds),
      'lastAnalysisAreaCount': lastAnalysisAreaCount,
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
      'prefSubstrateJson': jsonEncode(prefSubstrate),
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
      } catch (e) { print("Błąd dekodowania cech: $e"); }
    }

    List<String> decodedSubstrates = [];
    if (map['prefSubstrateJson'] != null) {
      try {
        decodedSubstrates = List<String>.from(jsonDecode(map['prefSubstrateJson']));
      } catch (e) { print("Błąd dekodowania podłoży: $e"); }
    }

    return PlantObservation(
      id: map['id'] ?? '',
      releveId: map['releveId'],
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
      isPotential: map['isPotential'] == 1,
      predictionProbability: map['predictionProbability']?.toDouble(),
      analyzedAreaIds: map['analyzedAreaIdsJson'] != null
          ? List<String>.from(jsonDecode(map['analyzedAreaIdsJson']))
          : [],
      lastAnalysisAreaCount: map['lastAnalysisAreaCount'] ?? 0,
      localName: map['localName'],
      certainty: map['certainty'],
      idDoubts: map['idDoubts'],
      keyMorphologicalTraits: map['keyMorphologicalTraits'],
      confusingSpecies: map['confusingSpecies'],
      characteristicFeature: map['characteristicFeature'],
      plantUsage: map['plantUsage'],
      cultivation: map['cultivation'],
      isSought: map['isSought'] == 1,
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      prefSubstrate: decodedSubstrates,
      prefMoisture: map['prefMoisture']?.toDouble(),
      prefSunlight: map['prefSunlight']?.toDouble(),
    );
  }
}