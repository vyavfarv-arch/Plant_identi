// lib/models/plant_species.dart
import 'dart:convert';
import 'harvest_season.dart';

class PlantSpecies {
  final String speciesID;
  final String latinName;
  final String polishName;
  final String family;
  final String biologicalType;

  final double? prefPhMin;
  final double? prefPhMax;

  // NOWA STRUKTURA PREFERENCJI (Biologiczna)
  final List<String> prefAreaTypes;
  final List<String> prefWaterDynamics;
  final List<String> prefLightLevels; // Zamiast zwarcia koron
  final List<String> prefSoilTypes;   // Zamiast podłoża i głębokości

  final String? plantUsage;
  final String? cultivation;
  final String? properties;

  final List<String> associatedSyntaxa;
  final List<HarvestSeason> harvestSeasons;

  PlantSpecies({
    required this.speciesID,
    required this.latinName,
    required this.polishName,
    required this.family,
    required this.biologicalType,
    this.prefPhMin,
    this.prefPhMax,
    this.prefAreaTypes = const [],
    this.prefWaterDynamics = const [],
    this.prefLightLevels = const [],
    this.prefSoilTypes = const [],
    this.plantUsage,
    this.cultivation,
    this.properties,
    this.associatedSyntaxa = const [],
    this.harvestSeasons = const [],
  });

  Map<String, dynamic> toMap() => {
    'speciesID': speciesID,
    'latinName': latinName,
    'polishName': polishName,
    'family': family,
    'biologicalType': biologicalType,
    'prefPhMin': prefPhMin,
    'prefPhMax': prefPhMax,
    'prefAreaTypesJson': jsonEncode(prefAreaTypes),
    'prefWaterDynamicsJson': jsonEncode(prefWaterDynamics),
    'prefLightLevelsJson': jsonEncode(prefLightLevels),
    'prefSoilTypesJson': jsonEncode(prefSoilTypes),
    'plantUsage': plantUsage,
    'cultivation': cultivation,
    'properties': properties,
    'associatedSyntaxaJson': jsonEncode(associatedSyntaxa),
    'harvestSeasonsJson': jsonEncode(harvestSeasons.map((e) => e.toMap()).toList()),
  };

  factory PlantSpecies.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(String? jsonStr) =>
        jsonStr != null ? List<String>.from(jsonDecode(jsonStr)) : [];

    List<HarvestSeason> decodedSeasons = [];
    if (map['harvestSeasonsJson'] != null) {
      try {
        final List<dynamic> rawList = jsonDecode(map['harvestSeasonsJson']);
        decodedSeasons = rawList.map((e) => HarvestSeason.fromMap(e)).toList();
      } catch (e) { print(e); }
    }

    return PlantSpecies(
      speciesID: map['speciesID'] ?? '',
      latinName: map['latinName'] ?? '',
      polishName: map['polishName'] ?? '',
      family: map['family'] ?? '',
      biologicalType: map['biologicalType'] ?? 'Zielne',
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      prefAreaTypes: decodeList(map['prefAreaTypesJson']),
      prefWaterDynamics: decodeList(map['prefWaterDynamicsJson']),
      prefLightLevels: decodeList(map['prefLightLevelsJson']),
      prefSoilTypes: decodeList(map['prefSoilTypesJson']),
      plantUsage: map['plantUsage'],
      cultivation: map['cultivation'],
      properties: map['properties'],
      associatedSyntaxa: decodeList(map['associatedSyntaxaJson']),
      harvestSeasons: decodedSeasons,
    );
  }
}