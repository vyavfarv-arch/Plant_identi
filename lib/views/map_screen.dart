import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/plants_view_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa Roślin')),
      body: Consumer<PlantsViewModel>(
        builder: (context, vm, child) {
          final plants = vm.filteredCompleteObservations;

          // Tworzenie zestawu markerów
          Set<Marker> markers = plants.map((obs) {
            return Marker(
              markerId: MarkerId(obs.id),
              position: LatLng(obs.latitude, obs.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Zielony punkt
              infoWindow: InfoWindow(title: obs.plantName),
            );
          }).toSet();

          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(52.237, 21.017), // Środek Polski (domyślnie)
              zoom: 6,
            ),
            markers: markers,
            myLocationEnabled: true,
          );
        },
      ),
    );
  }
}