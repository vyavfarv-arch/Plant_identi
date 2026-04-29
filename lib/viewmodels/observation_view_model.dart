// lib/viewmodels/observation_view_model.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../models/harvest_season.dart';
import '../services/database_helper.dart';

class ObservationViewModel extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final DatabaseHelper _db = DatabaseHelper();

  List<String> _currentPhotoPaths = [];
  Position? _currentPosition;
  bool _isInitializing = false;

  List<String> get currentPhotoPaths => _currentPhotoPaths;
  bool get canTakePhoto => _currentPhotoPaths.length < 10;
  bool get isInitializing => _isInitializing;
  CameraController? get controller => _cameraService.controller;
  Position? get currentPosition => _currentPosition;

  List<PlantObservation> _observations = [];
  List<PlantSpecies> _speciesDictionary = [];

  List<PlantObservation> get allObservations => _observations;
  List<PlantSpecies> get speciesDictionary => _speciesDictionary;

  List<PlantObservation> get incompleteObservations => _observations.where((obs) => !obs.isComplete).toList();
  List<PlantObservation> get completeObservations => _observations.where((obs) => obs.isComplete).toList();

  // --- LOGIKA INTELIGENTNEGO WYSZUKIWANIA I AUTO-UZUPEŁNIANIA ---

  List<String> get allLatinNames {
    return _speciesDictionary.map((s) => s.latinName).where((name) => name.isNotEmpty).toList();
  }

  PlantSpecies? findSpeciesByLatinName(String latinName) {
    try {
      return _speciesDictionary.firstWhere(
              (s) => s.latinName.toLowerCase() == latinName.toLowerCase().trim()
      );
    } catch (e) {
      return null;
    }
  }

  PlantSpecies? getSpeciesById(String? speciesId) {
    if (speciesId == null) return null;
    try {
      return _speciesDictionary.firstWhere((s) => s.speciesID == speciesId);
    } catch (e) {
      return null;
    }
  }

  List<String> get uniquePlantNames {
    return _speciesDictionary.map((s) => s.polishName.isNotEmpty ? s.polishName : s.latinName).toSet().toList();
  }

  List<String> get uniqueFamilies {
    return _speciesDictionary.map((s) => s.family).where((f) => f.isNotEmpty).toSet().toList();
  }

  // --- ŁADOWANIE BAZY DANYCH ---

  Future<void> loadFromDisk() async {
    _observations = await _db.getObservations();
    _speciesDictionary = await _db.getSpecies();
    notifyListeners();
  }

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();
    try {
      await _cameraService.initCamera();
      _currentPosition = await _locationService.getCurrentLocation();
    } catch (e) {
      debugPrint("Błąd inicjalizacji: $e");
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    if (!canTakePhoto) return;
    final path = await _cameraService.takePicture();
    if (path != null) {
      _currentPhotoPaths.add(path);
      if (_currentPhotoPaths.length == 1) {
        _currentPosition = await _locationService.getCurrentLocation();
      }
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    _currentPhotoPaths.removeAt(index);
    notifyListeners();
  }

  Future<void> addObservation(PlantObservation obs) async {
    await _db.insertObservation(obs);
    await loadFromDisk();
  }

  Future<void> deleteObservation(String id) async {
    await _db.deleteObservation(id);
    await loadFromDisk();
  }

  Future<void> updateObservationDetailed({
    required String id,
    required String localName,
    required String latinName,
    required String family,
    String? biologicalType,
    String? subspecies,
    String? certainty,
    String? doubts,
    String? keyTraits,
    String? confusing,
    String? characteristic,
    String? usage,
    String? cultivation,
    double? prefPhMin,
    double? prefPhMax,
    double? prefMoisture,
    double? prefSunlight,
    List<String>? prefSubstrate,
    // ZMIANA: Listy kalendarzy zamiast mapy
    List<HarvestSeason>? harvestSeasons,
    List<HarvestSeason>? customHarvestSeasons,
    // NOWE LISTY Z UI
    List<String>? prefAreaTypes,
    List<String>? prefExposures,
    List<String>? prefCanopyCovers,
    List<String>? prefWaterDynamics,
    List<String>? prefSoilDepths,
  }) async {

    final index = _observations.indexWhere((o) => o.id == id);
    if (index == -1) return;
    final old = _observations[index];

    final String targetSpeciesId = old.speciesId ?? const Uuid().v4();

    // 1. Zapisujemy gatunek (Wiedza teoretyczna)
    final species = PlantSpecies(
      speciesID: targetSpeciesId,
      latinName: latinName,
      polishName: localName,
      family: family,
      biologicalType: biologicalType ?? "Zielne",
      plantUsage: usage,
      cultivation: cultivation,
      prefPhMin: prefPhMin,
      prefPhMax: prefPhMax,
      prefSubstrate: prefSubstrate ?? [],
      prefMoisture: prefMoisture,
      prefSunlight: prefSunlight,
      harvestSeasons: harvestSeasons ?? [], // Przekazujemy listę kalendarzy domyślnych
      prefAreaTypes: prefAreaTypes ?? [],
      prefExposures: prefExposures ?? [],
      prefCanopyCovers: prefCanopyCovers ?? [],
      prefWaterDynamics: prefWaterDynamics ?? [],
      prefSoilDepths: prefSoilDepths ?? [],
    );
    await _db.insertSpecies(species);

    // 2. Aktualizujemy konkretny OKAZ (Stan faktyczny w terenie)
    final updatedObs = PlantObservation(
      id: old.id,
      releveId: old.releveId,
      speciesId: targetSpeciesId,
      localName: localName,
      subspecies: subspecies,
      tempBiologicalType: old.tempBiologicalType,
      photoPaths: old.photoPaths,
      latitude: old.latitude,
      longitude: old.longitude,
      timestamp: old.timestamp,
      characteristics: old.characteristics,
      observationDate: old.observationDate ?? DateTime.now(),
      phenologicalStage: old.phenologicalStage,
      abundance: old.abundance,
      coverage: old.coverage,
      vitality: old.vitality,
      certainty: certainty,
      idDoubts: doubts,
      keyMorphologicalTraits: keyTraits,
      confusingSpecies: confusing,
      characteristicFeature: characteristic,
      customHarvestSeasons: customHarvestSeasons ?? [], // Przekazujemy ew. indywidualny kalendarz
    );

    _observations[index] = updatedObs;
    await _db.insertObservation(updatedObs);
    await loadFromDisk();
  }

  void reset() {
    _currentPhotoPaths = [];
    _currentPosition = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}