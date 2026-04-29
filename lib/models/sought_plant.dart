// lib/models/sought_plant.dart
import 'dart:convert';

class SoughtPlant {
  final String id;
  final String polishName;
  final String latinName;

  final double? prefPhMin;
  final double? prefPhMax;
  final List<String> prefSubstrate;
  final double? prefMoisture;
  final double? prefSunlight;

  // NOWE PREFERENCJE
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

  SoughtPlant({
    required this.id, required this.polishName, required this.latinName,
    this.prefPhMin, this.prefPhMax, this.prefSubstrate = const [], this.prefMoisture, this.prefSunlight,

    this.prefAreaTypes = const [], this.prefExposures = const [], this.prefCanopyCovers = const [],
    this.prefWaterDynamics = const [], this.prefSoilDepths = const [], this.prefSlopeAngles = const [],
    this.prefLitterThicknesses = const [], this.prefDistancesToWater = const [], this.prefDeadWood = const [],
    this.prefLandUseHistory = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'polishName': polishName, 'latinName': latinName,
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
  };

  factory SoughtPlant.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(String? jsonStr) => jsonStr != null ? List<String>.from(jsonDecode(jsonStr)) : [];

    return SoughtPlant(
      id: map['id'], polishName: map['polishName'] ?? '', latinName: map['latinName'] ?? '',
      prefPhMin: map['prefPhMin']?.toDouble(), prefPhMax: map['prefPhMax']?.toDouble(),
      prefSubstrate: decodeList(map['prefSubstrateJson']), prefMoisture: map['prefMoisture']?.toDouble(), prefSunlight: map['prefSunlight']?.toDouble(),

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
    );
  }
}