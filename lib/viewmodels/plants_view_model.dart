import 'package:flutter/material.dart';
import '../models/plant_observation.dart';
import '../services/storage_service.dart'; // Dodaj ten import

class PlantsViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService(); // Dodaj serwis
  List<PlantObservation> _observations = [];
  DateTime? _filterDate;

  List<PlantObservation> get allObservations => _observations;

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

  // DODAJ TĘ METODĘ:
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
    _storage.saveObservations(_observations); // Zapisuj przy dodaniu
    notifyListeners();
  }

  void updateObservation(String id, String name, String abundance, DateTime date) {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      _observations[index].plantName = name;
      _observations[index].abundance = abundance;
      _observations[index].observationDate = date;
      _storage.saveObservations(_observations); // Zapisuj przy edycji
      notifyListeners();
    }
  }

  void deleteObservation(String id) {
    _observations.removeWhere((o) => o.id == id);
    _storage.saveObservations(_observations); // Zapisuj przy usuwaniu
    notifyListeners();
  }
}