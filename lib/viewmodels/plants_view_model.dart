import 'package:flutter/material.dart';
import '../models/plant_observation.dart';
import '../services/storage_service.dart';

class PlantsViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PlantObservation> _observations = [];
  DateTime? _filterDate;

  final List<String> _selectedPlantNames = [];

  List<PlantObservation> get allObservations => _observations;
  List<String> get selectedPlantNames => _selectedPlantNames;

  List<PlantObservation> get incompleteObservations =>
      _observations.where((obs) => !obs.isComplete).toList();

  List<PlantObservation> get filteredCompleteObservations {
    var list = _observations.where((obs) => obs.isComplete).toList();
    if (_filterDate != null) {
      list = list.where((obs) =>
      obs.observationDate!.year == _filterDate!.year &&
          obs.observationDate!.month == _filterDate!.month &&
          obs.observationDate!.day == _filterDate!.day
      ).toList();
    }
    return list;
  }

  // Logika dla Mapy: Pokaż tylko te, których nazwa (displayName) jest zaznaczona
  List<PlantObservation> get mapFilteredObservations {
    var allComplete = _observations.where((obs) => obs.isComplete).toList();
    if (_selectedPlantNames.isEmpty) return [];
    return allComplete.where((obs) => _selectedPlantNames.contains(obs.displayName)).toList();
  }

  List<String> get uniquePlantNames {
    return _observations
        .where((obs) => obs.isComplete && obs.displayName != "Nieznana roślina")
        .map<String>((obs) => obs.displayName) // Jawne rzutowanie na String
        .toSet()
        .toList();
  }

  void toggleNameFilter(String name) {
    if (_selectedPlantNames.contains(name)) {
      _selectedPlantNames.remove(name);
    } else {
      _selectedPlantNames.add(name);
    }
    notifyListeners();
  }

  Future<void> loadFromDisk() async {
    _observations = await _storage.loadObservations();
    notifyListeners();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void addObservation(PlantObservation observation) {
    _observations.add(observation);
    _storage.saveObservations(_observations);
    notifyListeners();
  }

  void updateObservationDetailed({
    required String id,
    String? family,
    String? genus,
    String? species,
    String? subspecies,
    String? localName,
    String? certainty,
    String? doubts,
    String? keyTraits,
    String? confusing,
    String? characteristic,
    String? usage,
    String? cultivation,
  }) {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final old = _observations[index];
      _observations[index] = PlantObservation(
        id: old.id,
        photoPaths: old.photoPaths,
        latitude: old.latitude,
        longitude: old.longitude,
        timestamp: old.timestamp,
        characteristics: old.characteristics,
        biologicalType: old.biologicalType,
        phytosociologicalLayer: old.phytosociologicalLayer,
        abundance: old.abundance,
        coverage: old.coverage,
        vitality: old.vitality,
        sociability: old.sociability,
        observationDate: old.observationDate, // Zachowujemy datę z terenu
        family: family,
        genus: genus,
        species: species,
        subspecies: subspecies,
        localName: localName,
        certainty: certainty,
        idDoubts: doubts,
        keyMorphologicalTraits: keyTraits,
        confusingSpecies: confusing,
        characteristicFeature: characteristic,
        plantUsage: usage,
        cultivation: cultivation,
      );
      _storage.saveObservations(_observations);
      notifyListeners();
    }
  }
  void deleteObservation(String id) {
    _observations.removeWhere((o) => o.id == id);
    _storage.saveObservations(_observations);
    notifyListeners();
  }
}