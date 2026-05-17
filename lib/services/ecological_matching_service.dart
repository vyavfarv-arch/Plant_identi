// lib/services/ecological_matching_service.dart
import '../models/releve.dart';
import '../models/plant_species.dart';
import '../models/sought_plant.dart';

class EcologicalMatchingResult {
  final double score;
  final List<String> matchingTraits;
  final List<String> missingTraits;

  EcologicalMatchingResult({
    required this.score,
    required this.matchingTraits,
    required this.missingTraits,
  });

  bool get isPotentialMatch => score >= 0.75;
}

class EcologicalMatchingService {

  /// SYSTEM WAG EKOLOGICZNYCH (Matryca deterministyczna)
  static EcologicalMatchingResult calculateCompatibility({
    required double? prefPhMin,
    required double? prefPhMax,
    required List<String> prefAreaTypes,
    required List<String> prefWaterDynamics,
    required List<String> prefLightLevels,
    required List<String> prefSoilTypes,
    required Releve area,
  }) {
    final h = area.habitat;
    if (h == null) {
      return EcologicalMatchingResult(score: 0.0, matchingTraits: [], missingTraits: ["Obszar nie ma opisu siedliska"]);
    }

    int totalWeight = 0;
    int matchedWeight = 0;

    List<String> matches = [];
    List<String> misses = [];

    // 1. Walidacja Typu Siedliska (WAGA 3 - KRYTYCZNA)
    if (prefAreaTypes.isNotEmpty) {
      totalWeight += 3;
      if (h.areaType != null && prefAreaTypes.contains(h.areaType)) {
        matchedWeight += 3;
        matches.add("Siedlisko: ${h.areaType}");
      } else {
        misses.add("Wymagane siedlisko: ${prefAreaTypes.join(', ')} (jest: ${h.areaType ?? 'brak'})");
      }
    }

    // 2. Walidacja Wilgotności / Dynamiki Wody (WAGA 2 - WYSOKA)
    if (prefWaterDynamics.isNotEmpty) {
      totalWeight += 2;
      if (h.waterDynamics != null && prefWaterDynamics.contains(h.waterDynamics)) {
        matchedWeight += 2;
        matches.add("Gospodarka wodna: ${h.waterDynamics}");
      } else {
        misses.add("Wymagana gospodarka wodna: ${prefWaterDynamics.join(', ')}");
      }
    }

    // 3. Walidacja Naświetlenia / Zwarcie koron (WAGA 2 - WYSOKA)
    if (prefLightLevels.isNotEmpty) {
      totalWeight += 2;
      if (h.canopyCover != null && prefLightLevels.contains(h.canopyCover)) {
        matchedWeight += 2;
        matches.add("Oświetlenie: ${h.canopyCover}");
      } else {
        misses.add("Wymagane oświetlenie: ${prefLightLevels.join(', ')}");
      }
    }

    // 4. Walidacja Struktury Podłoża (WAGA 2 - WYSOKA)
    if (prefSoilTypes.isNotEmpty) {
      totalWeight += 2;
      bool soilMatches = h.substrateType.any((type) => prefSoilTypes.contains(type));
      if (soilMatches) {
        matchedWeight += 2;
        matches.add("Podłoże pasuje do wymagań");
      } else {
        misses.add("Wymagany typ podłoża: ${prefSoilTypes.join(', ')}");
      }
    }

    // 5. Walidacja Odczynu pH (WAGA 2 - WYSOKA)
    if (prefPhMin != null && prefPhMax != null) {
      totalWeight += 2;
      if (h.ph != null) {
        if (h.ph! >= prefPhMin && h.ph! <= prefPhMax) {
          matchedWeight += 2;
          matches.add("Odczyn pH (${h.ph}) w normie");
        } else {
          misses.add("pH poza zakresem $prefPhMin-$prefPhMax (jest: ${h.ph})");
        }
      } else {
        misses.add("Obszar nie ma zbadanego pH gleby");
      }
    }

    double finalScore = totalWeight == 0 ? 1.0 : (matchedWeight / totalWeight);

    return EcologicalMatchingResult(
      score: finalScore,
      matchingTraits: matches,
      missingTraits: misses,
    );
  }

  static List<MapEntry<PlantSpecies, EcologicalMatchingResult>> findPotentialPlantsForArea(
      Releve area, List<PlantSpecies> dictionary) {
    final List<MapEntry<PlantSpecies, EcologicalMatchingResult>> results = [];
    for (var species in dictionary) {
      final match = calculateCompatibility(
        prefPhMin: species.prefPhMin, prefPhMax: species.prefPhMax,
        prefAreaTypes: species.prefAreaTypes, prefWaterDynamics: species.prefWaterDynamics,
        prefLightLevels: species.prefLightLevels, prefSoilTypes: species.prefSoilTypes, area: area,
      );
      if (match.isPotentialMatch) results.add(MapEntry(species, match));
    }
    return results..sort((a, b) => b.value.score.compareTo(a.value.score));
  }

  static List<MapEntry<Releve, EcologicalMatchingResult>> findMatchingAreasForPlant(
      SoughtPlant plant, List<Releve> allReleves) {
    final List<MapEntry<Releve, EcologicalMatchingResult>> results = [];
    for (var area in allReleves) {
      final match = calculateCompatibility(
        prefPhMin: plant.prefPhMin, prefPhMax: plant.prefPhMax,
        prefAreaTypes: plant.prefAreaTypes, prefWaterDynamics: plant.prefWaterDynamics,
        prefLightLevels: plant.prefLightLevels, prefSoilTypes: plant.prefSoilTypes, area: area,
      );
      results.add(MapEntry(area, match));
    }
    return results..sort((a, b) => b.value.score.compareTo(a.value.score));
  }
}