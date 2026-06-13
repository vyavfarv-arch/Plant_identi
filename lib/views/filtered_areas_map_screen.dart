// lib/views/filtered_areas_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/releve.dart';
import 'releve_details_screen.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Interfejs mapy dedykowany dla prezentacji wyfiltrowanych płatów fitosocjologicznych.
 * Renderuje pełną pulę obszarów jako wielokąty, wyróżniając kolorem niebieskim
 * dopasowane płaty i wyszarzając pozostałe strefy.
 * ============================================================================
 */
class FilteredAreasMapScreen extends StatelessWidget {
  final List<Releve> allAreas;
  final Set<String> matchedAreaIds;

  const FilteredAreasMapScreen({
    super.key,
    required this.allAreas,
    required this.matchedAreaIds,
  });

  @override
  Widget build(BuildContext context) {
    LatLng initialTarget = const LatLng(52.23, 21.01);

    // Centrujemy widok kamery na pierwszym pasującym (niebieskim) obszarze
    final matchedAreas = allAreas.where((r) => matchedAreaIds.contains(r.id) && r.points.isNotEmpty);
    if (matchedAreas.isNotEmpty) {
      initialTarget = matchedAreas.first.points.first;
    } else if (allAreas.isNotEmpty && allAreas.first.points.isNotEmpty) {
      initialTarget = allAreas.first.points.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Wyniki na mapie (${matchedAreaIds.length})"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
          mapType: MapType.hybrid,
          myLocationEnabled: true,
          polygons: allAreas.where((r) => r.points.isNotEmpty).map((area) {
            final isMatched = matchedAreaIds.contains(area.id);

            return Polygon(
              polygonId: PolygonId(area.id),
              points: area.points,
              // Wybór koloru na podstawie dopasowania do filtra
              fillColor: isMatched
                  ? Colors.indigo.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.15),
              strokeColor: isMatched
                  ? Colors.indigo
                  : Colors.grey.shade400,
              strokeWidth: 2,
              consumeTapEvents: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: area)),
              ),
            );
          }).toSet(),
        ),
      ),
    );
  }
}