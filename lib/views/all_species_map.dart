// lib/views/all_species_map.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../models/releve.dart';
import '../models/plant_observation.dart';
import 'releve_details_screen.dart';

/// Mapa zbiorcza wszystkich płatów, w których zarejestrowano dany gatunek.
/// Pokazuje zarówno granice Releve, jak i lokalizacje poszczególnych obserwacji.
class AllSpeciesMapScreen extends StatefulWidget {
  final String speciesName;
  final List<Releve> areas;
  final List<PlantObservation> observations;

  const AllSpeciesMapScreen({
    super.key,
    required this.speciesName,
    required this.areas,
    required this.observations,
  });

  @override
  State<AllSpeciesMapScreen> createState() => _AllSpeciesMapScreenState();
}

class _AllSpeciesMapScreenState extends State<AllSpeciesMapScreen> {
  GoogleMapController? _mapController;

  Set<Polygon> get _polygons {
    return widget.areas.map((area) {
      return Polygon(
        polygonId: PolygonId(area.id),
        points: area.points,
        strokeWidth: 3,
        strokeColor: Colors.teal,
        fillColor: Colors.teal.withOpacity(0.16),
        consumeTapEvents: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReleveDetailsScreen(releve: area),
            ),
          );
        },
      );
    }).toSet();
  }

  Set<Marker> get _markers {
    return widget.observations.map((obs) {
      final date = obs.observationDate ?? obs.timestamp;

      return Marker(
        markerId: MarkerId("obs_${obs.id}"),
        position: LatLng(obs.latitude, obs.longitude),
        infoWindow: InfoWindow(
          title: widget.speciesName,
          snippet: DateFormat('yyyy-MM-dd').format(date),
        ),
      );
    }).toSet();
  }

  List<LatLng> get _allPoints {
    final points = <LatLng>[];

    for (final area in widget.areas) {
      points.addAll(area.points);
    }

    for (final obs in widget.observations) {
      points.add(
        LatLng(
          obs.latitude,
          obs.longitude,
        ),
      );
    }

    return points;
  }

  CameraPosition get _initialCameraPosition {
    final points = _allPoints;

    if (points.isEmpty) {
      return const CameraPosition(
        target: LatLng(52.0, 19.0),
        zoom: 5.5,
      );
    }

    return CameraPosition(
      target: points.first,
      zoom: 12,
    );
  }

  Future<void> _fitAll() async {
    if (_mapController == null) return;

    final points = _allPoints;
    if (points.isEmpty) return;

    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          points.first,
          15,
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Jeżeli wszystkie punkty praktycznie pokrywają się,
    // LatLngBounds może mieć zerowy rozmiar.
    if (minLat == maxLat && minLng == maxLng) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(minLat, minLng),
          15,
        ),
      );
      return;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Występowanie: ${widget.speciesName}"),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Pokaż wszystkie obszary",
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            polygons: _polygons,
            markers: _markers,
            mapType: MapType.satellite,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitAll();
              });
            },
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.layers_outlined,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${widget.areas.length} "
                        "${widget.areas.length == 1 ? 'obszar' : 'obszarów'}"
                        " • ${widget.observations.length} "
                        "${widget.observations.length == 1 ? 'obserwacja' : 'obserwacji'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
