// lib/services/ecological_matching_service.dart
import 'dart:math';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../models/plant_species.dart';
import '../models/sought_plant.dart';

class ContinuousEcologicalProfile {
  final double sunlight;   // L
  final double moisture;   // F
  final double acidity;    // R
  final double nitrogen;   // N
  final double temperature;// T
  final double continent;  // K
  final double salinity;   // S

  ContinuousEcologicalProfile({
    required this.sunlight, required this.moisture, required this.acidity,
    required this.nitrogen, required this.temperature, required this.continent,
    required this.salinity,
  });
}

class AdvancedEcologicalTranslator {

  static ContinuousEcologicalProfile translateArea(HabitatInfo h) {
    // 1. L - ŚWIATŁO (Zmienione na bezpośrednią 9-stopniową mikro-skalę okapu)
    double sunlight = 10.0 - h.canopyDensity; // Inwersja: gęstość 1 -> Światło 9, gęstość 9 -> Światło 1
    if (sunlight > 2.0 && h.slopeAngle != "Płaski (0-2°)") {
      if (h.exposure == "S") sunlight += 0.8;
      if (h.exposure == "N") sunlight -= 0.8;
    }

    // 2. F - WILGOTNOŚĆ (Reżim hydrologiczny zamiast suwaka chwilowego)
    double moisture = 4.0; // Baza: Świeże
    final context = h.hydrologicalContext ?? "";
    if (context.contains("Skrajnie suche")) moisture = 1.5;
    if (context.contains("Wilgotne")) moisture = 7.0;
    if (context.contains("Mokre")) moisture = 9.0;
    if (context.contains("Stale zalane")) moisture = 11.0;

    final movement = h.waterMovement ?? "";
    if (movement.contains("Stojąca")) moisture += 1.0;
    if (movement.contains("Źródliskowa")) moisture += 0.5;

    if (h.substrateType.any((s) => s.contains("Torfowa"))) moisture += 1.5;
    if (h.substrateType.any((s) => s.contains("Gliniasta"))) moisture += 0.4;
    if (h.substrateType.any((s) => s.contains("Piaszczysta"))) moisture -= 1.0;

    // 3. R - ODCZYN pH
    double acidity = h.ph ?? 5.5; // Priorytet dla pomiaru kwasomierza
    if (h.ph == null) {
      if (h.substrateType.any((s) => s.contains("Torfowa")) && movement.contains("Stojąca")) acidity = 2.5;
      else if (h.substrateType.any((s) => s.contains("Ziemia leśna")) && h.areaType == "Las") acidity = 4.5;
      else if (h.substrateType.any((s) => s.contains("Gliniasta"))) acidity = 6.5;
      if (h.humanImpact == "Składowisko odpadów / Śmietnisko") acidity = 8.0;
    }

    // 4. N - ŻYZNOŚĆ GLEBY (Skojarzona z okrywą darniową/liściową)
    double nitrogen = 3.0;
    final impact = h.humanImpact ?? "";
    if (impact.contains("Śmietnisko")) nitrogen = 8.5;
    else if (impact.contains("Orka")) nitrogen = 7.5;
    else if (impact.contains("Wypas")) nitrogen = 5.0;

    final cover = h.soilSurfaceCover ?? "";
    if (cover.contains("Gruba ściółka")) nitrogen += 0.8;
    if (cover.contains("Zwarta darń")) nitrogen += 1.2;
    if (h.substrateType.any((s) => s.contains("Piaszczysta"))) nitrogen -= 1.0;

    // 5. T - TEMPERATURA STANOWISKA
    double temperature = 5.0;
    if (sunlight > 6.0 && h.exposure == "S" && h.slopeAngle == "Stromy (>25°)") temperature = 6.5;
    if (h.areaType == "Las" && h.canopyDensity >= 6) temperature -= 1.0;
    if (movement.contains("Stojąca")) temperature -= 0.5;

    // 6. K - KONTYNENTALIZM MIKROKLIMATU
    double continent = 3.5;
    if (h.canopyDensity <= 2 && (h.areaType == "Pole" || h.areaType == "Łąka")) continent += 0.8;
    if (h.canopyDensity >= 6 && h.areaType == "Las") continent -= 0.5;

    // 7. S - ZASOLENIE ANTROPOGENICZNE
    double salinity = 0.0;
    if (impact.contains("Zimowe solenie") || h.areaType == "Pobocze drogi") salinity = 2.5;

    return ContinuousEcologicalProfile(
      sunlight: sunlight.clamp(1.0, 9.0),
      moisture: moisture.clamp(1.0, 12.0),
      acidity: acidity.clamp(1.0, 9.0),
      nitrogen: nitrogen.clamp(1.0, 9.0),
      temperature: temperature.clamp(1.0, 9.0),
      continent: continent.clamp(1.0, 9.0),
      salinity: salinity.clamp(0.0, 9.0),
    );
  }
}

