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

    final currentReleve = releveVm.allReleves.firstWhere(
            (r) => r.id == widget.releve.id,
        orElse: () => widget.releve
    );

    final actualPlants = SpatialService.getPlantsInArea(obsVm.completeObservations, currentReleve);

    final knownNames = <String>{};
    for (var s in obsVm.speciesDictionary) {
      if (s.latinName.isNotEmpty) knownNames.add(s.latinName.toLowerCase());
      if (s.polishName.isNotEmpty) knownNames.add(s.polishName.toLowerCase());
    }
    for (var s in filterVm.soughtPlants) {
      if (s.latinName.isNotEmpty) knownNames.add(s.latinName.toLowerCase());
      if (s.polishName.isNotEmpty) knownNames.add(s.polishName.toLowerCase());
    }

    final potentialPlants = currentReleve.mlPredictions.entries.where((e) {
      if (e.value < 0.6) return false;
      return knownNames.contains(e.key.toLowerCase()); // Akceptuj tylko, jeśli znamy ten gatunek!
    }).toList();

    final parentArea = releveVm.getParentArea(currentReleve.parentId);
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
          _buildHierarchySection(context, releveVm, parentArea, childrenAreas, currentReleve, obsVm, filterVm),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _isAnalyzing ? null : () => _runMLAnalysis(currentReleve, releveVm, obsVm, filterVm),
                icon: _isAnalyzing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.psychology),
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

  void _runMLAnalysis(Releve area, ReleveViewModel releveVm, ObservationViewModel obsVm, SearchFilterViewModel filterVm) async {
    setState(() => _isAnalyzing = true);

    try {
      final mlService = MlPredictionService();
      await mlService.loadModel();
      final predictions = mlService.getPlantsForArea(area);

      await releveVm.updateRelevePredictions(area.id, predictions);

      // Obliczanie znanych gatunków do wyświetlenia na pop-upie
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analiza zakończona. Znaleziono $addedCount potencjalnych gatunków z Twojej bazy.")));
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Brak wyników", style: TextStyle(color: Colors.orange)),
              content: const Text("Model ML nie znalazł w tym siedlisku żadnych roślin, które znajdują się w Twoim magazynie lub na liście poszukiwanych."),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wystąpił błąd: $e")));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Widget _buildHierarchySection(BuildContext context, ReleveViewModel vm, Releve? parent, List<Releve> children, Releve currentReleve, ObservationViewModel obsVm, SearchFilterViewModel filterVm) {
    String parentTitle = currentReleve.type == "Klasa" ? "Klasa (Jednostka nadrzędna)" : (parent != null ? "Nadrzędny: ${parent.commonName}" : "Brak obszaru nadrzędnego");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          ListTile(
            dense: true, visualDensity: const VisualDensity(vertical: -4), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: Text(parentTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(currentReleve.type == "Klasa" ? "Status: Syntakson główny" : (parent?.type ?? "Kliknij, aby przypisać"), style: const TextStyle(fontSize: 11)),
            onTap: currentReleve.type == "Klasa" ? null : () => _showAssignParentDialog(context, currentReleve, vm),
          ),
          ListTile(
            leading: const Icon(Icons.landscape, color: Colors.brown),
            title: const Text("Informacje o siedlisku"),
            subtitle: Text(currentReleve.habitat == null ? "Brak opisu gleby" : "Siedlisko opisane"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitatFormScreen(releve: currentReleve))),
          ),
          if (children.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.blueGrey),
              title: Text("Obszary podległe (${children.length})"),
              children: children.map((c) => ListTile(
                title: Text(c.commonName), subtitle: Text("${c.type}: ${c.phytosociologicalName}"),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: c))),
              )).toList(),
            ),
        ],
      ),
    );
  }

  void _showAssignParentDialog(BuildContext context, Releve child, ReleveViewModel vm) {
    final potentialParents = vm.getPotentialParents(child);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Przypisz rodzica dla: ${child.commonName}"),
        content: potentialParents.isEmpty
            ? const Text("Brak zdefiniowanych obszarów spełniających wymogi hierarchii.")
            : SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text("Brak (Ustaw jako główny)"), onTap: () { vm.assignParent(child.id, null); Navigator.pop(ctx); }),
              ...potentialParents.map((p) => ListTile(title: Text(p.commonName), subtitle: Text(p.type), onTap: () { vm.assignParent(child.id, p.id); Navigator.pop(ctx); })).toList(),
            ],
          ),
        ),
      ),
    );
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