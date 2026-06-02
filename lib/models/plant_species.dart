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

  // --- TRZYSTANOWE MAPY ELLENBERGA (Klucz: liczba wskaźnikowa, Wartość: stan 0, 1 lub 2) ---
  final Map<int, int> ellenbergL; // Światło (1-9)
  final Map<int, int> ellenbergF; // Wilgotność (1-12)
  final Map<int, int> ellenbergR; // Odczyn pH (1-9)
  final Map<int, int> ellenbergN; // Żyzność/Azot (1-9)
  final Map<int, int> ellenbergT; // Temperatura (1-9)
  final Map<int, int> ellenbergK; // Kontynentalizm (1-9)
  final Map<int, int> ellenbergS; // Zasolenie (0-9)

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
    this.ellenbergL = const {},
    this.ellenbergF = const {},
    this.ellenbergR = const {},
    this.ellenbergN = const {},
    this.ellenbergT = const {},
    this.ellenbergK = const {},
    this.ellenbergS = const {},
    this.plantUsage,
    this.cultivation,
    this.properties,
    this.associatedSyntaxa = const [],
    this.harvestSeasons = const [],
  });

  Map<String, dynamic> toMap() {
    // Pakujemy dodatkowe osie (T, K, S, N) do wolnej kolumny associatedSyntaxaJson, by nie uszkodzić struktury DB v20
    final Map<String, dynamic> extraAxes = {
      'T': ellenbergT,
      'K': ellenbergK,
      'S': ellenbergS,
      'N': ellenbergN,
    };

    return {
      'speciesID': speciesID,
      'latinName': latinName,
      'polishName': polishName,
      'family': family,
      'biologicalType': biologicalType,
      'prefPhMin': prefPhMin,
      'prefPhMax': prefPhMax,
      'prefLightLevelsJson': jsonEncode(ellenbergL.map((k, v) => MapEntry(k.toString(), v))),
      'prefWaterDynamicsJson': jsonEncode(ellenbergF.map((k, v) => MapEntry(k.toString(), v))),
      'prefSoilTypesJson': jsonEncode(ellenbergR.map((k, v) => MapEntry(k.toString(), v))),
      'prefAreaTypesJson': jsonEncode(extraAxes),
      'plantUsage': plantUsage,
      'cultivation': cultivation,
      'properties': properties,
      'associatedSyntaxaJson': jsonEncode(associatedSyntaxa),
      'harvestSeasonsJson': jsonEncode(harvestSeasons.map((e) => e.toMap()).toList()),
    };
  }

  factory PlantSpecies.fromMap(Map<String, dynamic> map) {
    Map<int, int> parseEllenbergMap(String? jsonStr) {
      if (jsonStr == null || jsonStr.isEmpty) return {};
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      } catch (_) { return {}; }
    }

    Map<int, int> lMap = parseEllenbergMap(map['prefLightLevelsJson']);
    Map<int, int> fMap = parseEllenbergMap(map['prefWaterDynamicsJson']);
    Map<int, int> rMap = parseEllenbergMap(map['prefSoilTypesJson']);

    Map<int, int> tMap = {};
    Map<int, int> kMap = {};
    Map<int, int> sMap = {};
    Map<int, int> nMap = {};

    if (map['prefAreaTypesJson'] != null) {
      try {
        final Map<String, dynamic> extra = jsonDecode(map['prefAreaTypesJson']);
        Map<int, int> castSubMap(dynamic sub) => (sub as Map).map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));
        if (extra.containsKey('T')) tMap = castSubMap(extra['T']);
        if (extra.containsKey('K')) kMap = castSubMap(extra['K']);
        if (extra.containsKey('S')) sMap = castSubMap(extra['S']);
        if (extra.containsKey('N')) nMap = castSubMap(extra['N']);
      } catch (_) {}
    }

    List<HarvestSeason> decodedSeasons = [];
    if (map['harvestSeasonsJson'] != null) {
      try {
        final List<dynamic> rawList = jsonDecode(map['harvestSeasonsJson']);
        decodedSeasons = rawList.map((e) => HarvestSeason.fromMap(e)).toList();
      } catch (_) {}
    }

    return PlantSpecies(
      speciesID: map['speciesID'] ?? '',
      latinName: map['latinName'] ?? '',
      polishName: map['polishName'] ?? '',
      family: map['family'] ?? '',
      biologicalType: map['biologicalType'] ?? 'Zielne',
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      ellenbergL: lMap,
      ellenbergF: fMap,
      ellenbergR: rMap,
      ellenbergN: nMap,
      ellenbergT: tMap,
      ellenbergK: kMap,
      ellenbergS: sMap,
      plantUsage: map['plantUsage'],
      cultivation: map['cultivation'],
      properties: map['properties'],
      associatedSyntaxa: map['associatedSyntaxaJson'] != null ? List<String>.from(jsonDecode(map['associatedSyntaxaJson'])) : const [],
      harvestSeasons: decodedSeasons,
    );
  }
}