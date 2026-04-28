// lib/viewmodels/observation_view_model.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/database_helper.dart';
import 'package:uuid/uuid.dart';

class ObservationViewModel extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final DatabaseHelper _db = DatabaseHelper();

  // --- STANY APARATU ---
  List<String> _currentPhotoPaths = [];
  Position? _currentPosition;
  bool _isInitializing = false;

  List<String> get currentPhotoPaths => _currentPhotoPaths;
  bool get canTakePhoto => _currentPhotoPaths.length < 10;
  bool get isInitializing => _isInitializing;
  CameraController? get controller => _cameraService.controller;
  Position? get currentPosition => _currentPosition;

  // --- DANE ---
  List<PlantObservation> _observations = [];
  List<PlantSpecies> _speciesDictionary = [];

  List<PlantObservation> get allObservations => _observations;
  List<PlantSpecies> get speciesDictionary => _speciesDictionary;

  List<PlantObservation> get incompleteObservations => _observations.where((obs) => !obs.isComplete).toList();
  List<PlantObservation> get completeObservations => _observations.where((obs) => obs.isComplete).toList();

  Future<void> loadFromDisk() async {
    _observations = await _db.getObservations();
    // Zostanie aktywowane w Fazie 2:
    // _speciesDictionary = await _db.getSpeciesDictionary();
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

  // GŁÓWNA METODA ZAPISU - ZAPISUJE GATUNEK I OKAZ W TYM SAMYM CZASIE
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
    Map<String, List<int>>? harvestSeasons, // Kalendarz zielarski
  }) async {

    // 1. Generujemy unikalny klucz dla Gatunku (Ghost_Plant)
    final String newSpeciesId = const Uuid().v4();

    // 2. Tworzymy obiekt słownikowy Gatunku
    final species = PlantSpecies(
      speciesID: newSpeciesId, // NOWE: Przypisanie wygenerowanego ID
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
      harvestSeasons: harvestSeasons ?? {},
    );
    // TODO w FAZIE 2: Zapis do tabeli gatunków w DB
    // await _db.insertSpecies(species);

    // 3. Aktualizujemy konkretny OKAZ i łączymy go z nowym gatunkiem
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final old = _observations[index];

      final updatedObs = PlantObservation(
        id: old.id,
        releveId: old.releveId,
        speciesId: newSpeciesId, // NOWE: Przypięcie klucza obcego do okazu!
        localName: localName,
        subspecies: subspecies,
        tempBiologicalType: old.tempBiologicalType,
        photoPaths: old.photoPaths,
        latitude: old.latitude,
        longitude: old.longitude,
        timestamp: old.timestamp,
        characteristics: old.characteristics,
        observationDate: old.observationDate ?? DateTime.now(),
        areaPurity: old.areaPurity,
        abundance: old.abundance,
        coverage: old.coverage,
        vitality: old.vitality,
        certainty: certainty,
        idDoubts: doubts,
        keyMorphologicalTraits: keyTraits,
        confusingSpecies: confusing,
        characteristicFeature: characteristic,
      );

      _observations[index] = updatedObs;
      // Wkrótce (Faza 2) będzie to zapisywać się we właściwych tabelach :)
      await _db.insertObservation(updatedObs);
      notifyListeners();
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