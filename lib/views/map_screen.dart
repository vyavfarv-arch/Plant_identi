// lib/views/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart'; // DODANY IMPORT
import 'plant_card_view.dart';
import 'releve_details_screen.dart'; // DODANY IMPORT DO KLIKANIA W OBSZAR

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>(); // SŁUCHAMY OBSZARÓW

    // 1. Budowanie Markerów (Rośliny)
    Set<Marker> markers = obsVm.allObservations.map((obs) {
      return Marker(
        markerId: MarkerId(obs.id),
        position: LatLng(obs.latitude, obs.longitude),
        infoWindow: InfoWindow(title: obs.displayName, snippet: 'Kliknij, aby zobaczyć kartę'),
        onTap: () => PlantCardView.show(context, obs),
      );
    }).toSet();

    // 2. Budowanie Polygonów (Obszary)
    Set<Polygon> polygons = releveVm.allReleves.where((r) => r.points.isNotEmpty).map((r) {
      final isArea = r.type == "Obszar";
      return Polygon(
        polygonId: PolygonId(r.id),
        points: r.points,
        fillColor: isArea ? Colors.indigo.withOpacity(0.2) : Colors.teal.withOpacity(0.3),
        strokeColor: isArea ? Colors.indigo : Colors.teal,
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () {
          // Kliknięcie w obszar na mapie otwiera jego szczegóły
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r)));
        },
      );
    }).toSet();

    LatLng initialPos = const LatLng(52.2297, 21.0122); // Warszawa
    if (obsVm.allObservations.isNotEmpty) {
      initialPos = LatLng(obsVm.allObservations.first.latitude, obsVm.allObservations.first.longitude);
    } else if (releveVm.allReleves.isNotEmpty && releveVm.allReleves.first.points.isNotEmpty) {
      initialPos = releveVm.allReleves.first.points.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa Terenowa")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialPos, zoom: 12),
        markers: markers,
        polygons: polygons, // DODANIE POLYGONÓW DO MAPY
        mapType: MapType.hybrid,
        myLocationEnabled: true,
      ),
    );
  }
}