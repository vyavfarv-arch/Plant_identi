// lib/services/ml_prediction_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';

class MlPredictionService {
  Map<String, dynamic>? _modelData;

  /// Wczytuje forest_model.json z assetów
  Future<void> loadModel() async {
    try {
      final String response = await rootBundle.loadString('assets/forest_model.json');
      _modelData = json.decode(response);
    } catch (e) {
      print("Błąd ładowania modelu: $e");
    }
  }

  /// Prosty algorytm dopasowania (symulujący Random Forest)
  List<String> getMatchingAreas(PlantObservation plant, List<Releve> allReleves) {
    List<String> matchingIds = [];

    for (var area in allReleves) {
      if (area.habitat == null) continue;
      final habitat = area.habitat!;

      double score = 0.0;

      // 1. Dopasowanie pH
      if (plant.prefPhMin != null && plant.prefPhMax != null && habitat.ph != null) {
        if (habitat.ph! >= plant.prefPhMin! && habitat.ph! <= plant.prefPhMax!) {
          score += 0.4;
        }
      }

      // 2. Dopasowanie podłoża
      if (plant.prefSubstrate.isNotEmpty) {
        final matches = habitat.substrateType.any((s) => plant.prefSubstrate.contains(s));
        if (matches) score += 0.3;
      }

      // 3. Dopasowanie wilgotności
      if (plant.prefMoisture != null) {
        if ((habitat.moisture - plant.prefMoisture!).abs() <= 1) {
          score += 0.3;
        }
      }

      // Jeśli suma wag przekracza próg (np. 60%)
      if (score >= 0.6) {
        matchingIds.add(area.id);
      }
    }

    return matchingIds;
  }
}