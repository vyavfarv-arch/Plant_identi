import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/releve_view_model.dart'; // ZMIANA: Import właściwego ViewModelu

class AreaManagementScreen extends StatelessWidget {
  const AreaManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ZMIANA: Watchujemy ReleveViewModel zamiast PlantsViewModel
    final releveVm = context.watch<ReleveViewModel>();

    // Pokazujemy tylko elementy "główne" (bez rodzica) na szczycie listy
    final rootAreas = releveVm.allReleves.where((r) => r.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Struktura i Porządkowanie")),
      body: ListView.builder(
        itemCount: rootAreas.length,
        itemBuilder: (context, index) => _buildAreaTile(context, rootAreas[index], releveVm),
      ),
    );
  }

  Widget _buildAreaTile(BuildContext context, Releve area, ReleveViewModel vm, [int depth = 0]) {
    final children = vm.getChildren(area.id);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 * (depth + 1)),
          leading: Icon(_getIcon(area.type), color: _getColor(area.type)),
          // ZMIANA: area.name -> area.commonName
          title: Text(area.commonName),
          subtitle: Text("${area.type}: ${area.phytosociologicalName}"),
          trailing: IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            onPressed: () => _showAssignParentDialog(context, area, vm),
          ),
        ),
        if (children.isNotEmpty)
          ...children.map((child) => _buildAreaTile(context, child, vm, depth + 1)).toList(),
      ],
    );
  }

  void _showAssignParentDialog(BuildContext context, Releve child, ReleveViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Przypisz nadrzędny dla: ${child.commonName}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text("Brak (Ustaw jako główny)"),
                onTap: () {
                  vm.assignParent(child.id, null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              // Można przypisać tylko do obszarów spełniających logikę hierarchii
              ...vm.allReleves.where((r) => r.id != child.id && vm.isValidParent(child.type, r.type)).map((potentialParent) => ListTile(
                title: Text(potentialParent.commonName),
                subtitle: Text(potentialParent.type),
                onTap: () {
                  vm.assignParent(child.id, potentialParent.id);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    if (type == "Klasa") return Icons.account_balance;
    if (type == "Rząd") return Icons.reorder;
    return Icons.eco;
  }

  Color _getColor(String type) {
    switch (type) {
      case "Klasa": return Colors.red;
      case "Rząd": return Colors.orange;
      case "Związek": return Colors.purple;
      case "Zespół": return Colors.blue;
      default: return Colors.green;
    }
  }
}