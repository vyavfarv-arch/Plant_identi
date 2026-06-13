// lib/models/sought_plant.dart
import 'dart:convert';
import 'harvest_season.dart';
import 'has_ellenberg_profile.dart'; // Import wymaganego interfejsu
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Reprezentuje encję rośliny poszukiwanej przez użytkownika za pomocą matrycy ekologicznej.
 * Zawiera preferowane "widełki" pH oraz cyfrowe, trzystanowe mapy 7 indeksów Ellenberga.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku 'harvest_season.dart':
 * - Klasa [HarvestSeason]: Wykorzystywana do obsługi listy preferowanych terminów
 * zbioru surowca oraz ich serializacji do formatu JSON.
 * * Z pliku 'has_ellenberg_profile.dart':
 * - Interfejs [HasEllenbergProfile]: Implementowany przez klasę [SoughtPlant],
 * co gwarantuje polimorfizm i możliwość obliczania kar w EcologicalMatchingService.
 * ============================================================================
 */
class SoughtPlant implements HasEllenbergProfile {
  final String id;
  final String polishName;
  final String latinName;

  @override final double? prefPhMin;
  @override final double? prefPhMax;

  // --- TRZYSTANOWE CYFROWE MAPY INDEKSÓW ELLENBERGA ---
  @override final Map<int, int> ellenbergL; // Światło
  @override final Map<int, int> ellenbergF; // Wilgotność
  @override final Map<int, int> ellenbergR; // Odczyn pH
  @override final Map<int, int> ellenbergN; // Żyzność / Azot
  @override final Map<int, int> ellenbergT; // Temperatura
  @override final Map<int, int> ellenbergK; // Kontynentalizm
  @override final Map<int, int> ellenbergS; // Zasolenie

  final List<HarvestSeason> harvestSeasons;

  // Mapowanie właściwości gettera interfejsu
  @override String get profileId => id;
  @override String get name => polishName;

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
    // Pakujemy osie dodatkowe (T, K, S) do dodatkowej kolumny bez uszkadzania DB
    final Map<String, dynamic> extraAxes = {
      'T': ellenbergT.map((k, v) => MapEntry(k.toString(), v)),
      'K': ellenbergK.map((k, v) => MapEntry(k.toString(), v)),
      'S': ellenbergS.map((k, v) => MapEntry(k.toString(), v)),
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
      'prefNitrogenJson': jsonEncode(ellenbergN.map((k, v) => MapEntry(k.toString(), v))), // Wydzielona oś Azotu N
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
    Map<int, int> nMap = parseEllenbergMap(map['prefNitrogenJson']); // Bezpośredni odczyt Azotu

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
      ellenbergL: lMap,
      ellenbergF: fMap,
      ellenbergR: rMap,
      ellenbergN: nMap,
      ellenbergT: tMap,
      ellenbergK: kMap,
      ellenbergS: sMap,
      harvestSeasons: decodedSeasons,
    );
  }
}