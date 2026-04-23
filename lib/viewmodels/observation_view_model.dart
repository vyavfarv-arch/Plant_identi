import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../models/plant_observation.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/database_helper.dart';

class ObservationViewModel extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final StorageService _storage = StorageService();
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
    await _db.insertObservation(obs); // Zapis pojedynczej rośliny
    await loadFromDisk();
  }

  Future<void> deleteObservation(String id) async {
    await _db.deleteObservation(id);
    await loadFromDisk();
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

      // NOWA LOGIKA: Jeśli roślina nie miała daty, a teraz nadajemy jej nazwę, ustawiamy datę na teraz
      DateTime? finalDate = old.observationDate;
      if (finalDate == null && localName != null && localName.isNotEmpty) {
        finalDate = DateTime.now();
      }

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
        observationDate: finalDate, // Używamy wyliczonej daty
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

  void reset() {
    _currentPhotoPaths = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}