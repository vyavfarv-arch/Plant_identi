import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';
import '../services/storage_service.dart';
import '../services/phytosociology_service.dart';

class PlantsViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PlantObservation> _observations = [];
  List<Releve> _releves = [];
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

  // --- LOGIKA RELEVE (ZDJĘĆ FITOSOCJOLOGICZNYCH) ---
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1;
    bool oddNodes = false;
    double x = point.longitude;
    double y = point.latitude;

    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude < y && polygon[j].latitude >= y ||
          polygon[j].latitude < y && polygon[i].latitude >= y) &&
          (polygon[i].longitude <= x || polygon[j].longitude <= x)) {
        if (polygon[i].longitude + (y - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) * (polygon[j].longitude - polygon[i].longitude) < x) {
          oddNodes = !oddNodes;
        }
      }
      j = i;
    }
    return oddNodes;
  }
  void createReleve(List<LatLng> points) {
    if (points.length < 3) return;

    final plantsInArea = _observations.where((obs) =>
        _isPointInPolygon(LatLng(obs.latitude, obs.longitude), points)
    ).map((e) => e.id).toList();

    final newReleve = Releve(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      polygon: List.from(points),
      date: DateTime.now(),
      plantObservationIds: plantsInArea,
    );

    _releves.add(newReleve);
    _updateReleveSyntaxon(newReleve);
    notifyListeners();
  }

  void _updateReleveSyntaxon(Releve releve) {
    final areaPlants = _observations.where((o) => releve.plantObservationIds.contains(o.id)).toList();
    final result = PhytosociologyService().calculateBestFit(areaPlants);
    releve.assignedSyntaxonId = result['syntaxonId'];
    releve.isHeterogeneous = result['warning'] != null;
  }

  // --- OBSŁUGA OBSERWACJI ---

  void addObservation(PlantObservation obs) {
    _observations.add(obs);

    // Automatyczne przypisanie nowej rośliny do istniejących obszarów fito
    for (var releve in _releves) {
      if (releve.polygon.contains(LatLng(obs.latitude, obs.longitude))) {
        if (!releve.plantObservationIds.contains(obs.id)) {
          releve.plantObservationIds.add(obs.id);
          _updateReleveSyntaxon(releve);
        }
      }
    }

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
    String? latinName,
    String? phytosociologicalStatus,
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
        observationDate: old.observationDate,
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

  // --- FILTROWANIE ---

  void toggleNameFilter(String name) {
    if (_selectedPlantNames.contains(name)) {
      _selectedPlantNames.remove(name);
    } else {
      _selectedPlantNames.add(name);
    }
    notifyListeners();
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  Future<void> loadFromDisk() async {
    _observations = await _storage.loadObservations();
    notifyListeners();
  }

  void deleteObservation(String id) {
    _observations.removeWhere((o) => o.id == id);
    _storage.saveObservations(_observations);
    notifyListeners();
  }
}