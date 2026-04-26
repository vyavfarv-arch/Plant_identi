// lib/views/releve_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../services/location_service.dart';
import 'habitat_details_screen.dart';
class ReleveMapScreen extends StatefulWidget {
  const ReleveMapScreen({super.key});

  @override
  State<ReleveMapScreen> createState() => _ReleveMapScreenState();
}

class _ReleveMapScreenState extends State<ReleveMapScreen> {
  final List<LatLng> _polygonPoints = [];
  final LocationService _locationService = LocationService();
  LatLng _initialPosition = const LatLng(52.23, 21.01); // Warszawa jako fallback
  bool _isLoadingLocation = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _initialPosition = LatLng(pos.latitude, pos.longitude);
        _isLoadingLocation = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 15));
    } else {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Wyznacz nowy obszar")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 15),
            mapType: MapType.satellite,
            myLocationEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            onTap: (point) => setState(() => _polygonPoints.add(point)),
            polygons: {
              // 1. WYŚWIETLANIE ISTNIEJĄCYCH OBSZARÓW (SZARE)
              ...releveVm.allReleves.map((r) => Polygon(
                polygonId: PolygonId("bg_${r.id}"),
                points: r.points,
                fillColor: Colors.grey.withValues(alpha: 0.3),
                strokeColor: Colors.grey,
                strokeWidth: 1,
              )),
              // 2. AKTUALNIE RYSOWANY OBSZAR
              if (_polygonPoints.length >= 3)
                Polygon(
                  polygonId: const PolygonId("current_area"),
                  points: _polygonPoints,
                  fillColor: Colors.green.withValues(alpha: 0.4),
                  strokeColor: Colors.green,
                  strokeWidth: 3,
                )
            },
            markers: _polygonPoints.asMap().entries.map((e) => Marker(
              markerId: MarkerId("p${e.key}"),
              position: e.value,
              onTap: () => setState(() => _polygonPoints.removeAt(e.key)),
            )).toSet(),
          ),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),
          if (_polygonPoints.length >= 3)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HabitatDetailsScreen(points: List.from(_polygonPoints)),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text("DALEJ DO SZCZEGÓŁÓW", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}