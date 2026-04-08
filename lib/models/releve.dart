import 'package:google_maps_flutter/google_maps_flutter.dart';

class Releve {
  final String id;
  final LatLngBounds area; // Prostokąt wyznaczony przez 2 punkty
  final DateTime date;
  final List<String> plantObservationIds; // Lista ID roślin wewnątrz
  String? assignedSyntaxonId;
  bool isHeterogeneous; // Czy wykryto mieszanie klas

  Releve({
    required this.id,
    required this.area,
    required this.date,
    required this.plantObservationIds,
    this.assignedSyntaxonId,
    this.isHeterogeneous = false,
  });
}