// lib/services/ml_prediction_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/releve.dart';

class MlPredictionService {
  Map<String, dynamic>? _model;

  // Wczytanie modelu z pliku wygenerowanego w Pythonie
  Future<void> loadModel() async {
    final String response = await rootBundle.loadString('assets/forest_model.json');
    _model = json.decode(response);
  }

  // GŁÓWNA LOGIKA: Ocena obszaru
  // Zwraca mapę: { "Nazwa Rośliny": Prawdopodobieństwo 0.0 - 1.0 }
  Map<String, double> predictPlantsForArea(Releve area) {
    if (_model == null || area.habitat == null) return {};

    final habitat = area.habitat!;
    final List<String> classes = List<String>.from(_model!['classes']);

    Map<String, double> scores = {};
    for (var plant in classes) {
      scores[plant] = 0.0;
    }

    // PROSTY ALGORYTM DOPASOWANIA (Na czas rozbudowy Random Forest w Pythonie)
    // Docelowo tutaj będziemy iterować po drzewach decyzyjnych z JSON-a
    for (var plantName in classes) {
      double match = 0.0;

      // Przykład logiki: dopasowanie pH i wilgotności
      // W wersji docelowej Python wygeneruje tu konkretne progi (if moisture > 2.5...)
      match += 0.5; // bazowe prawdopodobieństwo

      scores[plantName] = match.clamp(0.0, 1.0);
    }

    return scores;
  }
}