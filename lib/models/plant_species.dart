// lib/models/plant_species.dart
import 'dart:convert';

class PlantSpecies {
  final String speciesID;
  final String latinName; // Klucz główny
  final String polishName;
  final String family;
  final String biologicalType;

  // Preferencje Środowiskowe (Algorytmy ML)
  final double? prefPhMin;
  final double? prefPhMax;
  final List<String> prefSubstrate;
  final double? prefMoisture;
  final double? prefSunlight;

  // Zastosowanie
  final String? plantUsage;
  final String? cultivation;
  final String? properties;

  // Fitosocjologia
  final List<String> associatedSyntaxa;

  // Kalendarz zbiorów zielarskich
  final Map<String, List<int>> harvestSeasons;

  PlantSpecies({
    required this.speciesID,
    required this.latinName,
    required this.polishName,
    required this.family,
    required this.biologicalType,
    this.prefPhMin,
    this.prefPhMax,
    this.prefSubstrate = const [],
    this.prefMoisture,
    this.prefSunlight,
    this.plantUsage,
    this.cultivation,
    this.properties,
    this.associatedSyntaxa = const [],
    this.harvestSeasons = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'latinName': latinName,
      'polishName': polishName,
      'speciesID' : speciesID,
      'family': family,
      'biologicalType': biologicalType,
      'prefPhMin': prefPhMin,
      'prefPhMax': prefPhMax,
      'prefSubstrateJson': jsonEncode(prefSubstrate),
      'prefMoisture': prefMoisture,
      'prefSunlight': prefSunlight,
      'plantUsage': plantUsage,
      'cultivation': cultivation,
      'properties': properties,
      'associatedSyntaxaJson': jsonEncode(associatedSyntaxa),
      'harvestSeasonsJson': jsonEncode(harvestSeasons),
    };
  }

  factory PlantSpecies.fromMap(Map<String, dynamic> map) {
    Map<String, List<int>> decodedHarvest = {};
    if (map['harvestSeasonsJson'] != null) {
      try {
        final rawMap = jsonDecode(map['harvestSeasonsJson']) as Map<String, dynamic>;
        rawMap.forEach((key, value) {
          decodedHarvest[key] = List<int>.from(value);
        });
      } catch (e) {
        print("Błąd dekodowania kalendarza zbiorów: $e");
      }
    }

    return PlantSpecies(
      latinName: map['latinName'] ?? '',
      speciesID: map['speciesID'] ?? '',
      polishName: map['polishName'] ?? '',
      family: map['family'] ?? '',
      biologicalType: map['biologicalType'] ?? 'Zielne',
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      prefSubstrate: map['prefSubstrateJson'] != null ? List<String>.from(jsonDecode(map['prefSubstrateJson'])) : [],
      prefMoisture: map['prefMoisture']?.toDouble(),
      prefSunlight: map['prefSunlight']?.toDouble(),
      plantUsage: map['plantUsage'],
      cultivation: map['cultivation'],
      properties: map['properties'],
      associatedSyntaxa: map['associatedSyntaxaJson'] != null ? List<String>.from(jsonDecode(map['associatedSyntaxaJson'])) : [],
      harvestSeasons: decodedHarvest,
    );
  }
}