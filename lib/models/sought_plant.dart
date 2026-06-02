// lib/models/sought_plant.dart
import 'dart:convert';
import 'harvest_season.dart';

class SoughtPlant {
  final String id;
  final String polishName;
  final String latinName;
  final double? prefPhMin;
  final double? prefPhMax;

  // --- TRZYSTANOWE MAPY INDEKSÓW ELLENBERGA ---
  final Map<int, int> ellenbergL;
  final Map<int, int> ellenbergF;
  final Map<int, int> ellenbergR;
  final Map<int, int> ellenbergN;
  final Map<int, int> ellenbergT;
  final Map<int, int> ellenbergK;
  final Map<int, int> ellenbergS;

  final List<HarvestSeason> harvestSeasons;

  SoughtPlant({
    required this.id,
    required this.polishName,
    required this.latinName,
    this.prefPhMin,
    this.prefPhMax,
    this.ellenbergL = const {},
    this.ellenbergF = const {},
    this.ellenbergR = const {},
    this.ellenbergN = const {},
    this.ellenbergT = const {},
    this.ellenbergK = const {},
    this.ellenbergS = const {},
    this.harvestSeasons = const [],
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> extraAxes = {
      'T': ellenbergT, 'K': ellenbergK, 'S': ellenbergS, 'N': ellenbergN,
    };
    return {
      'id': id,
      'polishName': polishName,
      'latinName': latinName,
      'prefPhMin': prefPhMin,
      'prefPhMax': prefPhMax,
      'prefLightLevelsJson': jsonEncode(ellenbergL.map((k, v) => MapEntry(k.toString(), v))),
      'prefWaterDynamicsJson': jsonEncode(ellenbergF.map((k, v) => MapEntry(k.toString(), v))),
      'prefSoilTypesJson': jsonEncode(ellenbergR.map((k, v) => MapEntry(k.toString(), v))),
      'prefAreaTypesJson': jsonEncode(extraAxes),
      'harvestSeasonsJson': jsonEncode(harvestSeasons.map((e) => e.toMap()).toList()),
    };
  }

  factory SoughtPlant.fromMap(Map<String, dynamic> map) {
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

    return SoughtPlant(
      id: map['id'] ?? '',
      polishName: map['polishName'] ?? '',
      latinName: map['latinName'] ?? '',
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      ellenbergL: lMap, ellenbergF: fMap, ellenbergR: rMap,
      ellenbergN: nMap, ellenbergT: tMap, ellenbergK: kMap, ellenbergS: sMap,
      harvestSeasons: decodedSeasons,
    );
  }
}