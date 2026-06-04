// lib/services/identification_assistant_service.dart
import '../models/plant_species.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';
import 'ecological_matching_service.dart';

class SuggestionResult {
  final PlantSpecies species;
  final double morphologicalScore;
  final double ecologicalScore;
  double get totalScore => (morphologicalScore * 0.6) + (ecologicalScore * 0.4);

  SuggestionResult({
    required this.species,
    required this.morphologicalScore,
    required this.ecologicalScore,
  });
}

class IdentificationAssistantService {
  // 1. SILNIK DETEKCJI ANOMALII
  static List<String> checkAnomalies(PlantObservation obs, PlantSpecies? species) {
    if (species == null || species.patternTraits.isEmpty) return [];
    List<String> anomalies = [];

    obs.characteristics.forEach((category, selectedTraits) {
      if (species.patternTraits.containsKey(category)) {
        final allowedTraits = species.patternTraits[category]!;
        for (var trait in selectedTraits) {
          if (!allowedTraits.contains(trait)) {
            anomalies.add("[$category]: Wykryto '$trait' (Wzorzec dopuszcza: ${allowedTraits.join(', ')})");
          }
        }
      }
    });
    return anomalies;
  }

  // 2. SILNIK SUGEROWANIA GATUNKÓW (ASYSTENT)
  static List<SuggestionResult> getSuggestions({
    required Map<String, List<String>> currentTraits,
    required Releve? activeArea,
    required List<PlantSpecies> speciesDictionary,
  }) {
    if (currentTraits.isEmpty && activeArea == null) return [];
    List<SuggestionResult> suggestions = [];

    for (var species in speciesDictionary) {
      if (species.patternTraits.isEmpty) continue;

      int matchingTraitsCount = 0;
      int totalTraitsCount = 0;

      currentTraits.forEach((category, traits) {
        if (species.patternTraits.containsKey(category)) {
          final patternList = species.patternTraits[category]!;
          for (var t in traits) {
            totalTraitsCount++;
            if (patternList.contains(t)) {
              matchingTraitsCount++;
            }
          }
        }
      });

      double morphScore = totalTraitsCount > 0 ? (matchingTraitsCount / totalTraitsCount) : 0.0;
      double ecoScore = 0.0;

      if (activeArea != null && activeArea.habitat != null) {
        final match = EcologicalMatchingService.calculateCompatibility(activeArea, species);
        ecoScore = match.score;
      }

      if (morphScore > 0.1 || ecoScore > 0.5) {
        suggestions.add(SuggestionResult(
          species: species,
          morphologicalScore: morphScore,
          ecologicalScore: ecoScore,
        ));
      }
    }

    return suggestions..sort((a, b) => b.totalScore.compareTo(a.totalScore));
  }
}