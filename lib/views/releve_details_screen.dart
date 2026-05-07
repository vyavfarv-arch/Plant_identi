// lib/views/releve_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../services/ml_prediction_service.dart';
import '../services/spatial_service.dart';
import 'plant_card_view.dart';
import 'habitat_form_screen.dart';
import 'filtered_areas_map_screen.dart'; // DODANY IMPORT

class ReleveDetailsScreen extends StatefulWidget {
  final Releve releve;
  const ReleveDetailsScreen({super.key, required this.releve});

  @override
  State<ReleveDetailsScreen> createState() => _ReleveDetailsScreenState();
}

class _ReleveDetailsScreenState extends State<ReleveDetailsScreen> {
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

    // Pobranie najświeższej wersji płatu z bazy
    final currentReleve = releveVm.allReleves.firstWhere(
            (r) => r.id == widget.releve.id,
        orElse: () => widget.releve
    );

    // Znajdowanie roślin, których lokalizacja (GPS) wpada w granice tego płatu
    final actualPlants = SpatialService.getPlantsInArea(obsVm.completeObservations, currentReleve);

    // Budowanie listy nazw roślin znanych (z magazynu i poszukiwanych) dla potrzeb ML
    final knownNames = <String>{};
    for (var s in obsVm.speciesDictionary) {
      if (s.latinName.isNotEmpty) knownNames.add(s.latinName.toLowerCase());
      if (s.polishName.isNotEmpty) knownNames.add(s.polishName.toLowerCase());
    }
    for (var s in filterVm.soughtPlants) {
      if (s.latinName.isNotEmpty) knownNames.add(s.latinName.toLowerCase());
      if (s.polishName.isNotEmpty) knownNames.add(s.polishName.toLowerCase());
    }

    // Filtracja wyników ML - pokazuj tylko te z wysokim prawdopodobieństwem i znane systemowi
    final potentialPlants = currentReleve.mlPredictions.entries.where((e) {
      if (e.value < 0.6) return false;
      return knownNames.contains(e.key.toLowerCase());
    }).toList();

    // Pobieramy tylko dzieci (podobszary), ignorujemy system rodzica
    final childrenAreas = releveVm.getChildren(currentReleve.id);

    return Scaffold(
      appBar: AppBar(
        title: Text("${currentReleve.type}: ${currentReleve.commonName}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') _confirmDelete(context, releveVm, currentReleve);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'delete', child: Text('Usuń obszar', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // SEKCJA AKCJI I STRUKTURY (Zaktualizowana)
          _buildActionSection(context, currentReleve, childrenAreas),

          const Divider(),

          _buildSectionHeader("Gatunki w płacie (${actualPlants.length}):", Colors.grey[100]!),
          if (actualPlants.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Brak zaobserwowanych roślin.")))
          else
            ...actualPlants.map((plant) => ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: Text(plant.displayName),
              subtitle: Text(obsVm.getSpeciesById(plant.speciesId)?.latinName ?? "Brak nazwy łacińskiej"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => PlantCardView.show(context, plant),
            )).toList(),

          if (potentialPlants.isNotEmpty) ...[
            _buildSectionHeader("Przewidywane gatunki (Potencjalne):", Colors.purple.shade50),
            ...potentialPlants.map((entry) => ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.purple),
              title: Text(entry.key),
              subtitle: Text("Prawdopodobieństwo: ${(entry.value * 100).toStringAsFixed(0)}%"),
            )).toList(),
          ],

          const SizedBox(height: 30),

          if (currentReleve.habitat != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: _isAnalyzing ? null : () => _runMLAnalysis(currentReleve, releveVm, obsVm, filterVm),
                icon: _isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.psychology),
                label: Text(_isAnalyzing ? "ANALIZOWANIE..." : "OKREŚL ROŚLINY POTENCJALNE"),
              ),
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(padding: const EdgeInsets.all(16), color: color, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
  }

  // NOWA METODA: Zamiast starej sekcji hierarchii
  Widget _buildActionSection(BuildContext context, Releve currentReleve, List<Releve> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // PRZYCISK 1: Wyświetl obszar na mapie
          ListTile(
            leading: const Icon(Icons.map, color: Colors.indigo),
            title: const Text("Wyświetl obszar na mapie", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Centrowanie widoku na granicach płatu"),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FilteredAreasMapScreen(filteredAreas: [currentReleve])),
            ),
          ),

          // PRZYCISK 2: Informacje o siedlisku
          ListTile(
            leading: const Icon(Icons.landscape, color: Colors.brown),
            title: const Text("Informacje o siedlisku"),
            subtitle: Text(currentReleve.habitat == null ? "Brak opisu gleby i terenu" : "Siedlisko opisane szczegółowo"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitatFormScreen(releve: currentReleve))),
          ),

          // SEKCJA PODLEGŁYCH OBSZARÓW
          if (children.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.account_tree_outlined, color: Colors.blueGrey),
              title: Text("Podobszary / Jednostki niższe (${children.length})"),
              children: children.map((c) => ListTile(
                title: Text(c.commonName),
                subtitle: Text("${c.type}: ${c.phytosociologicalName}"),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: c))),
              )).toList(),
            ),
        ],
      ),
    );
  }

  void _runMLAnalysis(Releve area, ReleveViewModel releveVm, ObservationViewModel obsVm, SearchFilterViewModel filterVm) async {
    setState(() => _isAnalyzing = true);
    try {
      final mlService = MlPredictionService();
      await mlService.loadModel();
      final predictions = mlService.getPlantsForArea(area);
      await releveVm.updateRelevePredictions(area.id, predictions);

      final knownNames = <String>{};
      for (var s in obsVm.speciesDictionary) {
        if (s.latinName.isNotEmpty) knownNames.add(s.latinName.toLowerCase());
        if (s.polishName.isNotEmpty) knownNames.add(s.polishName.toLowerCase());
      }
      for (var s in filterVm.soughtPlants) {
        if (s.latinName.isNotEmpty) knownNames.add(s.latinName.toLowerCase());
        if (s.polishName.isNotEmpty) knownNames.add(s.polishName.toLowerCase());
      }

      int addedCount = predictions.entries.where((e) => e.value >= 0.6 && knownNames.contains(e.key.toLowerCase())).length;

      if (mounted) {
        if (addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analiza zakończona. Znaleziono $addedCount potencjalnych gatunków.")));
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Brak dopasowań", style: TextStyle(color: Colors.orange)),
              content: const Text("Model ML nie znalazł w tym siedlisku żadnych roślin z Twojej bazy."),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _confirmDelete(BuildContext context, ReleveViewModel vm, Releve currentReleve) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń obszar"),
        content: const Text("Czy na pewno chcesz trwale usunąć ten płat?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { vm.deleteReleve(currentReleve.id); Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text("USUŃ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}