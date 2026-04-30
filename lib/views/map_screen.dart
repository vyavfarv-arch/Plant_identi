// lib/views/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import 'plant_card_view.dart';
import 'releve_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showPlants = true;
  String _plantFilter = "Wszystkie";

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>();

    Set<Marker> markers = {};
    if (_showPlants) {
      markers = obsVm.allObservations.where((o) {
        if (_plantFilter == "Wszystkie") return true;
        return o.displayName.contains(_plantFilter);
      }).map((obs) {
        return Marker(
          markerId: MarkerId('plant_${obs.id}'),
          position: LatLng(obs.latitude, obs.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => PlantCardView.show(context, obs),
        );
      }).toSet();
    }

    Set<Polygon> polygons = releveVm.allReleves.where((r) => r.points.isNotEmpty).map((r) {
      return Polygon(
        polygonId: PolygonId(r.id),
        points: r.points,
        fillColor: Colors.indigo.withOpacity(0.4),
        strokeColor: Colors.indigo,
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa Terenowa"),
        actions: [
          // FILTR W PRAWYM GÓRNYM ROGU
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (val) {
              setState(() {
                if (val == "ukryj") { _showPlants = false; }
                else { _showPlants = true; _plantFilter = val; }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Wszystkie", child: Text("Pokaż wszystkie rośliny")),
              const PopupMenuItem(value: "ukryj", child: Text("Ukryj rośliny")),
              const PopupMenuDivider(),
              ...obsVm.allLatinNames.take(5).map((name) => PopupMenuItem(value: name, child: Text(name))),
            ],
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 10),
        markers: markers,
        polygons: polygons,
        mapType: MapType.hybrid,
        myLocationEnabled: true,
      ),
    );
  }
}