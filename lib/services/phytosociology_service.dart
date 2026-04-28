// lib/services/phytosociology_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/syntaxon.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart'; // DODANO SŁOWNIK

class PhytosociologyService {
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

  List<String> _getAllDiagnosticSpecies(Syntaxon s) {
    List<String> all = List.from(s.characteristicSpecies);
    String? currentParentId = s.parentId;
    Set<String> visitedIds = {s.id};

    while (currentParentId != null) {
      if (visitedIds.contains(currentParentId)) break;
      visitedIds.add(currentParentId);

      final parentIndex = _syntaxaDatabase.indexWhere((element) => element.id == currentParentId);
      if (parentIndex == -1) break;

      final parent = _syntaxaDatabase[parentIndex];
      all.addAll(parent.characteristicSpecies);
      currentParentId = parent.parentId;
    }

    return all.map((e) => e.toLowerCase()).toList();
  }

  // ZMIANA: Przekazujemy listę dictionary, by "odkryć" nazwy łacińskie okazów
  Map<String, dynamic> calculateBestFit(List<PlantObservation> observations, List<PlantSpecies> dictionary) {
    if (observations.isEmpty || !_isLoaded) return {'syntaxonId': null, 'warning': null};

    final uniqueLatinNames = observations.map((o) {
      final specList = dictionary.where((s) => s.speciesID == o.speciesId);
      final spec = specList.isNotEmpty ? specList.first : null;
      return spec?.latinName.trim().toLowerCase();
    }).where((name) => name != null && name.isNotEmpty).cast<String>().toSet();

    Syntaxon? bestFit;
    double highestScore = 0;
    Map<String, double> classScores = {};

    for (var syntaxon in _syntaxaDatabase) {
      final diagSpecies = _getAllDiagnosticSpecies(syntaxon);
      if (diagSpecies.isEmpty) continue;

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