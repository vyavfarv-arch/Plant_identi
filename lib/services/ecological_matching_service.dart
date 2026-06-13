// lib/services/ecological_matching_service.dart
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../models/plant_species.dart';
import '../models/has_ellenberg_profile.dart';

class ContinuousEcologicalProfile {
  final double sunlight;
  final double moisture;
  final double acidity;
  final double nitrogen;
  final double temperature;
  final double continent;
  final double salinity;

  ContinuousEcologicalProfile({
    required this.sunlight,
    required this.moisture,
    required this.acidity,
    required this.nitrogen,
    required this.temperature,
    required this.continent,
    required this.salinity,
  });
}

class AxisPenalty {
  final double value;
  final bool isDefined;
  AxisPenalty(this.value, this.isDefined);
}

class ContinuousEcologicalMatchingResult {
  final double score;
  final Map<String, String> diagnostics;

  ContinuousEcologicalMatchingResult({required this.score, required this.diagnostics});
  bool get isPotentialMatch => score >= 0.75;
}

class AdvancedEcologicalTranslator {
  static ContinuousEcologicalProfile translateArea(HabitatInfo h) {
    double sunlight = 10.0 - h.canopyDensity;
    if (sunlight > 2.0 && h.slopeAngle != "Płaski (0-2°)") {
      if (h.exposure == "S") sunlight += 0.8;
      if (h.exposure == "N") sunlight -= 0.8;
    }

    double moisture = 4.0;
    final context = h.hydrologicalContext ?? "";
    if (context.contains("Skrajnie suche")) moisture = 1.5;
    if (context.contains("Wilgotne")) moisture = 7.0;
    if (context.contains("Mokre")) moisture = 9.0;
    if (context.contains("Stale zalane")) moisture = 11.0;

    final movement = h.waterMovement ?? "";
    if (movement.contains("Stojąca")) moisture += 1.0;
    if (movement.contains("Źródliskowa")) moisture += 0.5;
    if (movement.contains("Płynąca")) moisture += 0.2;

    if (h.substrateType.any((s) => s.contains("Torfowa"))) moisture += 1.5;
    if (h.substrateType.any((s) => s.contains("Gliniasta"))) moisture += 0.4;
    if (h.substrateType.any((s) => s.contains("Piaszczysta"))) moisture -= 1.0;

    double acidity = h.ph ?? 5.5;
    if (h.ph == null) {
      if (h.substrateType.any((s) => s.contains("Torfowa")) && movement.contains("Stojąca")) acidity = 2.5;
      else if (h.substrateType.any((s) => s.contains("Ziemia leśna")) && h.areaType == "Las") acidity = 4.5;
      else if (h.substrateType.any((s) => s.contains("Gliniasta"))) acidity = 6.5;
      if (h.humanImpact == "Składowisko odpadów / Śmietnisko") acidity = 8.0;
    }

    double nitrogen = 3.0;
    final impact = h.humanImpact ?? "";
    if (impact.contains("Śmietnisko")) nitrogen = 8.5;
    else if (impact.contains("Orka")) nitrogen = 7.5;
    else if (impact.contains("Wypas")) nitrogen = 5.0;

    final cover = h.soilSurfaceCover ?? "";
    if (cover.contains("Gruba ściółka")) nitrogen += 0.8;
    if (cover.contains("Zwarta darń")) nitrogen += 1.2;
    if (h.substrateType.any((s) => s.contains("Piaszczysta"))) nitrogen -= 1.0;

    double temperature = 5.0;
    if (sunlight > 6.0 && h.exposure == "S" && h.slopeAngle == "Stromy (>25°)") temperature = 6.5;
    if (h.areaType == "Las" && h.canopyDensity >= 6) temperature -= 1.0;
    if (movement.contains("Stojąca")) temperature -= 0.5;

    double continent = 3.5;
    if (h.canopyDensity <= 2 && (h.areaType == "Pole" || h.areaType == "Łąka")) continent += 0.8;
    if (h.canopyDensity >= 6 && h.areaType == "Las") continent -= 0.5;

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
  static AxisPenalty calculateAxisPenalty(double areaValue, Map<int, int> speciesMap, int minVal, int maxVal) {
    if (speciesMap.isEmpty || !speciesMap.values.any((state) => state > 0)) {
      return AxisPenalty(0.0, false);
    }

    int closestNode = areaValue.round().clamp(minVal, maxVal);
    int directState = speciesMap[closestNode] ?? 0;

    if (directState == 2) return AxisPenalty(0.0, true);
    if (directState == 1) return AxisPenalty(0.15, true);

    double minDistance = double.infinity;
    double penaltyModifier = 1.0;

    speciesMap.forEach((node, state) {
      if (state > 0) {
        double dist = (areaValue - node).abs();
        if (dist < minDistance) {
          minDistance = dist;
          penaltyModifier = (state == 2) ? 0.75 : 1.0;
        }
      }
    });

    if (minDistance == double.infinity) return AxisPenalty(1.0, true);
    double maxPossibleDist = (maxVal - minVal).toDouble();
    return AxisPenalty(((minDistance / maxPossibleDist) * penaltyModifier).clamp(0.0, 1.0), true);
  }

  static ContinuousEcologicalMatchingResult calculateCompatibility(Releve area, HasEllenbergProfile species) {
    if (area.habitat == null) return ContinuousEcologicalMatchingResult(score: 0.0, diagnostics: {});
    final areaProfile = AdvancedEcologicalTranslator.translateArea(area.habitat!);

    final resL = calculateAxisPenalty(areaProfile.sunlight, species.ellenbergL, 1, 9);
    final resF = calculateAxisPenalty(areaProfile.moisture, species.ellenbergF, 1, 12);
    final resR = calculateAxisPenalty(areaProfile.acidity, species.ellenbergR, 1, 9);
    final resN = calculateAxisPenalty(areaProfile.nitrogen, species.ellenbergN, 1, 9);
    final resT = calculateAxisPenalty(areaProfile.temperature, species.ellenbergT, 1, 9);
    final resK = calculateAxisPenalty(areaProfile.continent, species.ellenbergK, 1, 9);
    final resS = calculateAxisPenalty(areaProfile.salinity, species.ellenbergS, 0, 9);

    double sumPenalty = 0.0;
    double maxPenalty = 0.0;
    int activeAxesCount = 0;
    Map<String, String> diagMap = {};

    void processAxisScore(String axisKey, AxisPenalty res) {
      if (res.isDefined) {
        sumPenalty += res.value;
        if (res.value > maxPenalty) maxPenalty = res.value;
        activeAxesCount++;
        diagMap[axisKey] = (res.value <= 0.15) ? "✓" : "✗";
      } else {
        diagMap[axisKey] = "?";
      }
    }

    processAxisScore("L", resL);
    processAxisScore("F", resF);
    processAxisScore("R", resR);
    processAxisScore("N", resN);
    processAxisScore("T", resT);
    processAxisScore("K", resK);
    processAxisScore("S", resS);

    if (activeAxesCount == 0) return ContinuousEcologicalMatchingResult(score: 0.0, diagnostics: diagMap);

    double averagePenalty = sumPenalty / activeAxesCount;
    double combinedPenalty = (averagePenalty * 0.5) + (maxPenalty * 0.5);

    return ContinuousEcologicalMatchingResult(
      score: (1.0 - combinedPenalty).clamp(0.0, 1.0),
      diagnostics: diagMap,
    );
  }

  static bool isSevereMismatch(Releve area, PlantSpecies? species) {
    if (species == null || area.habitat == null) return false;

    if (species.ellenbergL.isEmpty && species.ellenbergF.isEmpty &&
        species.ellenbergR.isEmpty && species.ellenbergN.isEmpty &&
        species.ellenbergT.isEmpty && species.ellenbergK.isEmpty &&
        species.ellenbergS.isEmpty) {
      return false;
    }

    final match = calculateCompatibility(area, species);
    return match.score < 0.55;
  }

  static List<MapEntry<PlantSpecies, ContinuousEcologicalMatchingResult>> findPotentialPlantsForArea(
      Releve area, List<PlantSpecies> dictionary) {
    final List<MapEntry<PlantSpecies, ContinuousEcologicalMatchingResult>> results = [];
    for (var species in dictionary) {
      final match = calculateCompatibility(area, species);
      if (match.isPotentialMatch) {
        results.add(MapEntry(species, match));
      }
    }
    return results..sort((a, b) => b.value.score.compareTo(a.value.score));
  }
}