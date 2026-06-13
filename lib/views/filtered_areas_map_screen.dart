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
 * Renderuje przekazaną kolekcję obszarów jako interaktywne wielokąty (Polygons).
 * Centruje kamerę na pierwszym dopasowanym płacie i umożliwia bezpośrednią
 * nawigację do szczegółów po kliknięciu w dany obszar.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/releve.dart':
 * - Klasa [Releve]: Model danych reprezentujący kolekcję wejściową płatów.
 * * Z katalogu widoków:
 * - Ekran [ReleveDetailsScreen]: Wywoływany w celu wyświetlenia szczegółowych statystyk
 * i analizy ekologicznej po kliknięciu w poligon płatu.
 * ============================================================================
 */

class FilteredAreasMapScreen extends StatelessWidget {
  final List<Releve> filteredAreas;

  const FilteredAreasMapScreen({super.key, required this.filteredAreas});

  @override
  Widget build(BuildContext context) {
    // Punkt startowy mapy (pierwszy element lub centrum Polski)
    LatLng initialTarget = const LatLng(52.23, 21.01);
    if (filteredAreas.isNotEmpty && filteredAreas.first.points.isNotEmpty) {
      initialTarget = filteredAreas.first.points.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Wyniki na mapie (${filteredAreas.length})"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child:  GoogleMap(
        initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
        mapType: MapType.hybrid,
        myLocationEnabled: true,
        polygons: filteredAreas.where((r) => r.points.isNotEmpty).map((area) {
          return Polygon(
            polygonId: PolygonId(area.id),
            points: area.points,
            fillColor: Colors.indigo.withOpacity(0.5),
            strokeColor: Colors.indigo,
            strokeWidth: 2,
            consumeTapEvents: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: area)),
            ),
          );
        }).toSet(),
      ),),
    );
  }
}