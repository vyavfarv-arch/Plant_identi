import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/plants_view_model.dart';

class ReleveMapScreen extends StatefulWidget {
  const ReleveMapScreen({super.key});

  @override
  State<ReleveMapScreen> createState() => _ReleveMapScreenState();
}

class _ReleveMapScreenState extends State<ReleveMapScreen> {
  final List<LatLng> _tappedPoints = [];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wyznacz płat (2 punkty)"),
        actions: [
          if (_tappedPoints.length == 2)
            IconButton(
              icon: const Icon(Icons.check_box, size: 30),
              onPressed: () => _confirmReleve(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _tappedPoints.clear()),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 15),
        mapType: MapType.satellite, // Wymagane zdjęcia satelitarne
        myLocationEnabled: true,
        onTap: (pos) {
          if (_tappedPoints.length < 2) {
            setState(() => _tappedPoints.add(pos));
          }
        },
        // Wyświetlanie punktów i prostokąta
        markers: _tappedPoints.asMap().entries.map<Marker>((e) => Marker(
          markerId: MarkerId("p${e.key}"),
          position: e.value,
          // POPRAWKA: Zmiana label na infoWindow
          infoWindow: InfoWindow(title: "Punkt ${e.key + 1}"),
        )).toSet(),
        polygons: _tappedPoints.length == 2 ? {
          Polygon(
            polygonId: const PolygonId("area"),
            points: _calculateRectanglePoints(_tappedPoints[0], _tappedPoints[1]),
            fillColor: Colors.green.withOpacity(0.3),
            strokeColor: Colors.green,
            strokeWidth: 2,
          )
        } : {},
      ),
    );
  }

  // Funkcja pomocnicza tworząca 4 punkty prostokąta z 2 narożników
  List<LatLng> _calculateRectanglePoints(LatLng p1, LatLng p2) {
    return [
      p1,
      LatLng(p1.latitude, p2.longitude),
      p2,
      LatLng(p2.latitude, p1.longitude),
    ];
  }

  void _confirmReleve(BuildContext context) {

    context.read<PlantsViewModel>().createReleve(_tappedPoints);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Utworzono płat fitosocjologiczny na podstawie wielokąta.")),
    );
    Navigator.pop(context);
  }
}