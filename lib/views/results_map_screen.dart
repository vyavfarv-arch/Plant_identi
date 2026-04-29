// lib/views/results_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../models/plant_observation.dart';
import '../viewmodels/observation_view_model.dart';

class ResultsMapScreen extends StatefulWidget {
  final List<Releve> matchingAreas;
  final String plantName;
  final String? speciesId;

  const ResultsMapScreen({super.key, required this.matchingAreas, required this.plantName, this.speciesId});

  @override
  State<ResultsMapScreen> createState() => _ResultsMapScreenState();
}

class _ResultsMapScreenState extends State<ResultsMapScreen> {
  Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _buildPolygons();
  }

  void _buildPolygons() {
    for (var area in widget.matchingAreas) {
      if (area.points.isNotEmpty) {
        _polygons.add(
          Polygon(
            polygonId: PolygonId(area.id),
            points: area.points,
            fillColor: Colors.deepOrange.withOpacity(0.5),
            strokeColor: Colors.deepOrange,
            strokeWidth: 2,
            consumeTapEvents: true,
            onTap: () => _showAreaActionSheet(area),
          ),
        );
      }
    }
  }

  void _showAreaActionSheet(Releve area) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Wytypowany obszar: ${area.commonName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Typ: ${area.type}"),
            const SizedBox(height: 20),
            Text("Czy odnalazłeś tu roślinę: ${widget.plantName}?", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Jeszcze nie"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      _markAsFound(area);
                      Navigator.pop(ctx);
                    },
                    child: const Text("TAK, ZNALAZŁEM!"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _markAsFound(Releve area) {
    final obsVm = context.read<ObservationViewModel>();

    // Tworzymy natychmiastowy wpis w magazynie bez zdjęcia.
    // Użytkownik może wejść do magazynu i zedytować wpis później!
    final newObs = PlantObservation(
      id: const Uuid().v4(),
      releveId: area.id,
      speciesId: widget.speciesId,
      localName: widget.speciesId == null ? widget.plantName : null, // Używamy nazwy, jeśli to nowa roślina
      latitude: area.points.first.latitude,
      longitude: area.points.first.longitude,
      timestamp: DateTime.now(),
      observationDate: DateTime.now(), // Zaznaczamy, że obserwacja została dokonana!
      photoPaths: [],
      characteristics: {},
    );

    obsVm.addObservation(newObs);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      content: Text("Sukces! ${widget.plantName} dodana do Magazynu w obszarze ${area.commonName}."),
    ));
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialTarget = const LatLng(52.0, 19.0); // Domyślnie Polska
    if (widget.matchingAreas.isNotEmpty && widget.matchingAreas.first.points.isNotEmpty) {
      initialTarget = widget.matchingAreas.first.points.first;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Szukaj: ${widget.plantName}')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialTarget, zoom: 14),
        polygons: _polygons,
        mapType: MapType.hybrid,
        myLocationEnabled: true,
      ),
    );
  }
}