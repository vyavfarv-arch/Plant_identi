// lib/services/spatial_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';

class SpatialService {
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    // Istniejąca logika algorytmu Ray-casting
    // ...
  }

  static List<PlantObservation> getPlantsInArea(List<PlantObservation> plants, Releve area) {
    return plants.where((p) => isPointInPolygon(LatLng(p.latitude, p.longitude), area.points)).toList();
  }
}