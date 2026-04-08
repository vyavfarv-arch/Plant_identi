import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../models/plant_observation.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import 'package:path/path.dart' as p;

class ObservationViewModel extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();

  // Tymczasowa lista ścieżek do zdjęć dla aktualnie tworzonej obserwacji
  List<String> _currentPhotoPaths = [];
  Position? _currentPosition;
  bool _isInitializing = false;

  List<String> get currentPhotoPaths => _currentPhotoPaths;
  bool get canTakePhoto => _currentPhotoPaths.length < 3;
  bool get isInitializing => _isInitializing;
  CameraController? get controller => _cameraService.controller;
  Position? get currentPosition => _currentPosition;
  // Inicjalizacja serwisów
  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    try {
      // Najpierw aparat - to jest priorytet dla użytkownika
      await _cameraService.initCamera();
      notifyListeners(); // Odśwież, żeby pokazać obraz z aparatu jak najszybciej

      // Lokalizacja pobierana w tle - nie blokuje renderowania aparatu
      _currentPosition = await _locationService.getCurrentLocation();
    } catch (e) {
      print("Błąd inicjalizacji: $e");
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Akcja: Zrób zdjęcie
  Future<void> takePhoto() async {
    if (!canTakePhoto) return;

    final path = await _cameraService.takePicture();
    if (path != null) {
      _currentPhotoPaths.add(path);

      // Przy pierwszym zdjęciu odświeżamy lokalizację, żeby była jak najdokładniejsza
      if (_currentPhotoPaths.length == 1) {
        _currentPosition = await _locationService.getCurrentLocation();
      }

      notifyListeners(); // Powiadom UI, że zmieniła się liczba zdjęć
    }
  }

  // Akcja: Usuń wybrane zdjęcie
  void removePhoto(int index) {
    _currentPhotoPaths.removeAt(index);
    notifyListeners();
  }

  // Resetowanie formularza
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