import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/plants_view_model.dart';
import 'plant_card_view.dart';

class ReleveDetailsScreen extends StatelessWidget {
  final Releve releve;
  const ReleveDetailsScreen({super.key, required this.releve});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();
    final plantsInArea = vm.getPlantsInReleve(releve);
    final parentArea = vm.getParentArea(releve.parentId);
    final childrenAreas = vm.getChildren(releve.id);

    return Scaffold(
      appBar: AppBar(
        title: Text("${releve.type}: ${releve.name}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Ikona 3 kropek z opcjami
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') _confirmDelete(context, vm);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'delete', child: Text('Usuń obszar całkowicie', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // SEKCJA HIERARCHII
          _buildHierarchySection(context, vm, parentArea, childrenAreas),

          const Divider(height: 1),

          // STATYSTYKI
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text("Gatunki w płacie (${plantsInArea.length}):",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // LISTA ROŚLIN
          if (plantsInArea.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Brak zaobserwowanych roślin.")))
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

  Widget _buildHierarchySection(BuildContext context, PlantsViewModel vm, Releve? parent, List<Releve> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // WIDOK RODZICA
          ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_upward, color: Colors.blueGrey),
            title: Text(parent != null ? "Nadrzędny: ${parent.name}" : "Brak obszaru nadrzędnego"),
            subtitle: Text(parent?.type ?? "Kliknij aby przypisać zgodnie z hierarchią"),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showAssignParentDialog(context, releve, vm),
          ),

          // WIDOK DZIECI
          if (children.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.blueGrey),
              title: Text("Obszary podległe (${children.length})"),
              children: children.map((c) => ListTile(
                title: Text(c.name),
                subtitle: Text(c.type),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: c))),
              )).toList(),
            ),
        ],
      ),
    );
  }

  void _showAssignParentDialog(BuildContext context, Releve child, PlantsViewModel vm) {
    final potentialParents = vm.getPotentialParents(child);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Przypisz ${child.type == 'Klasa' ? 'brak' : 'rodzica dla ' + child.name}"),
        content: potentialParents.isEmpty && child.type != "Klasa"
            ? const Text("Brak zdefiniowanych obszarów spełniających wymogi hierarchii.")
            : SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text("Brak (Ustaw jako główny)"), onTap: () { vm.assignParent(child.id, null); Navigator.pop(ctx); }),
              ...potentialParents.map((p) => ListTile(
                title: Text(p.name),
                subtitle: Text(p.type),
                onTap: () { vm.assignParent(child.id, p.id); Navigator.pop(ctx); },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlantsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń obszar"),
        content: const Text("Czy na pewno chcesz trwale usunąć ten płat?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { vm.deleteReleve(releve.id); Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text("USUŃ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}