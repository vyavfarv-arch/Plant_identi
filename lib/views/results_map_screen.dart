// lib/views/results_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../models/sought_plant.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../services/ecological_matching_service.dart';
import '../services/spatial_service.dart';
import 'quick_find_form_screen.dart'; // Import nowego formularza

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
      // FIX BŁĘDU: Sprawdzenie relacji bezpośredniej LUB przecięcia przestrzennego (GPS)
      final bool isAlreadyObserved = obsVm.allObservations.any((o) {
        final bool matchesPlant = o.speciesId == widget.targetPlant.id ||
            o.localName?.toLowerCase() == widget.targetPlant.polishName.toLowerCase() ||
            obsVm.getSpeciesById(o.speciesId)?.latinName.toLowerCase() == widget.targetPlant.latinName.toLowerCase();

        if (!matchesPlant) return false;

        final bool directlyLinked = o.releveId == area.id;
        final bool spatiallyInside = SpatialService.isPointInPolygon(LatLng(o.latitude, o.longitude), area.points);

        return directlyLinked || spatiallyInside;
      });

      Color fillColor;
      Color strokeColor;
      String statusText = "";

      if (isAlreadyObserved) {
        fillColor = Colors.green.withOpacity(0.5); // ZIELONY: Roślina już tu jest
        strokeColor = Colors.green.shade800;
        statusText = "Gatunek potwierdzony w tym płacie!";
      } else {
        // Obliczenie dopasowania wagowego z nowej matrycy ekologicznej
        final matchResult = EcologicalMatchingService.calculateCompatibility(
          prefPhMin: widget.targetPlant.prefPhMin, prefPhMax: widget.targetPlant.prefPhMax,
          prefAreaTypes: widget.targetPlant.prefAreaTypes, prefWaterDynamics: widget.targetPlant.prefWaterDynamics,
          prefLightLevels: widget.targetPlant.prefLightLevels, prefSoilTypes: widget.targetPlant.prefSoilTypes, area: area,
        );

        if (matchResult.isPotentialMatch) {
          fillColor = Colors.amber.withOpacity(0.5); // ŻÓŁTY: Wysoki potencjał (Wagi ≥75%)
          strokeColor = Colors.orange.shade800;
          statusText = "Siedlisko potencjalne (Matryca wagowa: ${(matchResult.score * 100).toStringAsFixed(0)}%)";
        } else {
          fillColor = Colors.grey.withOpacity(0.25); // SZARY: Brak warunków ekologicznych
          strokeColor = Colors.grey.shade600;
          statusText = "Niska zgodność makrosiedliskowa";
        }
      }

      return Polygon(
        polygonId: PolygonId(area.id), points: area.points,
        fillColor: fillColor, strokeColor: strokeColor, strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => _showAreaActionSheet(context, area, isAlreadyObserved, statusText),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _legendItem(Colors.green, "Potwierdzona (Magazyn)"),
          _legendItem(Colors.amber, "Potencjalna (Matryca ≥75%)"),
          _legendItem(Colors.grey, "Niedopasowana"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) => Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withOpacity(0.5), border: Border.all(color: color))), const SizedBox(width: 6), Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]);

  void _showAreaActionSheet(BuildContext context, Releve area, bool isAlreadyObserved, String statusText) {
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
            Text("Czy odnalazłeś tu roślinę: ${widget.targetPlant.polishName}?", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj"))),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Przekierowanie do pełnego formularza terenowego zamiast pustego zapisu
                      Navigator.push(context, MaterialPageRoute(builder: (_) => QuickFindFormScreen(area: area, targetPlant: widget.targetPlant)));
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
}