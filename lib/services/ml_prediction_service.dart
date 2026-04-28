// lib/services/ml_prediction_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/sought_plant.dart'; // ZMIANA MODELU
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

  int _traverseTree(Map<String, dynamic> node, Map<String, double> features) {
    if (node['type'] == 'leaf') {
      return node['value'];
    }
    String featureName = node['feature'];
    double threshold = (node['threshold'] as num).toDouble();
    double featureValue = features[featureName] ?? 0.0;

    if (featureValue <= threshold) {
      return _traverseTree(node['left'], features);
    } else {
      return _traverseTree(node['right'], features);
    }
  }

  Map<String, double> getPlantsForArea(Releve area) {
    if (_modelData == null || area.habitat == null) return {};

    final h = area.habitat!;
    Map<String, double> features = {
      'ph': h.ph ?? 7.0,
      'moisture': h.moisture,
      'sunlight': h.sunlight,
      'pollution': h.pollution,
    };

    for (var sub in h.substrateType) {
      features[sub] = 1.0;
    }

    final List<dynamic> classes = _modelData!['classes'];
    final List<dynamic> forest = _modelData!['forest'];

    Map<int, int> votes = {};
    for (var tree in forest) {
      int predictedClassIndex = _traverseTree(tree, features);
      votes[predictedClassIndex] = (votes[predictedClassIndex] ?? 0) + 1;
    }

    Map<String, double> probabilities = {};
    int totalTrees = forest.length;

    votes.forEach((classIndex, voteCount) {
      if (classIndex >= 0 && classIndex < classes.length) {
        probabilities[classes[classIndex].toString()] = voteCount / totalTrees;
      }
    });

    var sortedEntries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // ZMIANA: Szukamy na podstawie obiektu SoughtPlant
  List<String> getMatchingAreas(SoughtPlant plant, List<Releve> allReleves) {
    if (_modelData == null) return [];

    List<String> matchingIds = [];
    String targetName = plant.latinName.isNotEmpty ? plant.latinName : plant.polishName;

    for (var area in allReleves) {
      if (area.habitat == null) continue;

      final predictions = getPlantsForArea(area);

      double prob = 0.0;
      predictions.forEach((predictedName, value) {
        if (predictedName.toLowerCase().contains(targetName.toLowerCase())) {
          prob = value;
        }
      });

      if (prob > 0.0) {
        matchingIds.add(area.id);
      }
    }

    return matchingIds;
  }
}