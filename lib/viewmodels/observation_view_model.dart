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

  // --- ŁADOWANIE I INICJALIZACJA ---

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

  // --- ZDJĘCIA ---

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

  // --- OPERACJE NA OBSERWACJACH (PRZYWRÓCONE I POPRAWIONE) ---

  // Metoda dodawania, której brakowało w Twoim błędzie
  Future<void> addObservation(PlantObservation obs) async {
    await _db.insertObservation(obs);
    await loadFromDisk();
  }

  // Ulepszone usuwanie: czyści słownik, jeśli to był ostatni okaz gatunku
  Future<void> deleteObservation(String id) async {
    try {
      final obs = _observations.firstWhere((o) => o.id == id);
      final String? sId = obs.speciesId;

      await _db.deleteObservation(id);

      if (sId != null) {
        // Sprawdzamy, czy w bazie są jeszcze inne obserwacje tego gatunku
        final allObs = await _db.getObservations();
        final hasInstances = allObs.any((o) => o.speciesId == sId);

        if (!hasInstances) {
          // Jeśli to był ostatni okaz, usuwamy gatunek ze słownika bazy
          await _db.deleteSpecies(sId);
        }
      }
      await loadFromDisk();
    } catch (e) {
      debugPrint("Błąd podczas usuwania: $e");
    }
  }

  // --- WYSZUKIWANIE ---

  List<String> get allLatinNames => _speciesDictionary.map((s) => s.latinName).where((name) => name.isNotEmpty).toList();

  PlantSpecies? findSpeciesByLatinName(String latinName) {
    try {
      return _speciesDictionary.firstWhere((s) => s.latinName.toLowerCase() == latinName.toLowerCase().trim());
    } catch (_) { return null; }
  }
  PlantSpecies? findSpeciesByPolishName(String polishName) {
    try {
      return _speciesDictionary.firstWhere(
              (s) => s.polishName.toLowerCase() == polishName.toLowerCase().trim()
      );
    } catch (_) { return null; }
  }

  Future<void> addSpecies(PlantSpecies species) async {
    await _db.insertSpecies(species);
    await loadFromDisk(); // Synchronizacja pamięci podręcznej z dyskiem
  }
  PlantSpecies? getSpeciesById(String? speciesId) {
    if (speciesId == null) return null;
    try {
      return _speciesDictionary.firstWhere((s) => s.speciesID == speciesId);
    } catch (_) { return null; }
  }

  List<String> get uniqueFamilies => _speciesDictionary.map((s) => s.family).where((f) => f.isNotEmpty).toSet().toList();

  // --- AKTUALIZACJA SZCZEGÓŁOWA ---

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
    List<HarvestSeason>? harvestSeasons,
    List<HarvestSeason>? customHarvestSeasons,
    List<String>? prefAreaTypes,
    List<String>? prefWaterDynamics,
    List<String>? prefLightLevels,
    List<String>? prefSoilTypes,
  }) async {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index == -1) return;
    final old = _observations[index];
    final String targetSpeciesId = old.speciesId ?? const Uuid().v4();

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
      harvestSeasons: harvestSeasons ?? [],
      prefAreaTypes: prefAreaTypes ?? [],
      prefWaterDynamics: prefWaterDynamics ?? [],
      prefLightLevels: prefLightLevels ?? [],
      prefSoilTypes: prefSoilTypes ?? [],
    );
    await _db.insertSpecies(species);

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
      customHarvestSeasons: customHarvestSeasons ?? [],
    );

    await _db.insertObservation(updatedObs);
    await loadFromDisk();
  }
  // lib/viewmodels/observation_view_model.dart

  Future<void> updateObservationCoordinates(String id, double lat, double lng) async {
    try {
      final index = _observations.indexWhere((o) => o.id == id);
      if (index == -1) return;
      final old = _observations[index];

      final updatedObs = PlantObservation(
        id: old.id,
        releveId: old.releveId,
        speciesId: old.speciesId,
        localName: old.localName,
        subspecies: old.subspecies,
        tempBiologicalType: old.tempBiologicalType,
        photoPaths: old.photoPaths,
        latitude: lat, // Nowa szerokość
        longitude: lng, // Nowa długość
        timestamp: old.timestamp,
        characteristics: old.characteristics,
        observationDate: old.observationDate,
        phenologicalStage: old.phenologicalStage,
        abundance: old.abundance,
        coverage: old.coverage,
        vitality: old.vitality,
        certainty: old.certainty,
        idDoubts: old.idDoubts,
        keyMorphologicalTraits: old.keyMorphologicalTraits,
        confusingSpecies: old.confusingSpecies,
        characteristicFeature: old.characteristicFeature,
        customHarvestSeasons: old.customHarvestSeasons,
      );

      _observations[index] = updatedObs;
      await _db.insertObservation(updatedObs); // Nadpisanie rekordu w bazie przez ConflictAlgorithm.replace
      await loadFromDisk();
    } catch (e) {
      debugPrint("Błąd podczas zmiany lokalizacji okazu: $e");
    }
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