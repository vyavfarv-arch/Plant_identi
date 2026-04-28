import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../models/plant_observation.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/database_helper.dart';

class ObservationViewModel extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final DatabaseHelper _db = DatabaseHelper();

  // --- LOGIKA TWORZENIA NOWEJ OBSERWACJI ---
  List<String> _currentPhotoPaths = [];
  Position? _currentPosition;
  bool _isInitializing = false;

  List<String> get currentPhotoPaths => _currentPhotoPaths;
  bool get canTakePhoto => _currentPhotoPaths.length < 10; // Limit 10 zdjęć
  bool get isInitializing => _isInitializing;
  CameraController? get controller => _cameraService.controller;
  Position? get currentPosition => _currentPosition;

  // --- LOGIKA ZARZĄDZANIA BAZĄ OBSERWACJI ---
  List<PlantObservation> _observations = [];

  List<PlantObservation> get allObservations => _observations;

  List<PlantObservation> get incompleteObservations =>
      _observations.where((obs) => !obs.isComplete).toList();

  List<PlantObservation> get completeObservations =>
      _observations.where((obs) => obs.isComplete).toList();

  // Pobieranie unikalnych nazw i rodzin do filtrów (później trafi do SearchFilterVM)
  List<String> get uniquePlantNames => _observations
      .where((obs) => obs.isComplete && obs.displayName != "Nieznana roślina")
      .map((obs) => obs.displayName)
      .toSet()
      .toList();

  List<String> get uniqueFamilies => _observations
      .where((obs) => obs.family != null && obs.family!.isNotEmpty)
      .map((obs) => obs.family!)
      .toSet()
      .toList();

  // --- METODY ---

  Future<void> loadFromDisk() async {
    _observations = await _db.getObservations(); // Pobranie listy z SQLite
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
    String? family,
    String? subspecies,
    String? localName,
    String? latinName,
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
  }) async {
    final index = _observations.indexWhere((o) => o.id == id);
    if (index != -1) {
      final old = _observations[index];

      final updatedObs = PlantObservation(
        id: old.id,
        photoPaths: old.photoPaths,
        latitude: old.latitude,
        releveId: old.releveId,
        longitude: old.longitude,
        timestamp: old.timestamp,
        characteristics: old.characteristics,
        biologicalType: old.biologicalType,
        areaPurity: old.areaPurity,
        abundance: old.abundance,
        coverage: old.coverage,
        vitality: old.vitality,
        observationDate: old.observationDate ?? DateTime.now(),
        family: family,
        subspecies: subspecies,
        localName: localName,
        latinName: latinName,
        certainty: certainty,
        idDoubts: doubts,
        keyMorphologicalTraits: keyTraits,
        confusingSpecies: confusing,
        characteristicFeature: characteristic,
        plantUsage: usage,
        cultivation: cultivation,
        prefPhMin: prefPhMin,
        prefPhMax: prefPhMax,
        prefSubstrate: prefSubstrate ?? old.prefSubstrate,
        prefMoisture: prefMoisture,
        prefSunlight: prefSunlight,
      );

      _observations[index] = updatedObs;
      await _db.insertObservation(updatedObs);
      notifyListeners();
    }
  }
  Future<void> saveAnalysisResults(String plantId, List<String> areaIds, int totalAreaCount) async {
    final index = _observations.indexWhere((o) => o.id == plantId);
    if (index != -1) {
      final old = _observations[index];
      final updated = PlantObservation(
        id: old.id,
        photoPaths: old.photoPaths,
        releveId: old.releveId,
        latitude: old.latitude,
        longitude: old.longitude,
        timestamp: old.timestamp,
        characteristics: old.characteristics,
        isSought: old.isSought,
        analyzedAreaIds: areaIds,
        lastAnalysisAreaCount: totalAreaCount,
        biologicalType: old.biologicalType,
        areaPurity: old.areaPurity,
        abundance: old.abundance,
        coverage: old.coverage,
        vitality: old.vitality,
        observationDate: old.observationDate,
        family: old.family,
        subspecies: old.subspecies,
        latinName: old.latinName,
        polishName: old.polishName,
        localName: old.localName,
        certainty: old.certainty,
        idDoubts: old.idDoubts,
        keyMorphologicalTraits: old.keyMorphologicalTraits,
        confusingSpecies: old.confusingSpecies,
        characteristicFeature: old.characteristicFeature,
        plantUsage: old.plantUsage,
        cultivation: old.cultivation,
        prefPhMin: old.prefPhMin,
        prefPhMax: old.prefPhMax,
        prefSubstrate: old.prefSubstrate,
        prefMoisture: old.prefMoisture,
        prefSunlight: old.prefSunlight,
      );

      _observations[index] = updated;
      await _db.insertObservation(updated);
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