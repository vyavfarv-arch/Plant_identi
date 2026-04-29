// lib/models/plant_species.dart
import 'dart:convert';
import 'harvest_season.dart';

class PlantSpecies {
  final String speciesID;
  final String latinName;
  final String polishName;
  final String family;
  final String biologicalType;

  // --- STARE PREFERENCJE ---
  final double? prefPhMin;
  final double? prefPhMax;
  final List<String> prefSubstrate;
  final double? prefMoisture;
  final double? prefSunlight;

  // --- NOWE PREFERENCJE (Listy akceptowanych warunków) ---
  final List<String> prefAreaTypes;
  final List<String> prefExposures;
  final List<String> prefCanopyCovers;
  final List<String> prefWaterDynamics;
  final List<String> prefSoilDepths;
  final List<String> prefSlopeAngles;
  final List<String> prefLitterThicknesses;
  final List<String> prefDistancesToWater;
  final List<String> prefDeadWood;
  final List<String> prefLandUseHistory;

  // Zastosowanie
  final String? plantUsage;
  final String? cultivation;
  final String? properties;

  // Fitosocjologia i kalendarz
  final List<String> associatedSyntaxa;
  final List<HarvestSeason> harvestSeasons;

  PlantSpecies({
    required this.speciesID, required this.latinName, required this.polishName, required this.family, required this.biologicalType,
    this.prefPhMin, this.prefPhMax, this.prefSubstrate = const [], this.prefMoisture, this.prefSunlight,

    this.prefAreaTypes = const [], this.prefExposures = const [], this.prefCanopyCovers = const [],
    this.prefWaterDynamics = const [], this.prefSoilDepths = const [], this.prefSlopeAngles = const [],
    this.prefLitterThicknesses = const [], this.prefDistancesToWater = const [], this.prefDeadWood = const [],
    this.prefLandUseHistory = const [],

    this.plantUsage, this.cultivation, this.properties,
    this.associatedSyntaxa = const [], this.harvestSeasons = const [],
  });

  Map<String, dynamic> toMap() => {
    'speciesID': speciesID, 'latinName': latinName, 'polishName': polishName, 'family': family, 'biologicalType': biologicalType,
    'prefPhMin': prefPhMin, 'prefPhMax': prefPhMax, 'prefSubstrateJson': jsonEncode(prefSubstrate),
    'prefMoisture': prefMoisture, 'prefSunlight': prefSunlight,

    'prefAreaTypesJson': jsonEncode(prefAreaTypes),
    'prefExposuresJson': jsonEncode(prefExposures),
    'prefCanopyCoversJson': jsonEncode(prefCanopyCovers),
    'prefWaterDynamicsJson': jsonEncode(prefWaterDynamics),
    'prefSoilDepthsJson': jsonEncode(prefSoilDepths),
    'prefSlopeAnglesJson': jsonEncode(prefSlopeAngles),
    'prefLitterThicknessesJson': jsonEncode(prefLitterThicknesses),
    'prefDistancesToWaterJson': jsonEncode(prefDistancesToWater),
    'prefDeadWoodJson': jsonEncode(prefDeadWood),
    'prefLandUseHistoryJson': jsonEncode(prefLandUseHistory),

    'plantUsage': plantUsage, 'cultivation': cultivation, 'properties': properties,
    'associatedSyntaxaJson': jsonEncode(associatedSyntaxa),
    'harvestSeasonsJson': jsonEncode(harvestSeasons.map((e) => e.toMap()).toList()),
  };

  factory PlantSpecies.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(String? jsonStr) => jsonStr != null ? List<String>.from(jsonDecode(jsonStr)) : [];

    List<HarvestSeason> decodedSeasons = [];
    if (map['harvestSeasonsJson'] != null) {
      try {
        final List<dynamic> rawList = jsonDecode(map['harvestSeasonsJson']);
        decodedSeasons = rawList.map((e) => HarvestSeason.fromMap(e)).toList();
      } catch (e) { print(e); }
    }

    return PlantSpecies(
      speciesID: map['speciesID'] ?? '', latinName: map['latinName'] ?? '', polishName: map['polishName'] ?? '',
      family: map['family'] ?? '', biologicalType: map['biologicalType'] ?? 'Zielne',
      prefPhMin: map['prefPhMin']?.toDouble(), prefPhMax: map['prefPhMax']?.toDouble(),
      prefSubstrate: decodeList(map['prefSubstrateJson']),
      prefMoisture: map['prefMoisture']?.toDouble(), prefSunlight: map['prefSunlight']?.toDouble(),

      prefAreaTypes: decodeList(map['prefAreaTypesJson']),
      prefExposures: decodeList(map['prefExposuresJson']),
      prefCanopyCovers: decodeList(map['prefCanopyCoversJson']),
      prefWaterDynamics: decodeList(map['prefWaterDynamicsJson']),
      prefSoilDepths: decodeList(map['prefSoilDepthsJson']),
      prefSlopeAngles: decodeList(map['prefSlopeAnglesJson']),
      prefLitterThicknesses: decodeList(map['prefLitterThicknessesJson']),
      prefDistancesToWater: decodeList(map['prefDistancesToWaterJson']),
      prefDeadWood: decodeList(map['prefDeadWoodJson']),
      prefLandUseHistory: decodeList(map['prefLandUseHistoryJson']),

      plantUsage: map['plantUsage'], cultivation: map['cultivation'], properties: map['properties'],
      associatedSyntaxa: decodeList(map['associatedSyntaxaJson']), harvestSeasons: decodedSeasons,
    );
  }
}