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
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Mapa prezentacji wyników analizy matrycowej dla rośliny poszukiwanej.
 * Dynamicznie koloruje poligony płatów na podstawie stanu (Potwierdzona obecność – zielony,
 * Zweryfikowana nieobecność – szary, Potencjalna zgodność z wektorem 7 osi Ellenberga – bursztynowy).
 * Udostępnia menu akcji oznaczania nieobecności lub szybkiego formularza sukcesu.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z katalogu '../models/':
 * - Klasy [Releve], [SoughtPlant], [PlantObservation]: Struktury danych do analizy i zapisu nieobecności.
 * * Z katalogu '../viewmodels/':
 * - Klasa [ObservationViewModel]: Odczyt i zapis obserwacji (weryfikacja statusów w płacie).
 * - Klasa [ReleveViewModel]: Udostępnia poligony płatów zarejestrowanych w systemie.
 * * Z katalogu '../services/':
 * - Klasa [EcologicalMatchingService]: Wylicza stopień zgodności i dostarcza sygnaturę [L:✓ F:✗ ...].
 * - Klasa [SpatialService]: Sprawdza, czy koordynaty okazów mieszczą się geometrycznie w płatach.
 * * Z katalogu widoków:
 * - Ekran [QuickFindFormScreen]: Otwierany w momencie potwierdzenia znalezienia rośliny.
 * ============================================================================
 */
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
      final bool isAlreadyObserved = obsVm.allObservations.any((o) {
        final bool matchesPlant = o.speciesId == widget.targetPlant.id ||
            o.localName?.toLowerCase() == widget.targetPlant.polishName.toLowerCase() ||
            obsVm.getSpeciesById(o.speciesId)?.latinName.toLowerCase() == widget.targetPlant.latinName.toLowerCase();
        if (!matchesPlant || o.abundance == "Brak") return false;
        return o.releveId == area.id || SpatialService.isPointInPolygon(LatLng(o.latitude, o.longitude), area.points);
      });

      final bool isMarkedAbsent = obsVm.allObservations.any((o) {
        final bool matchesPlant = o.speciesId == widget.targetPlant.id || o.localName?.toLowerCase() == widget.targetPlant.polishName.toLowerCase();
        return matchesPlant && o.abundance == "Brak" && (o.releveId == area.id || SpatialService.isPointInPolygon(LatLng(o.latitude, o.longitude), area.points));
      });

      Color fillColor; Color strokeColor; String statusText = "";

      if (isAlreadyObserved) {
        fillColor = Colors.green.withOpacity(0.5); strokeColor = Colors.green.shade800;
        statusText = "Gatunek potwierdzony w tym płacie!";
      } else if (isMarkedAbsent) {
        fillColor = Colors.grey.withOpacity(0.4); strokeColor = Colors.grey.shade700;
        statusText = "Zweryfikowana nieobecność gatunku (Brak występowania)";
      } else {
        final matchResult = EcologicalMatchingService.calculateCompatibility(area, widget.targetPlant);

        if (matchResult.isPotentialMatch) {
          fillColor = Colors.amber.withOpacity(0.5); strokeColor = Colors.orange.shade800;

          // FIX UX: Usunięto informacje procentowe, zostawiając czysty wektor diagnostyczny 7 osi Ellenberga
          final diagStr = matchResult.diagnostics.entries.map((e) => "${e.key}:${e.value}").join(" ");
          statusText = "Siedlisko potencjalne: [$diagStr]";
        } else {
          fillColor = Colors.grey.withOpacity(0.15); strokeColor = Colors.grey.shade400;
          statusText = "Niska zgodność makrosiedliskowa";
        }
      }

      return Polygon(
        polygonId: PolygonId(area.id), points: area.points, fillColor: fillColor, strokeColor: strokeColor, strokeWidth: 2, consumeTapEvents: true,
        onTap: () => _showAreaActionSheet(context, area, isAlreadyObserved, isMarkedAbsent, statusText),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(title: Text('Siedliska: ${widget.targetPlant.polishName}'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: SafeArea(child: Column(children: [_buildLegend(), Expanded(child: GoogleMap(initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12), polygons: polygons, mapType: MapType.hybrid, myLocationEnabled: true))])),
    );
  }

  // FIX RENDERFLEX OVERFLOW: Zastąpienie Row płaskimi, elastycznymi i bezpiecznymi widgetami Chip
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.white,
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.start, // Elastyczne wyrównanie Material 3
        children: [
          _legendChip(Colors.green, "Obecna (Sukces)"),
          _legendChip(Colors.amber, "Potencjalna (Matryca)"),
          _legendChip(Colors.grey, "Nieobecna / Niska zgodność"),
        ],
      ),
    );
  }

  Widget _legendChip(Color color, String text) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color.withOpacity(0.6), radius: 6),
      label: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.grey.shade50,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showAreaActionSheet(BuildContext context, Releve area, bool isAlreadyObserved, bool isMarkedAbsent, String statusText) {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Obszar: ${area.commonName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(statusText, style: TextStyle(color: isAlreadyObserved ? Colors.green.shade800 : Colors.deepOrange.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
            const Divider(height: 24),
            Text("Zweryfikuj obecność rośliny: ${widget.targetPlant.polishName}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), icon: const Icon(Icons.label_off_outlined), label: const Text("NIE MA JEJ TUTAJ"), onPressed: () { Navigator.pop(ctx); _markAsAbsent(context, area); })),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), icon: const Icon(Icons.check_circle_outline), label: const Text("ZNALAZŁEM!"), onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => QuickFindFormScreen(area: area, targetPlant: widget.targetPlant))); })),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _markAsAbsent(BuildContext context, Releve area) async {
    final obsVm = context.read<ObservationViewModel>();

    // POPRAWKA LOGIKI: Wyszukujemy klucz z tabeli 'plant_species' na podstawie nazwy łacińskiej zamiast wstrzykiwać ID z 'sought_plants' (zapobiega Foreign Key Constraint Failed crashowi)
    final existingSpecies = obsVm.findSpeciesByLatinName(widget.targetPlant.latinName);
    final String? targetSpeciesId = existingSpecies?.speciesID;

    final absentObs = PlantObservation(
      id: const Uuid().v4(), releveId: area.id, speciesId: targetSpeciesId, localName: widget.targetPlant.polishName, subspecies: "",
      latitude: area.points.first.latitude, longitude: area.points.first.longitude, timestamp: DateTime.now(), photoPaths: [], characteristics: {}, abundance: "Brak", observationDate: DateTime.now(),
    );
    await obsVm.addObservation(absentObs);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.blueGrey, content: Text("Zanotowano nieobecność gatunku ${widget.targetPlant.polishName} na obszarze ${area.commonName}.")));
  }
}