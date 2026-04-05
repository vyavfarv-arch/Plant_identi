import 'package:flutter/material.dart';
import '../models/plant_observation.dart';
import '../services/storage_service.dart';

class PlantsViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PlantObservation> _observations = [];
  DateTime? _filterDate;

  // Filtry nazw dla mapy
  final List<String> _selectedPlantNames = [];

  List<PlantObservation> get allObservations => _observations;
  List<String> get selectedPlantNames => _selectedPlantNames;

  // Lista dla "Opisz Spotkane Rośliny" (tylko niekompletne)
  List<PlantObservation> get incompleteObservations =>
      _observations.where((obs) => !obs.isComplete).toList();

  // Lista dla "Magazynu Roślin" (filtrowanie po dacie)
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

  // Logika dla Mapy: Pusta mapa na start, pokazuje tylko zaznaczone
  List<PlantObservation> get mapFilteredObservations {
    var allComplete = _observations.where((obs) => obs.isComplete).toList();

    if (_selectedPlantNames.isEmpty) {
      return []; // Nic nie wybrano -> nic nie wyświetlamy
    }

    return allComplete.where((obs) =>
        _selectedPlantNames.contains(obs.plantName)).toList();
  }

  // Pobieranie unikalnych nazw do listy filtrów
  List<String> get uniquePlantNames {
    return _observations
        .where((obs) => obs.isComplete && obs.plantName != null)
        .map((obs) => obs.plantName!)
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

  void updateObservation(String id, String name, String abundance, DateTime date) {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      _observations[index].plantName = name;
      _observations[index].abundance = abundance;
      _observations[index].observationDate = date;
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