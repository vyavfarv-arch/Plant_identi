// lib/viewmodels/observation_view_model.dart
import 'package:flutter/material.dart';
import '../models/plant_observation.dart';
import '../services/storage_service.dart';

class ObservationViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PlantObservation> _observations = [];

  List<PlantObservation> get allObservations => _observations;
  List<PlantObservation> get completeObservations =>
      _observations.where((obs) => obs.isComplete).toList();

  void addObservation(PlantObservation obs) {
    _observations.add(obs);
    _storage.saveObservations(_observations);
    notifyListeners();
  }

// Tutaj trafią metody: updateObservationDetailed, deleteObservation...
}