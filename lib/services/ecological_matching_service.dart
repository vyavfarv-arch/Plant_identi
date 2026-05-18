// lib/services/ecological_matching_service.dart
import 'dart:math';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../models/plant_species.dart';
import '../models/sought_plant.dart';

/// Klasa reprezentująca znormalizowany profil ekologiczny (skala 0.0 - 4.0)
class EcologicalProfile {
  final double sunlight;    // 0 = pełen cień, 4 = pełne słońce
  final double moisture;    // 0 = skrajnie sucho, 4 = mokradło
  final double nitrogen;    // 0 = skrajnie ubogie, 4 = bardzo żyzne
  final double disturbance; // 0 = nienaruszone, 4 = silna antropopresja
  final double temperature; // 0 = bardzo chłodne, 4 = ciepłe

  EcologicalProfile({
    required this.sunlight,
    required this.moisture,
    required this.nitrogen,
    required this.disturbance,
    required this.temperature,
  });
}

/// Klasa reprezentująca zakres tolerancji gatunku na dane czynniki
class EcologicalRange {
  final double min;
  final double max;

  EcologicalRange(this.min, this.max);

  double get mid => (min + max) / 2.0;
  double get tolerance => (max - min) / 2.0 == 0 ? 0.5 : (max - min) / 2.0;

  /// Matematyczna funkcja odległości ekologicznej
  double calculatePenalty(double areaValue) {
    if (areaValue >= min && areaValue <= max) return 0.0; // Idealnie w zakresie tolerancji
    final distance = areaValue < min ? min - areaValue : areaValue - max;
    return distance / 4.0; // Normalizacja kary do przedziału 0.0 - 1.0 (bo max odległość to 4.0)
  }
}

/// Wynik porównania matrycy indeksów ekologicznych
class EcologicalMatchingResult {
  final double score;              // Współczynnik zgodności 0.0 - 1.0 (0% - 100%)
  final List<String> matchingTraits;
  final List<String> missingTraits;

  EcologicalMatchingResult({
    required this.score,
    required this.matchingTraits,
    required this.missingTraits,
  });

  bool get isPotentialMatch => score >= 0.75;
}
class EcologicalTranslator {

  /// TRANSLACJA OBSZARU: Konwersja HabitatInfo na EcologicalProfile (0.0 - 4.0)
  static EcologicalProfile translateArea(HabitatInfo h) {
    // 1. INDEKS ŚWIATŁA (sunlightIndex)
    double sunlight = 2.0; // Punkt wyjścia
    if (h.canopyCover != null) {
      if (h.canopyCover!.contains("Otwarte")) sunlight = 4.0;
      else if (h.canopyCover!.contains("Półotwarte")) sunlight = 2.5;
      else if (h.canopyCover!.contains("Zacienione")) sunlight = 1.0;
      else if (h.canopyCover!.contains("Gęste")) sunlight = 0.0;
    }
    // Modyfikacja ekspozycją stoku dla obszarów z dostępem światła
    if (sunlight > 1.0 && h.exposure != null) {
      if (h.exposure == "S") sunlight += 0.5;
      if (h.exposure == "N") sunlight -= 1.0;
    }

    // 2. INDEKS WILGOTNOŚCI (moistureIndex)
    // Mapowanie surowego suwaka chwilowego (0-3) na bazę indeksu
    double moisture = h.moisture * 1.33; // 0.0 -> 0.0, 3.0 -> 4.0
    if (h.waterDynamics != null) {
      if (h.waterDynamics == "Stale wilgotne") moisture += 0.5;
      if (h.waterDynamics == "Sezonowo zalewane") moisture += 1.0;
      if (h.waterDynamics == "Sezonowo wysychające") moisture -= 0.5;
      if (h.waterDynamics == "Stale suche") moisture = min(moisture, 1.0);
    }
    if (h.substrateType.contains("Glina")) moisture += 0.3;
    if (h.substrateType.contains("Piasek")) moisture -= 0.5;
    if (h.substrateType.contains("Torf")) moisture += 0.6;
    if (h.distanceToWater == "Do 5m") moisture += 0.8;

    // 3. INDEKS AZOTU / ŻYZNOŚCI (nitrogenIndex)
    double nitrogen = 2.0;
    if (h.areaType != null) {
      if (h.areaType == "Pole") nitrogen = 3.5;
      if (h.areaType == "Pobocze drogi") nitrogen = 3.0;
      if (h.areaType == "Ugór") nitrogen = 2.5;
      if (h.areaType == "Las") nitrogen = 1.8;
      if (h.areaType == "Mokradło") nitrogen = 1.2;
    }
    if (h.litterThickness == "Gruba (>10cm)") nitrogen += 0.5;
    if (h.litterThickness == "Brak") nitrogen -= 0.5;
    if (h.substrateType.contains("Piasek")) nitrogen -= 0.7;

    // 4. INDEKS ZABURZENIA SŁOWISKA (disturbanceIndex)
    double disturbance = 1.0;
    if (h.areaType != null) {
      if (h.areaType == "Pole") disturbance = 4.0;
      if (h.areaType == "Pobocze drogi") disturbance = 3.5;
      if (h.areaType == "Ugór") disturbance = 2.8;
      if (h.areaType == "Łąka") disturbance = 1.8;
      if (h.areaType == "Las" || h.areaType == "Mokradło") disturbance = 0.3;
    }

    // 5. INDEKS TEMPERATURY (temperatureIndex)
    double temperature = 2.0; // Klimat umiarkowany
    if (h.exposure == "S") temperature += 0.5;
    if (h.exposure == "N") temperature -= 0.5;
    if (h.canopyCover != null && h.canopyCover!.contains("Gęste")) temperature -= 0.4; // Mikroklimat leśny
    if (h.areaType == "Mokradło") temperature -= 0.3; // Gleby zimne

    return EcologicalProfile(
      sunlight: sunlight.clamp(0.0, 4.0),
      moisture: moisture.clamp(0.0, 4.0),
      nitrogen: nitrogen.clamp(0.0, 4.0),
      disturbance: disturbance.clamp(0.0, 4.0),
      temperature: temperature.clamp(0.0, 4.0),
    );
  }

