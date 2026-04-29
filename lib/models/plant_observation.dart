// lib/models/plant_observation.dart
import 'dart:convert';
import 'harvest_season.dart';

class PlantObservation {
  final String id;
  final String? releveId;
  final String? speciesId;
  final String? localName;
  final String? subspecies;
  final String? tempBiologicalType;
  final List<String> photoPaths;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, List<String>> characteristics;
  final DateTime? observationDate;
  final String? phenologicalStage;
  final String? abundance;
  final String? coverage;
  final String? vitality;
  final String? certainty;
  final String? idDoubts;
  final String? keyMorphologicalTraits;
  final String? confusingSpecies;
  final String? characteristicFeature;

  final List<HarvestSeason> customHarvestSeasons;

  PlantObservation({
    required this.id,
    this.releveId,
    this.speciesId,
    this.localName,
    this.subspecies,
    this.tempBiologicalType,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
    this.observationDate,
    this.phenologicalStage,
    this.abundance,
    this.coverage,
    this.vitality,
    this.certainty,
    this.idDoubts,
    this.keyMorphologicalTraits,
    this.confusingSpecies,
    this.characteristicFeature,
    this.customHarvestSeasons = const [],
  });

  String get displayName => localName ?? "Nieznana roślina";
  bool get isComplete => observationDate != null && (speciesId != null || localName != null);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'releveId': releveId,
      'speciesId': speciesId,
      'localName': localName,
      'subspecies': subspecies,
      'tempBiologicalType': tempBiologicalType,
      'photoPathsJson': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'characteristicsJson': jsonEncode(characteristics),
      'observationDate': observationDate?.toIso8601String(),
      'phenologicalStage': phenologicalStage,
      'abundance': abundance,
      'coverage': coverage,
      'vitality': vitality,
      'certainty': certainty,
      'idDoubts': idDoubts,
      'keyMorphologicalTraits': keyMorphologicalTraits,
      'confusingSpecies': confusingSpecies,
      'characteristicFeature': characteristicFeature,
      'customHarvestSeasonsJson': jsonEncode(customHarvestSeasons.map((e) => e.toMap()).toList()),
    };
  }

  factory PlantObservation.fromMap(Map<String, dynamic> map) {
    Map<String, List<String>> decodedChars = {};
    if (map['characteristicsJson'] != null) {
      try {
        final rawMap = jsonDecode(map['characteristicsJson']) as Map<String, dynamic>;
        rawMap.forEach((key, value) => decodedChars[key] = List<String>.from(value));
      } catch (e) { print(e); }
    }

    List<HarvestSeason> decodedSeasons = [];
    if (map['customHarvestSeasonsJson'] != null) {
      try {
        final List<dynamic> rawList = jsonDecode(map['customHarvestSeasonsJson']);
        decodedSeasons = rawList.map((e) => HarvestSeason.fromMap(e)).toList();
      } catch (e) { print(e); }
    }

    return PlantObservation(
      id: map['id'] ?? '',
      releveId: map['releveId'],
      speciesId: map['speciesId'],
      localName: map['localName'],
      subspecies: map['subspecies'],
      tempBiologicalType: map['tempBiologicalType'],
      photoPaths: map['photoPathsJson'] != null ? List<String>.from(jsonDecode(map['photoPathsJson'])) : [],
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      characteristics: decodedChars,
      observationDate: map['observationDate'] != null ? DateTime.parse(map['observationDate']) : null,
      phenologicalStage: map['phenologicalStage'],
      abundance: map['abundance'],
      coverage: map['coverage'],
      vitality: map['vitality'],
      certainty: map['certainty'],
      idDoubts: map['idDoubts'],
      keyMorphologicalTraits: map['keyMorphologicalTraits'],
      confusingSpecies: map['confusingSpecies'],
      characteristicFeature: map['characteristicFeature'],
      customHarvestSeasons: decodedSeasons,
    );
  }
}