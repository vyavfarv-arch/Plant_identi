// lib/models/sought_plant.dart
import 'dart:convert';
import 'harvest_season.dart';

class SoughtPlant {
  final String id;
  final String polishName;
  final String latinName;
  final double? prefPhMin;
  final double? prefPhMax;
  final List<String> prefAreaTypes;
  final List<String> prefWaterDynamics;
  final List<String> prefLightLevels;
  final List<String> prefSoilTypes;
  final List<HarvestSeason> harvestSeasons;

  SoughtPlant({
    required this.id,
    required this.polishName,
    required this.latinName,
    this.prefPhMin,
    this.prefPhMax,
    this.prefAreaTypes = const [],
    this.prefWaterDynamics = const [],
    this.prefLightLevels = const [],
    this.prefSoilTypes = const [],
    this.harvestSeasons = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'polishName': polishName,
    'latinName': latinName,
    'prefPhMin': prefPhMin,
    'prefPhMax': prefPhMax,
    'prefAreaTypesJson': jsonEncode(prefAreaTypes),
    'prefWaterDynamicsJson': jsonEncode(prefWaterDynamics),
    'prefLightLevelsJson': jsonEncode(prefLightLevels),
    'prefSoilTypesJson': jsonEncode(prefSoilTypes),
    'harvestSeasonsJson': jsonEncode(harvestSeasons.map((e) => e.toMap()).toList()),
  };

  factory SoughtPlant.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(String? jsonStr) => jsonStr != null ? List<String>.from(jsonDecode(jsonStr)) : [];

    List<HarvestSeason> decodedSeasons = [];
    if (map['harvestSeasonsJson'] != null) {
      try {
        final List<dynamic> rawList = jsonDecode(map['harvestSeasonsJson']);
        decodedSeasons = rawList.map((e) => HarvestSeason.fromMap(e)).toList();
      } catch (e) { print(e); }
    }

    return SoughtPlant(
      id: map['id'] ?? '',
      polishName: map['polishName'] ?? '',
      latinName: map['latinName'] ?? '',
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      prefAreaTypes: decodeList(map['prefAreaTypesJson']),
      prefWaterDynamics: decodeList(map['prefWaterDynamicsJson']),
      prefLightLevels: decodeList(map['prefLightLevelsJson']),
      prefSoilTypes: decodeList(map['prefSoilTypesJson']),
      harvestSeasons: decodedSeasons,
    );
  }
}