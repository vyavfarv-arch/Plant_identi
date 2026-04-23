import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Dodano dla LatLng
import '../models/releve.dart';
import '../viewmodels/releve_view_model.dart'; // ZMIANA: Nowy ViewModel dla obszarów
import '../viewmodels/observation_view_model.dart'; // ZMIANA: Nowy ViewModel dla roślin
import '../services/spatial_service.dart'; // ZMIANA: Nowy serwis do analizy punktów
import 'plant_card_view.dart';
import 'habitat_form_screen.dart';

class ReleveDetailsScreen extends StatelessWidget {
  final Releve releve;
  const ReleveDetailsScreen({super.key, required this.releve});

  @override
  Widget build(BuildContext context) {
    // ZMIANA: Pobieramy dane z dwóch oddzielnych ViewModeli
    final releveVm = context.watch<ReleveViewModel>();
    final obsVm = context.watch<ObservationViewModel>();

    // ZMIANA: Wykorzystujemy SpatialService do znalezienia roślin w tym płacie
    final plantsInArea = SpatialService.getPlantsInArea(obsVm.completeObservations, releve);

    final parentArea = releveVm.getParentArea(releve.parentId);
    final childrenAreas = releveVm.getChildren(releve.id);

    return Scaffold(
      appBar: AppBar(
        // ZMIANA: Wyświetlamy nazwę zwyczajową płatu
        title: Text("${releve.type}: ${releve.commonName}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') _confirmDelete(context, releveVm);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Usuń obszar', style: TextStyle(color: Colors.red))
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // SEKCJA HIERARCHII
          _buildHierarchySection(context, releveVm, parentArea, childrenAreas),

          const Divider(height: 1),

          // STATYSTYKI
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
                "Gatunki w płacie (${plantsInArea.length}):",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),

          // LISTA ROŚLIN
          if (plantsInArea.isEmpty)
            const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("Brak zaobserwowanych roślin."))
            )
          else
            ...plantsInArea.map((plant) => ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: Text(plant.displayName),
              subtitle: Text(plant.latinName ?? "Brak nazwy łacińskiej"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => PlantCardView.show(context, plant),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildHierarchySection(BuildContext context, ReleveViewModel vm, Releve? parent, List<Releve> children) {
    // BUGFIX: Poprawne wyświetlanie dla Klasy i obsługa nowych nazw
    String parentTitle = releve.type == "Klasa"
        ? "Klasa (Jednostka nadrzędna)"
        : (parent != null ? "Nadrzędny: ${parent.commonName}" : "Brak obszaru nadrzędnego");

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.account_balance, color: Colors.blueGrey),
            title: Text(parentTitle),
            subtitle: Text(releve.type == "Klasa" ? "Status: Syntakson główny" : (parent?.type ?? "Kliknij, aby przypisać")),
            // Zablokuj edycję rodzica dla Klasy
            onTap: releve.type == "Klasa" ? null : () => _showAssignParentDialog(context, releve, vm),
          ),

          // PRZYCISK INFORMACJI O SIEDLISKU
          ListTile(
            leading: const Icon(Icons.landscape, color: Colors.brown),
            title: const Text("Informacje o siedlisku"),
            subtitle: Text(releve.habitat == null ? "Brak opisu gleby" : "Siedlisko opisane"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitatFormScreen(releve: releve))),
          ),

          // WIDOK DZIECI
          if (children.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.blueGrey),
              title: Text("Obszary podległe (${children.length})"),
              children: children.map((c) => ListTile(
                title: Text(c.commonName), // ZMIANA: commonName
                subtitle: Text("${c.type}: ${c.phytosociologicalName}"), // ZMIANA: phytoName
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
              ListTile(
                  title: const Text("Brak (Ustaw jako główny)"),
                  onTap: () { vm.assignParent(child.id, null); Navigator.pop(ctx); }
              ),
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

  void _confirmDelete(BuildContext context, ReleveViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń obszar"),
        content: const Text("Czy na pewno chcesz trwale usunąć ten płat?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.deleteReleve(releve.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("USUŃ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}