  /// TRANSLACJA GATUNKU: Przekształcenie kryteriów wybiórczości na zakresy tolerancji
  static Map<String, EcologicalRange> translateSpecies({
    required List<String> lightLevels,
    required List<String> waterDynamics,
    required List<String> soilTypes,
    required List<String> areaTypes,
  }) {
    // Domyślne pełne zakresy tolerancji (brak ograniczeń)
    double sMin = 0.0, sMax = 4.0;
    double mMin = 0.0, mMax = 4.0;
    double nMin = 0.0, nMax = 4.0;
    double dMin = 0.0, dMax = 4.0;

    // Światło
    if (lightLevels.isNotEmpty) {
      if (lightLevels.contains("Otwarte")) { sMin = 3.0; sMax = 4.0; }
      else if (lightLevels.contains("Częściowo otwarte")) { sMin = 2.0; sMax = 3.5; }
      else if (lightLevels.contains("Częściowo zacienione")) { sMin = 1.0; sMax = 2.5; }
      else if (lightLevels.contains("Zacienione")) { sMin = 0.0; sMax = 1.5; }
    }

    // Wilgotność
    if (waterDynamics.isNotEmpty) {
      if (waterDynamics.contains("Stale suche")) { mMin = 0.0; mMax = 1.5; }
      else if (waterDynamics.contains("Sezonowo wysychające")) { mMin = 1.0; mMax = 2.5; }
      else if (waterDynamics.contains("Stale wilgotne")) { mMin = 2.0; mMax = 3.5; }
      else if (waterDynamics.contains("Sezonowo zalewane")) { mMin = 3.0; mMax = 4.0; }
    }

    // Żyzność (Azot) na podstawie typu gleby i siedliska
    if (soilTypes.isNotEmpty) {
      if (soilTypes.contains("Czarnoziem") || soilTypes.contains("Gliniasta")) { nMin = 2.5; nMax = 4.0; }
      else if (soilTypes.contains("Próchniczna")) { nMin = 2.0; nMax = 3.5; }
      else if (soilTypes.contains("Torfowa")) { nMin = 1.0; nMax = 2.5; }
      else if (soilTypes.contains("Piaszczysta") || soilTypes.contains("Kamienista")) { nMin = 0.0; nMax = 1.5; }
    }

    // Antropopresja (Zaburzenia)
    if (areaTypes.isNotEmpty) {
      if (areaTypes.contains("Pole") || areaTypes.contains("Pobocze")) { dMin = 3.0; dMax = 4.0; }
      else if (areaTypes.contains("Ugór") || areaTypes.contains("Skraj lasu")) { dMin = 1.5; dMax = 3.5; }
      else if (areaTypes.contains("Las") || areaTypes.contains("Mokradło")) { dMin = 0.0; dMax = 1.8; }
    }

    return {
      'sunlight': EcologicalRange(sMin, sMax),
      'moisture': EcologicalRange(mMin, mMax),
      'nitrogen': EcologicalRange(nMin, nMax),
      'disturbance': EcologicalRange(dMin, dMax),
      'temperature': EcologicalRange(1.0, 3.5), // Standardowy zakres umiarkowany dla flory PL
    };
  }
}
class EcologicalMatchingService {

