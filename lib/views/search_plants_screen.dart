import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../services/spatial_service.dart';

class SearchPlantsScreen extends StatelessWidget {
  const SearchPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    // Pobieramy unikalne nazwy opisanych roślin z magazynu
    final List<String> uniquePlants = obsVm.uniquePlantNames;

    return Scaffold(
      appBar: AppBar(title: const Text("Baza Gatunków")),
      body: uniquePlants.isEmpty
          ? const Center(child: Text("Magazyn jest pusty. Opisz najpierw rośliny!"))
          : ListView.builder(
        itemCount: uniquePlants.length,
        itemBuilder: (context, index) {
          final plantName = uniquePlants[index];
          return ListTile(
            leading: const Icon(Icons.eco, color: Colors.green),
            title: Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Przytrzymaj, aby zobaczyć ekologię gatunku"),
            onTap: () {
              // Tutaj w przyszłości podepniemy tryb "Poszukiwania" (Step 6/7)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Wybrano: $plantName do poszukiwań")),
              );
            },
            onLongPress: () => _showPlantEcoDetails(context, plantName, obsVm, releveVm),
          );
        },
      ),
    );
  }

  void _showPlantEcoDetails(BuildContext context, String plantName, ObservationViewModel obsVm, ReleveViewModel releveVm) {
    // 1. Znajdź wszystkie obserwacje tego gatunku
    final speciesObs = obsVm.completeObservations.where((o) => o.displayName == plantName).toList();

    // 2. Agreguj dane z siedlisk (releves), w których te rośliny rosną
    final Set<String> substrates = {};
    final Set<double> moistureValues = {};
    final List<double> phValues = [];
    final Set<String> litterLayers = {};
    final Set<String> observedInReleves = {};

    String cultivation = "";
    String usage = "";

    for (var obs in speciesObs) {
      // Wyciągnij opis hodowli i wykorzystania (jeśli są uzupełnione)
      if (cultivation.isEmpty && obs.cultivation != null && obs.cultivation!.isNotEmpty) {
        cultivation = obs.cultivation!;
      }
      if (usage.isEmpty && obs.plantUsage != null && obs.plantUsage!.isNotEmpty) {
        usage = obs.plantUsage!;
      }

      // Sprawdź, w jakich obszarach na mapie znajduje się ta konkretna obserwacja
      final areas = SpatialService.getAreasForPlant(releveVm.allReleves, obs);
      for (var area in areas) {
        observedInReleves.add("${area.type}: ${area.commonName}");
        if (area.habitat != null) {
          substrates.addAll(area.habitat!.substrateType);
          moistureValues.add(area.habitat!.moisture);
          if (area.habitat!.ph != null) phValues.add(area.habitat!.ph!);
          litterLayers.addAll(area.habitat!.litterLayer);
        }
      }
    }

    // Oblicz średnie pH
    final double? avgPh = phValues.isEmpty ? null : phValues.reduce((a, b) => a + b) / phValues.length;

    // Wyświetl Dialog z zagregowanymi danymi
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.teal, size: 40),
            const SizedBox(height: 10),
            Text(plantName, textAlign: TextAlign.center),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("WYSTĘPOWANIE (Siedlisko):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
              const Divider(),
              _ecoInfo("Typ podłoża", substrates.isNotEmpty ? substrates.join(", ") : "brak danych"),
              _ecoInfo("Wilgotność", _translateMoisture(moistureValues)),
              _ecoInfo("Średnie pH", avgPh != null ? avgPh.toStringAsFixed(1) : "brak danych"),
              _ecoInfo("Ściółka", litterLayers.isNotEmpty ? litterLayers.join(", ") : "brak danych"),
              const SizedBox(height: 20),
              const Text("HODOWLA I WYKORZYSTANIE:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
              const Divider(),
              _ecoInfo("Hodowla", cultivation.isNotEmpty ? cultivation : "brak opisu"),
              _ecoInfo("Wykorzystanie", usage.isNotEmpty ? usage : "brak opisu"),
              const SizedBox(height: 20),
              const Text("LOKALIZACJA W PŁATACH:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
              const Divider(),
              Text(observedInReleves.isNotEmpty ? observedInReleves.join("\n") : "Roślina zaobserwowana poza zapisanymi obszarami.",
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ"))],
      ),
    );
  }

  Widget _ecoInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 13),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _translateMoisture(Set<double> values) {
    if (values.isEmpty) return "brak danych";
    const labels = ["Sucho", "Świeżo", "Wilgotno", "Mokro"];
    return values.map((v) => labels[v.round()]).join(", ");
  }
}