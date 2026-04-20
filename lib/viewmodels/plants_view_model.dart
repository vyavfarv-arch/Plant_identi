import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';
import '../services/storage_service.dart';
import '../models/habitat_info.dart';


class PlantsViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<PlantObservation> _observations = [];
  List<Releve> _releves = [];
  String _areaSearchQuery = "";
  DateTime? _filterDate;
  final List<String> _selectedPlantNames = [];
  Releve? _filterArea;
  Releve? get filterArea => _filterArea;
  List<PlantObservation> get allObservations => _observations;
  List<String> get selectedPlantNames => _selectedPlantNames;
  List<Releve> get allReleves => _releves;
  DateTimeRange? _filterDateRange;
  DateTimeRange? get filterDateRange => _filterDateRange;

  final List<String> _selectedReleveTypes = ["Zespół", "Związek", "Rząd", "Klasa"];
  final Map<String, Set<String>> _selectedSpecificNames = {};
  List<String> get selectedReleveTypes => _selectedReleveTypes;
  String get areaSearchQuery => _areaSearchQuery;

  List<PlantObservation> get incompleteObservations =>
      _observations.where((obs) => !obs.isComplete).toList();

  List<String> getUniqueNamesForRank(String rank) {
    return _releves
        .where((r) => r.type == rank)
        .map((r) => r.name)
        .toSet()
        .toList();
  }
  bool isNameSelected(String rank, String name) {
    return _selectedSpecificNames[rank]?.contains(name) ?? false;
  }
// Zaktualizowany getter filtrowania
  List<PlantObservation> get filteredCompleteObservations {
    var list = _observations.where((obs) => obs.isComplete).toList();

    // Filtr daty
    if (_filterDateRange != null) {
      list = list.where((obs) {
        final date = obs.observationDate ?? obs.timestamp;
        return date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
            date.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    bool isNameSelected(String rank, String name) {
      return _selectedSpecificNames[rank]?.contains(name) ?? false;
    }

    if (_filterArea != null) {
      list = list.where((obs) =>
          isPointInPolygon(LatLng(obs.latitude, obs.longitude), _filterArea!.points)
      ).toList();
    }

    return list;
  }

  void setFilterArea(Releve? area) {
    _filterArea = area;
    notifyListeners();
  }

// ZAKTUALIZOWANY GETTER FILTROWANIA
  List<Releve> get filteredReleves {
    return _releves.where((r) {
      final matchesType = _selectedReleveTypes.contains(r.type);
      final matchesSearch = _areaSearchQuery.isEmpty ||
          r.name.toLowerCase().contains(_areaSearchQuery.toLowerCase());
      final specificNames = _selectedSpecificNames[r.type] ?? {};
      final matchesSpecific = specificNames.isEmpty || specificNames.contains(r.name);
      return matchesType && matchesSearch && matchesSpecific;
    }).toList();
  }
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

// Pobiera listę roślin znajdujących się w danym obszarze
  List<PlantObservation> getPlantsInReleve(Releve releve) {
    return _observations.where((plant) {
      return isPointInPolygon(LatLng(plant.latitude, plant.longitude), releve.points);
    }).toList();
  }

// Pobiera listę obszarów, w których znajduje się konkretna roślina
  List<Releve> getRelevesForPlant(PlantObservation plant) {
    return _releves.where((releve) {
      return isPointInPolygon(LatLng(plant.latitude, plant.longitude), releve.points);
    }).toList();
  }
  void toggleReleveTypeFilter(String type) {
    if (_selectedReleveTypes.contains(type)) {
      _selectedReleveTypes.remove(type);
    } else {
      _selectedReleveTypes.add(type);
    }
    notifyListeners();
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
  void setAreaSearchQuery(String query) {
    _areaSearchQuery = query;
    notifyListeners();
  }
  void assignParent(String childId, String? parentId) {
    final index = _releves.indexWhere((r) => r.id == childId);
    if (index != -1) {
      _releves[index].parentId = parentId;
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }
  List<Releve> getChildren(String parentId) {
    return _releves.where((r) => r.parentId == parentId).toList();
  }


  // --- ZARZĄDZANIE OBSZARAMI (RELEVE) ---

  // Metoda wywoływana z ReleveMapScreen po wypełnieniu ankiety
  void saveNewReleve(Releve releve) {
    _releves.add(releve);
    _storage.saveReleves(_releves);
    notifyListeners();
  }

  void deleteReleve(String id) {
    _releves.removeWhere((r) => r.id == id);
    _storage.saveReleves(_releves);
    notifyListeners();
  }

  void updateReleve(String id, String newName, String newType) {
    final index = _releves.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _releves[index];
      _releves[index] = Releve(
        id: old.id,
        name: newName,
        type: newType,
        points: old.points,
        date: old.date,
        parentId: old.parentId,
      );
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }
  void updateReleveHabitat(String releveId, HabitatInfo info) {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      _releves[index].habitat = info;
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }
  // --- OBSŁUGA OBSERWACJI ---

  void addObservation(PlantObservation obs) {
    _observations.add(obs);
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
        latinName: latinName,
        phytosociologicalStatus: phytosociologicalStatus,
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

  // --- ŁADOWANIE I FILTROWANIE ---

  Future<void> loadFromDisk() async {
    _observations = await _storage.loadObservations();
    _releves = await _storage.loadReleves();
    notifyListeners();
  }

  void toggleNameFilter(String name) {
    if (_selectedPlantNames.contains(name)) {
      _selectedPlantNames.remove(name);
    } else {
      _selectedPlantNames.add(name);
    }
    notifyListeners();
  }

  void setFilterDateRange(DateTimeRange? range) {
    _filterDateRange = range;
    notifyListeners();
  }

  void deleteObservation(String id) {
    _observations.removeWhere((o) => o.id == id);
    _storage.saveObservations(_observations);
    notifyListeners();
  }
  bool isValidParent(String childType, String parentType) {
    if (childType == "Rząd") return parentType == "Klasa";
    if (childType == "Związek") return parentType == "Rząd";
    if (childType == "Zespół") return parentType == "Związek";
    return false;
  }
  Releve? getParentArea(String? parentId) {
    if (parentId == null) return null;
    try {
      return _releves.firstWhere((r) => r.id == parentId);
    } catch (e) {
      return null;
    }
  }
  List<Releve> getPotentialParents(Releve child) {
    return _releves.where((r) => isValidParent(child.type, r.type)).toList();
  }
  void toggleNameSelection(String rank, String name) {
    _selectedSpecificNames.putIfAbsent(rank, () => {});
    if (_selectedSpecificNames[rank]!.contains(name)) {
      _selectedSpecificNames[rank]!.remove(name);
    } else {
      _selectedSpecificNames[rank]!.add(name);
    }
    notifyListeners();
  }
  void clearAreaSearchQuery() {
    _areaSearchQuery = "";
    notifyListeners();
  }

}