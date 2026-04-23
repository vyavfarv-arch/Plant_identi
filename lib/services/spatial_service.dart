// lib/services/spatial_service.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';

class SpatialService {
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
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

  static List<PlantObservation> getPlantsInArea(List<PlantObservation> plants, Releve area) {
    return plants.where((p) => isPointInPolygon(LatLng(p.latitude, p.longitude), area.points)).toList();
  }

  static List<Releve> getAreasForPlant(List<Releve> areas, PlantObservation plant) {
    return areas.where((a) => isPointInPolygon(LatLng(plant.latitude, plant.longitude), a.points)).toList();
  }
}