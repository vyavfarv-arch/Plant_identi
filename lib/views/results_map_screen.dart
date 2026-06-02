// lib/views/results_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../models/sought_plant.dart';
import '../models/plant_observation.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../services/ecological_matching_service.dart';
import '../services/spatial_service.dart';
import 'quick_find_form_screen.dart';

class ResultsMapScreen extends StatefulWidget {
  final SoughtPlant targetPlant;

  const ResultsMapScreen({super.key, required this.targetPlant});

  @override
  State<ResultsMapScreen> createState() => _ResultsMapScreenState();
}

class _ResultsMapScreenState extends State<ResultsMapScreen> {
  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final obsVm = context.watch<ObservationViewModel>();

    LatLng initialTarget = const LatLng(52.23, 21.01);
    final allAreas = releveVm.allReleves;
    if (allAreas.isNotEmpty && allAreas.first.points.isNotEmpty) {
      initialTarget = allAreas.first.points.first;
    }

    final Set<Polygon> polygons = allAreas.where((r) => r.points.isNotEmpty).map((area) {
      // 1. Sprawdzenie, czy roślina została potwierdzona jako OBECNA
      final bool isAlreadyObserved = obsVm.allObservations.any((o) {
        final bool matchesPlant = o.speciesId == widget.targetPlant.id ||
            o.localName?.toLowerCase() == widget.targetPlant.polishName.toLowerCase() ||
            obsVm.getSpeciesById(o.speciesId)?.latinName.toLowerCase() == widget.targetPlant.latinName.toLowerCase();

        if (!matchesPlant || o.abundance == "Brak") return false;

        final bool directlyLinked = o.releveId == area.id;
        final bool spatiallyInside = SpatialService.isPointInPolygon(LatLng(o.latitude, o.longitude), area.points);
        return directlyLinked || spatiallyInside;
      });

      // 2. Sprawdzenie, czy roślina została zweryfikowana jako NIEPOTWIERDZONA (BRAK)
      final bool isMarkedAbsent = obsVm.allObservations.any((o) {
        final bool matchesPlant = o.speciesId == widget.targetPlant.id ||
            o.localName?.toLowerCase() == widget.targetPlant.polishName.toLowerCase();
        return matchesPlant && o.abundance == "Brak" && (o.releveId == area.id || SpatialService.isPointInPolygon(LatLng(o.latitude, o.longitude), area.points));
      });

      Color fillColor;
      Color strokeColor;
      String statusText = "";

      if (isAlreadyObserved) {
        fillColor = Colors.green.withOpacity(0.5); // ZIELONY: Jest tutaj
        strokeColor = Colors.green.shade800;
        statusText = "Gatunek potwierdzony w tym płacie!";
      } else if (isMarkedAbsent) {
        fillColor = Colors.grey.withOpacity(0.4); // SZARY: Zweryfikowany brak rośliny
        strokeColor = Colors.grey.shade700;
        statusText = "Zweryfikowana nieobecność gatunku (Brak występowania)";
      } else {
        final matchResult = EcologicalMatchingService.calculateCompatibility(area, widget.targetPlant);

        if (matchResult.isPotentialMatch) {
          fillColor = Colors.amber.withOpacity(0.5);
          strokeColor = Colors.orange.shade800;
          statusText = "Siedlisko potencjalne (Matryca Ellenberga: ${(matchResult.score * 100).toStringAsFixed(0)}%)";
        } else {
          fillColor = Colors.grey.withOpacity(0.15);
          strokeColor = Colors.grey.shade400;
          statusText = "Niska zgodność makrosiedliskowa";
        }
      }

      return Polygon(
        polygonId: PolygonId(area.id), points: area.points,
        fillColor: fillColor, strokeColor: strokeColor, strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => _showAreaActionSheet(context, area, isAlreadyObserved, isMarkedAbsent, statusText),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(title: Text('Siedliska: ${widget.targetPlant.polishName}'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            _buildLegend(),
            Expanded(child: GoogleMap(initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12), polygons: polygons, mapType: MapType.hybrid, myLocationEnabled: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.white,
      width: double.infinity,
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _legendItem(Colors.green, "Obecna (Sukces)"),
          _legendItem(Colors.amber, "Potencjalna (Matryca)"),
          _legendItem(Colors.grey, "Nieobecna / Niska zgodność"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) => Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withOpacity(0.5), border: Border.all(color: color))), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]);

  void _showAreaActionSheet(BuildContext context, Releve area, bool isAlreadyObserved, bool isMarkedAbsent, String statusText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Obszar: ${area.commonName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(statusText, style: TextStyle(color: isAlreadyObserved ? Colors.green.shade800 : Colors.deepOrange.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
            const Divider(height: 24),
            Text("Zweryfikuj obecność rośliny: ${widget.targetPlant.polishName}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                // PRZYCISK: OZNACZ JAKO NIEOBECNĄ (SZARY STATUS)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    icon: const Icon(Icons.label_off_outlined),
                    label: const Text("NIE MA JEJ TUTAJ"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _markAsAbsent(context, area);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // PRZYCISK: POTWIERDŹ OBECNOŚĆ (ZIELONY STATUS)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("ZNALAZŁEM!"),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => QuickFindFormScreen(area: area, targetPlant: widget.targetPlant)));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Logika zapisywania faktu, że przeszukano płat i roślina nie została odnaleziona
  void _markAsAbsent(BuildContext context, Releve area) async {
    final obsVm = context.read<ObservationViewModel>();
    final String targetSpeciesId = widget.targetPlant.id;

    final absentObs = PlantObservation(
      id: const Uuid().v4(),
      releveId: area.id,
      speciesId: targetSpeciesId,
      localName: widget.targetPlant.polishName,
      subspecies: "",
      latitude: area.points.first.latitude,
      longitude: area.points.first.longitude,
      timestamp: DateTime.now(),
      photoPaths: [],
      characteristics: {},
      abundance: "Brak", // Krytyczny indykator dla mapy wyników
      observationDate: DateTime.now(),
    );

    await obsVm.addObservation(absentObs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blueGrey,
          content: Text("Zanotowano nieobecność gatunku ${widget.targetPlant.polishName} na obszarze ${area.commonName}."),
        ),
      );
    }
  }
}