import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/plants_view_model.dart';

class AreaManagementScreen extends StatelessWidget {
  const AreaManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();
    // Pokazujemy tylko elementy "główne" (bez rodzica) na szczycie listy
    final rootAreas = vm.allReleves.where((r) => r.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Struktura i Porządkowanie")),
      body: ListView.builder(
        itemCount: rootAreas.length,
        itemBuilder: (context, index) => _buildAreaTile(context, rootAreas[index], vm),
      ),
    );
  }

  Widget _buildAreaTile(BuildContext context, Releve area, PlantsViewModel vm, [int depth = 0]) {
    final children = vm.getChildren(area.id);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 * (depth + 1)),
          leading: Icon(_getIcon(area.type), color: _getColor(area.type)),
          title: Text(area.name),
          subtitle: Text(area.type),
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

  void _showAssignParentDialog(BuildContext context, Releve child, PlantsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Przypisz nadrzędny dla: ${child.name}"),
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
              // Można przypisać tylko do obszarów o "szerszym" znaczeniu (uproszczone)
              ...vm.allReleves.where((r) => r.id != child.id).map((potentialParent) => ListTile(
                title: Text(potentialParent.name),
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
    if (type == "Klasa") return Colors.red;
    if (type == "Rząd") return Colors.orange;
    return Colors.blue;
  }
}