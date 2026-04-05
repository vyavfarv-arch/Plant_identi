import 'package:flutter/material.dart';
import '../models/plant_observation.dart';

class PlantsViewModel extends ChangeNotifier {
  final List<PlantObservation> _observations = [];

  List<PlantObservation> get allObservations => _observations;

  // Pobiera tylko te, które wymagają jeszcze opisu
  List<PlantObservation> get incompleteObservations =>
      _observations.where((obs) => !obs.isComplete).toList();

  void addObservation(PlantObservation observation) {
    _observations.add(observation);
    notifyListeners();
  }

  void updateObservation(String id, String name, String abundance, DateTime date) {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      _observations[index].plantName = name;
      _observations[index].abundance = abundance;
      _observations[index].observationDate = date;
      notifyListeners();
    }
  }
}