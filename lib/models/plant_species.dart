// lib/models/plant_species.dart
import 'dart:convert';
import 'harvest_season.dart';
import 'has_ellenberg_profile.dart';

class PlantSpecies implements HasEllenbergProfile {
  final String speciesID;
  final String latinName;
  final String polishName;
  final String family;
  final String biologicalType;

  @override double? prefPhMin;
  @override double? prefPhMax;

  @override final Map<int, int> ellenbergL;
  @override final Map<int, int> ellenbergF;
  @override final Map<int, int> ellenbergR;
  @override final Map<int, int> ellenbergN;
  @override final Map<int, int> ellenbergT;
  @override final Map<int, int> ellenbergK;
  @override final Map<int, int> ellenbergS;

  final String? plantUsage;
  final String? cultivation;
  final String? properties;
  final List<String> associatedSyntaxa;
  final List<HarvestSeason> harvestSeasons;

  @override String get profileId => speciesID;
  @override String get name => polishName;

  PlantSpecies({
    required this.speciesID, required this.latinName, required this.polishName, required this.family, required this.biologicalType,
    this.prefPhMin, this.prefPhMax, this.ellenbergL = const {}, this.ellenbergF = const {}, this.ellenbergR = const {},
    this.ellenbergN = const {}, this.ellenbergT = const {}, this.ellenbergK = const {}, this.ellenbergS = const {},
    this.plantUsage, this.cultivation, this.properties, this.associatedSyntaxa = const [], this.harvestSeasons = const [],
  });

  Map<String, dynamic> toMap() {
    // FIX: Klucze String zapobiegają błędom "Converting object to an encodable object failed"
    final Map<String, dynamic> extraAxes = {
      'T': ellenbergT.map((k, v) => MapEntry(k.toString(), v)),
      'K': ellenbergK.map((k, v) => MapEntry(k.toString(), v)),
      'S': ellenbergS.map((k, v) => MapEntry(k.toString(), v)),
    };

    return {
      'speciesID': speciesID, 'latinName': latinName, 'polishName': polishName, 'family': family, 'biologicalType': biologicalType,
      'prefPhMin': prefPhMin, 'prefPhMax': prefPhMax,
      'prefLightLevelsJson': jsonEncode(ellenbergL.map((k, v) => MapEntry(k.toString(), v))),
      'prefWaterDynamicsJson': jsonEncode(ellenbergF.map((k, v) => MapEntry(k.toString(), v))),
      'prefSoilTypesJson': jsonEncode(ellenbergR.map((k, v) => MapEntry(k.toString(), v))),
      'prefNitrogenJson': jsonEncode(ellenbergN.map((k, v) => MapEntry(k.toString(), v))), // FIX: dedykowana kolumna
      'prefAreaTypesJson': jsonEncode(extraAxes),
      'plantUsage': plantUsage, 'cultivation': cultivation, 'properties': properties,
      'associatedSyntaxaJson': jsonEncode(associatedSyntaxa), 'harvestSeasonsJson': jsonEncode(harvestSeasons.map((e) => e.toMap()).toList()),
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
    Map<int, int> nMap = parseEllenbergMap(map['prefNitrogenJson']);

    Map<int, int> tMap = {};
    Map<int, int> kMap = {};
    Map<int, int> sMap = {};

    if (map['prefAreaTypesJson'] != null) {
      try {
        final Map<String, dynamic> extra = jsonDecode(map['prefAreaTypesJson']);
        Map<int, int> castSubMap(dynamic sub) => (sub as Map).map((k, v) => MapEntry(int.parse(k.toString()), (v as num).toInt()));
        if (extra.containsKey('T')) tMap = castSubMap(extra['T']);
        if (extra.containsKey('K')) kMap = castSubMap(extra['K']);
        if (extra.containsKey('S')) sMap = castSubMap(extra['S']);
      } catch (_) {}
    }

    List<HarvestSeason> decodedSeasons = [];
    if (map['harvestSeasonsJson'] != null) {
      try { decodedSeasons = (jsonDecode(map['harvestSeasonsJson']) as List).map((e) => HarvestSeason.fromMap(e)).toList(); } catch (_) {}
    }

    return PlantSpecies(
      speciesID: map['speciesID'] ?? '', latinName: map['latinName'] ?? '', polishName: map['polishName'] ?? '', family: map['family'] ?? '', biologicalType: map['biologicalType'] ?? 'Zielne',
      prefPhMin: map['prefPhMin']?.toDouble(), prefPhMax: map['prefPhMax']?.toDouble(),
      ellenbergL: lMap, ellenbergF: fMap, ellenbergR: rMap, ellenbergN: nMap, ellenbergT: tMap, ellenbergK: kMap, ellenbergS: sMap,
      plantUsage: map['plantUsage'], cultivation: map['cultivation'], properties: map['properties'],
      associatedSyntaxa: map['associatedSyntaxaJson'] != null ? List<String>.from(jsonDecode(map['associatedSyntaxaJson'])) : const [], harvestSeasons: decodedSeasons,
    );
  }
}