  /// MATEMATYCZNY RDZEŃ: Wylicza odchylenie punktu od optimum tolerancji gatunku
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

    // 1. Translacja obszaru na wektor indeksów
    final areaProfile = EcologicalTranslator.translateArea(h);

    // 2. Translacja preferencji gatunku na zakresy tolerancji
    final speciesRanges = EcologicalTranslator.translateSpecies(
      lightLevels: prefLightLevels,
      waterDynamics: prefWaterDynamics,
      soilTypes: prefSoilTypes,
      areaTypes: prefAreaTypes,
    );

    // 3. Obliczanie matematycznych kar za wykroczenie poza optimum amplitude
    double pSun = speciesRanges['sunlight']!.calculatePenalty(areaProfile.sunlight);
    double pMoi = speciesRanges['moisture']!.calculatePenalty(areaProfile.moisture);
    double pNit = speciesRanges['nitrogen']!.calculatePenalty(areaProfile.nitrogen);
    double pDis = speciesRanges['disturbance']!.calculatePenalty(areaProfile.disturbance);
    double pTem = speciesRanges['temperature']!.calculatePenalty(areaProfile.temperature);

    // Dodatkowa tradycyjna walidacja chemiczna dla pH gleby
    double pPh = 0.0;
    if (prefPhMin != null && prefPhMax != null && h.ph != null) {
      if (h.ph! < prefPhMin) pPh = ((prefPhMin - h.ph!) / 4.0).clamp(0.0, 1.0);
      if (h.ph! > prefPhMax) pPh = ((h.ph! - prefPhMax) / 4.0).clamp(0.0, 1.0);
    }

    // Wyliczenie średniej arytmetycznej kar ekologicznych
    double averagePenalty = (pSun + pMoi + pNit + pDis + pTem + pPh) / 6.0;
    double finalScore = 1.0 - averagePenalty;

    // Budowanie komunikatów diagnostycznych dla użytkownika (UX)
    List<String> matches = [];
    List<String> misses = [];

    _evalResult("Światło", pSun, areaProfile.sunlight, matches, misses);
    _evalResult("Wilgotność", pMoi, areaProfile.moisture, matches, misses);
    _evalResult("Żyzność (N)", pNit, areaProfile.nitrogen, matches, misses);
    _evalResult("Zaburzenie", pDis, areaProfile.disturbance, matches, misses);
    if (h.ph != null) _evalResult("Odczyn pH", pPh, h.ph!, matches, misses);

    return EcologicalMatchingResult(
      score: finalScore.clamp(0.0, 1.0),
      matchingTraits: matches,
      missingTraits: misses,
    );
  }

  static void _evalResult(String label, double penalty, double val, List<String> matches, List<String> misses) {
    if (penalty == 0.0) {
      matches.add("$label w normie optimum (Indeks: ${val.toStringAsFixed(1)})");
    } else {
      misses.add("$label poza zakresem (Odchylenie, Indeks: ${val.toStringAsFixed(1)})");
    }
  }

  /// KIERUNEK A: Jakie rośliny mogą urosnąć w tym płacie?
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

  /// KIERUNEK B: W jakich płatach szukać danej rośliny?
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