class EcologicalMatchingService {

  // MATEMATYCZNY KOSTIUM DYSTANSU: Liczy odchylenie od optimum na podstawie wag trzystanowych
  static double calculateAxisPenalty(double areaValue, Map<int, int> speciesMap, int minVal, int maxVal) {
    if (speciesMap.isEmpty || !speciesMap.values.any((state) => state > 0)) {
      return 0.0; // Brak zdefiniowanych ograniczeń = brak kary
    }

    int closestNode = areaValue.round().clamp(minVal, maxVal);
    int directState = speciesMap[closestNode] ?? 0;

    if (directState == 2) return 0.0;  // Idealne trafienie w zdefiniowane Optimum
    if (directState == 1) return 0.15; // Stan tolerowany (roślina przeżyje, drobne upośledzenie wagowe)

    // Stan wyjściowy = 0 (Brak tolerancji). Szukamy najbliższego akceptowalnego punktu
    double minDistance = double.infinity;
    double penaltyModifier = 1.0;

    speciesMap.forEach((node, state) {
      if (state > 0) {
        double dist = (areaValue - node).abs();
        if (dist < minDistance) {
          minDistance = dist;
          penaltyModifier = (state == 2) ? 0.75 : 1.0; // Jeśli graniczy z optimum, spadek kary jest łagodniejszy
        }
      }
    });

    if (minDistance == double.infinity) return 1.0;
    double maxPossibleDist = (maxVal - minVal).toDouble();
    return ((minDistance / maxPossibleDist) * penaltyModifier).clamp(0.0, 1.0);
  }

  static ContinuousEcologicalMatchingResult calculateCompatibility(Releve area, PlantSpecies species) {
    if (area.habitat == null) return ContinuousEcologicalMatchingResult(score: 0.0);

    final areaProfile = AdvancedEcologicalTranslator.translateArea(area.habitat!);

    double pL = calculateAxisPenalty(areaProfile.sunlight, species.ellenbergL, 1, 9);
    double pF = calculateAxisPenalty(areaProfile.moisture, species.ellenbergF, 1, 12);
    double pR = calculateAxisPenalty(areaProfile.acidity, species.ellenbergR, 1, 9);
    double pN = calculateAxisPenalty(areaProfile.nitrogen, species.ellenbergN, 1, 9);
    double pT = calculateAxisPenalty(areaProfile.temperature, species.ellenbergT, 1, 9);
    double pK = calculateAxisPenalty(areaProfile.continent, species.ellenbergK, 1, 9);
    double pS = calculateAxisPenalty(areaProfile.salinity, species.ellenbergS, 0, 9);

    double averagePenalty = (pL + pF + pR + pN + pT + pK + pS) / 7.0;
    return ContinuousEcologicalMatchingResult(score: (1.0 - averagePenalty).clamp(0.0, 1.0));
  }
}

class ContinuousEcologicalMatchingResult {
  final double score;
  ContinuousEcologicalMatchingResult({required this.score});
  bool get isPotentialMatch => score >= 0.75;
}