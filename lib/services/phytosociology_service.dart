import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/syntaxon.dart';
import '../models/plant_observation.dart';

class PhytosociologyService {
  // Singleton pattern
  static final PhytosociologyService _instance = PhytosociologyService._internal();
  factory PhytosociologyService() => _instance;
  PhytosociologyService._internal();

  List<Syntaxon> _syntaxaDatabase = [];
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString('assets/syntaxa.json');
      final List<dynamic> data = json.decode(response);
      _syntaxaDatabase = data.map((json) => Syntaxon.fromJson(json)).toList();
      _isLoaded = true;
    } catch (e) {
      print("Błąd ładowania bazy syntaksonów: $e");
    }
  }

  // Funkcja zwracająca pełną listę gatunków (własne + rodzica)
  List<String> _getAllDiagnosticSpecies(Syntaxon s) {
    List<String> all = List.from(s.characteristicSpecies);
    String? currentParentId = s.parentId;
    Set<String> visitedIds = {s.id};

    while (currentParentId != null) {

      if (visitedIds.contains(currentParentId)) {
        print("UWAGA: Wykryto cykl w hierarchii syntaksonów dla ID: $currentParentId");
        break; // Przerywamy pętlę
      }
      visitedIds.add(currentParentId);

      final parentIndex = _syntaxaDatabase.indexWhere((element) => element.id == currentParentId);

      if (parentIndex == -1) {
        print("UWAGA: Brakujący rodzic w bazie syntaksonów o ID: $currentParentId");
        break; // Przerywamy pętlę, ratując aplikację przed crashem
      }

      final parent = _syntaxaDatabase[parentIndex];
      all.addAll(parent.characteristicSpecies);
      currentParentId = parent.parentId;
    }

    return all.map((e) => e.toLowerCase()).toList();
  }
  Map<String, dynamic> calculateBestFit(List<PlantObservation> observations) {
    if (observations.isEmpty || !_isLoaded) return {'syntaxonId': null, 'warning': null};

    final uniqueLatinNames = observations
        .map((o) => o.latinName?.trim().toLowerCase())
        .where((name) => name != null)
        .cast<String>()
        .toSet();

    Syntaxon? bestFit;
    double highestScore = 0;
    Map<String, double> classScores = {};

    for (var syntaxon in _syntaxaDatabase) {
      final diagSpecies = _getAllDiagnosticSpecies(syntaxon);
      if (diagSpecies.isEmpty) continue;

      // Liczymy trafienia (tutaj charakterystyczne mają priorytet)
      int found = uniqueLatinNames.where((n) => diagSpecies.contains(n)).length;
      double score = found / diagSpecies.length;

      if (score > highestScore) {
        highestScore = score;
        bestFit = syntaxon;
      }

      if (syntaxon.rank == SyntaxonRank.klasa && score > 0.1) {
        classScores[syntaxon.name] = score;
      }
    }

    String? warning;
    var highClasses = classScores.entries.where((e) => e.value > 0.3).toList();
    if (highClasses.length > 1) {
      warning = "Obszar niejednorodny: wykryto klasy ${highClasses.map((e) => e.key).join(' i ')}";
    }

    return {
      'syntaxonId': bestFit?.id,
      'warning': warning,
      'score': highestScore
    };
  }
}