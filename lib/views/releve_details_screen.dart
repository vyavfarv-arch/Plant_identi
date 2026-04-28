// lib/views/releve_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../models/plant_observation.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/spatial_service.dart';
import '../services/ml_prediction_service.dart';
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

    final currentReleve = releveVm.allReleves.firstWhere(
            (r) => r.id == widget.releve.id,
        orElse: () => widget.releve
    );

    // Podział na rośliny zaobserwowane (rzeczywiste) i przewidziane (potencjalne)
    final allPlantsInArea = obsVm.allObservations.where((o) => o.releveId == currentReleve.id).toList();
    final actualPlants = allPlantsInArea.where((o) => !o.isPotential).toList();
    final potentialPlants = allPlantsInArea.where((o) => o.isPotential).toList();

    final parentArea = releveVm.getParentArea(currentReleve.parentId);
    final childrenAreas = releveVm.getChildren(currentReleve.id);

    return Scaffold(
      appBar: AppBar(
        title: Text("${currentReleve.type}: ${currentReleve.commonName}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildHierarchySection(context, releveVm, parentArea, childrenAreas, currentReleve),
          const Divider(),

          // SEKCJA 1: GATUNKI W PŁACIE (RZECZYWISTE)
          _buildSectionHeader("Gatunki w płacie (${actualPlants.length}):", Colors.grey[100]!),
          ...actualPlants.map((plant) => _buildPlantTile(plant)),

          if (actualPlants.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Brak zaobserwowanych roślin."))),

          // SEKCJA 2: GATUNKI POTENCJALNE (ML)
          if (potentialPlants.isNotEmpty) ...[
            _buildSectionHeader("Przewidywane gatunki (Potencjalne):", Colors.purple.shade50),
            ...potentialPlants.map((plant) => _buildPlantTile(plant, isPotential: true)),
          ],

          const SizedBox(height: 30),

          // PRZYCISK NA SAMYM DOLE
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
                onPressed: _isAnalyzing ? null : () => _runMLAnalysis(currentReleve, obsVm),
                icon: _isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isAnalyzing ? "ANALIZOWANIE..." : "OKREŚL ROŚLINY POTENCJALNE"),
              ),
            ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: color,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildPlantTile(PlantObservation plant, {bool isPotential = false}) {
    return ListTile(
      leading: Icon(Icons.eco, color: isPotential ? Colors.purple : Colors.green),
      title: Text(plant.displayName),
      subtitle: Text(isPotential
          ? "Prawdopodobieństwo: ${(plant.predictionProbability! * 100).toStringAsFixed(0)}%"
          : (plant.latinName ?? "Brak nazwy łacińskiej")),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => PlantCardView.show(context, plant),
    );
  }

  void _runMLAnalysis(Releve area, ObservationViewModel obsVm) async {
    setState(() => _isAnalyzing = true);

    try {
      final mlService = MlPredictionService();
      await mlService.loadModel();
      final predictions = mlService.getPlantsForArea(area);

      int addedCount = 0;

      for (var entry in predictions.entries) {
        double prob = entry.value;

        // Zapisujemy tylko te powyżej 60%
        if (prob >= 0.6) {
          // Sprawdź czy już nie ma takiej rośliny potencjalnej w tym płacie
          bool exists = obsVm.allObservations.any((o) =>
          o.releveId == area.id &&
              o.isPotential &&
              (o.latinName == entry.key || o.localName == entry.key)
          );

          if (!exists) {
            final potPlant = PlantObservation(
              id: const Uuid().v4(),
              releveId: area.id,
              isPotential: true,
              predictionProbability: prob,
              latinName: entry.key, // Przypisujemy nazwę przewidzianą przez model
              photoPaths: [],
              latitude: area.points.isNotEmpty ? area.points.first.latitude : 0.0,
              longitude: area.points.isNotEmpty ? area.points.first.longitude : 0.0,
              timestamp: DateTime.now(),
              characteristics: {},
            );
            await obsVm.addObservation(potPlant);
            addedCount++;
          }
        }
      }

      if (mounted) {
        if (addedCount > 0) {
          // Sukces - znaleziono i dodano rośliny
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Analiza zakończona. Dodano $addedCount nowych gatunków potencjalnych."))
          );
        } else {
          // Porażka
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Brak wyników", style: TextStyle(color: Colors.orange)),
              content: const Text("Model nie znalazł żadnych roślin z prawdopodobieństwem powyżej 60% dla tego specyficznego siedliska."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Wystąpił błąd: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Widget _buildHierarchySection(BuildContext context, ReleveViewModel vm, Releve? parent, List<Releve> children, Releve currentReleve) {
    String parentTitle = currentReleve.type == "Klasa"
        ? "Klasa (Jednostka nadrzędna)"
        : (parent != null ? "Nadrzędny: ${parent.commonName}" : "Brak obszaru nadrzędnego");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -4),
            title: Text(parentTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(
                currentReleve.type == "Klasa" ? "Status: Syntakson główny" : (parent?.type ?? "Kliknij, aby przypisać"),
                style: const TextStyle(fontSize: 11)
            ),
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
                title: Text(c.commonName),
                subtitle: Text("${c.type}: ${c.phytosociologicalName}"),
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
              ...potentialParents.map((p) => ListTile(
                title: Text(p.commonName),
                subtitle: Text(p.type),
                onTap: () { vm.assignParent(child.id, p.id); Navigator.pop(ctx); },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}