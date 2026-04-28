// lib/views/results_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/releve.dart';

class ResultsMapScreen extends StatelessWidget {
  final List<Releve> matchingAreas;
  final String plantName;

  const ResultsMapScreen({super.key, required this.matchingAreas, required this.plantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Wyniki dla: $plantName")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: (matchingAreas.isNotEmpty && matchingAreas.first.points.isNotEmpty)
              ? matchingAreas.first.points.first
              : const LatLng(52, 20),
          zoom: 10,
        ),
        mapType: MapType.satellite,
        polygons: matchingAreas.map((area) => Polygon(
          polygonId: PolygonId(area.id),
          points: area.points,
          fillColor: Colors.amber.withValues(alpha: 0.5), // Złoty kolor dla wyników
          strokeColor: Colors.orange,
          strokeWidth: 3,
        )).toSet(),
      ),
    );
  }
}