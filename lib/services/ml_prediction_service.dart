// lib/services/ml_prediction_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';

class MlPredictionService {
  Map<String, dynamic>? _modelData;

  Future<void> loadModel() async {
    try {
      final String response = await rootBundle.loadString('assets/forest_model.json');
      _modelData = json.decode(response);
    } catch (e) {
      print("Błąd ładowania modelu: $e");
    }
  }

  /// Przechodzi rekursywnie przez węzły pojedynczego drzewa decyzyjnego
  int _traverseTree(Map<String, dynamic> node, Map<String, double> features) {
    // Jeśli dotarliśmy do liścia, zwracamy wartość (index klasy)
    if (node['type'] == 'leaf') {
      return node['value'];
    }

    // Pobierz informacje o węźle decyzyjnym
    String featureName = node['feature'];
    double threshold = (node['threshold'] as num).toDouble();

    // Pobierz wartość danej cechy siedliska (0.0 jeśli brak np. dla One-Hot Encoded)
    double featureValue = features[featureName] ?? 0.0;

    // Przejdź w lewo lub w prawo zależnie od warunku
    if (featureValue <= threshold) {
      return _traverseTree(node['left'], features);
    } else {
      return _traverseTree(node['right'], features);
    }
  }

  /// MODUŁ 1: Zwraca prawdopodobieństwa gatunków dla danego obszaru
  Map<String, double> getPlantsForArea(Releve area) {
    if (_modelData == null || area.habitat == null) return {};

    final h = area.habitat!;

    // Mapowanie cech (Features) by odpowiadały kluczom w JSON.
    Map<String, double> features = {
      'ph': h.ph ?? 7.0, // Domyślnie neutralne, jeśli puste
      'moisture': h.moisture,
      'sunlight': h.sunlight,
      'pollution': h.pollution,
    };

    // One-hot encoding dla typów podłoży (python exportuje jako poszczególne feature_names np. 'Torf')
    for (var sub in h.substrateType) {
      features[sub] = 1.0;
    }

    final List<dynamic> classes = _modelData!['classes'];
    final List<dynamic> forest = _modelData!['forest'];

    // Głosowanie drzew (Suma głosów dla indeksu klasy)
    Map<int, int> votes = {};
    for (var tree in forest) {
      int predictedClassIndex = _traverseTree(tree, features);
      votes[predictedClassIndex] = (votes[predictedClassIndex] ?? 0) + 1;
    }

    // Zamiana głosów na prawdopodobieństwa (nazwaGatunku : %)
    Map<String, double> probabilities = {};
    int totalTrees = forest.length;

    votes.forEach((classIndex, voteCount) {
      if (classIndex >= 0 && classIndex < classes.length) {
        probabilities[classes[classIndex].toString()] = voteCount / totalTrees;
      }
    });

    // Sortowanie wyników od najwyższego do najniższego prawdopodobieństwa
    var sortedEntries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// MODUŁ 2: Zwraca obszary, w których może występować dana roślina
  List<String> getMatchingAreas(PlantObservation plant, List<Releve> allReleves) {
    if (_modelData == null) return [];

    List<String> matchingIds = [];
    String targetName = plant.latinName ?? plant.localName ?? "";

    for (var area in allReleves) {
      if (area.habitat == null) continue;

      // Pytamy model: Jakie rośliny tu występują?
      final predictions = getPlantsForArea(area);

      // Sprawdzamy, czy szukana roślina jest na liście wyników algorytmu
      double prob = 0.0;
      predictions.forEach((predictedName, value) {
        if (predictedName.toLowerCase().contains(targetName.toLowerCase())) {
          prob = value;
        }
      });

      // Zwraca obszar jako "zmatchowany", jeśli drzewa oddały na tę roślinę min. 1 głos (prob > 0.0)
      if (prob > 0.0) {
        matchingIds.add(area.id);
      }
    }

    return matchingIds;
  }
}