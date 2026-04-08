import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Wymagane dla LatLng
import '../models/plant_observation.dart';
import '../models/releve.dart';
import '../services/storage_service.dart';
import '../services/phytosociology_service.dart';

class PlantsViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PlantObservation> _observations = [];
  List<Releve> _releves = []; // Lista zdjęć fitosocjologicznych

  DateTime? _filterDate;
  final List<String> _selectedPlantNames = [];

  List<PlantObservation> get allObservations => _observations;
  List<String> get selectedPlantNames => _selectedPlantNames;
  List<Releve> get allReleves => _releves;

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

  List<PlantObservation> get mapFilteredObservations {
    var allComplete = _observations.where((obs) => obs.isComplete).toList();
    if (_selectedPlantNames.isEmpty) return [];
    return allComplete.where((obs) => _selectedPlantNames.contains(obs.displayName)).toList();
  }

  List<String> get uniquePlantNames {
    return _observations
        .where((obs) => obs.isComplete && obs.displayName != "Nieznana roślina")
        .map<String>((obs) => obs.displayName)
        .toSet()
        .toList();
  }

  // GŁÓWNA METODA DODAWANIA (Z AUTOMATYKĄ FITO)
  void addObservation(PlantObservation obs) {
    _observations.add(obs);

    // Automatyczne przypisanie nowej rośliny do istniejących obszarów (kwadratów)
    for (var releve in _releves) {
      if (releve.area.contains(LatLng(obs.latitude, obs.longitude))) {
        if (!releve.plantObservationIds.contains(obs.id)) {
          releve.plantObservationIds.add(obs.id);
          _updateReleveSyntaxon(releve);
        }
      }
    }

    _storage.saveObservations(_observations);
    notifyListeners();
  }

  // Logika przeliczania syntaksonu dla zdjęcia
  void _updateReleveSyntaxon(Releve releve) {
    final areaPlants = _observations.where((o) => releve.plantObservationIds.contains(o.id)).toList();
    final result = PhytosociologyService().calculateBestFit(areaPlants);
    releve.assignedSyntaxonId = result['syntaxonId'];
    releve.isHeterogeneous = result['warning'] != null;
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
  void createReleve(LatLng p1, LatLng p2) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
      ),
      northeast: LatLng(
        p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
      ),
    );

    // Znajdź wszystkie rośliny w tym obszarze
    final plantsInArea = _observations.where((obs) {
      final pos = LatLng(obs.latitude, obs.longitude);
      return bounds.contains(pos);
    }).map((e) => e.id).toList();

    final newReleve = Releve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      area: bounds,
      date: DateTime.now(),
      plantObservationIds: plantsInArea,
    );

    _releves.add(newReleve);

    // Oblicz najlepszy fit syntaksonu (używa Twojej logiki z PhytosociologyService)
    _updateReleveSyntaxon(newReleve);

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