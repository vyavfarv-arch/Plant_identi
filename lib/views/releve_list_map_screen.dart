import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/plants_view_model.dart';
import 'releve_map_screen.dart';
import 'releve_details_screen.dart';

class ReleveListMapScreen extends StatelessWidget {
  const ReleveListMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zapisane obszary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showTypeFilterDialog(context, vm),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 12),
        mapType: MapType.hybrid,
        polygons: vm.filteredReleves.map((releve) => Polygon(
          polygonId: PolygonId(releve.id),
          points: releve.points,
          fillColor: _getColorForType(releve.type).withOpacity(0.4),
          strokeColor: _getColorForType(releve.type),
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: releve))
            );
          },
        )).toSet(),
      ),
      // PRZYCISK DODAWANIA (PLUS)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReleveMapScreen())
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case "Zespół": return Colors.blue;
      case "Związek": return Colors.purple;
      case "Rząd": return Colors.orange;
      case "Klasa": return Colors.red;
      default: return Colors.green;
    }
  }

  void _showTypeFilterDialog(BuildContext context, PlantsViewModel vm) {
    final searchController = TextEditingController(text: vm.areaSearchQuery);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Filtruj obszary"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Poprawiona wyszukiwarka z przyciskiem CZYSZCZENIA
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Szukaj po nazwie",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          vm.clearAreaSearchQuery();
                          setStateDialog(() {});
                        },
                      )
                          : null,
                    ),
                    onChanged: (v) {
                      vm.setAreaSearchQuery(v);
                      setStateDialog(() {}); // Odśwież widok ikony czyszczenia
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Wybierz typy i konkretne płaty:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Divider(),

                  // Hierarchiczny Multiselect dla każdego typu
                  ...["Zespół", "Związek", "Rząd", "Klasa"].map((rank) {
                    final names = vm.getUniqueNamesForRank(rank);
                    return ExpansionTile(
                      leading: Checkbox(
                        value: vm.selectedReleveTypes.contains(rank),
                        onChanged: (val) {
                          vm.toggleReleveTypeFilter(rank);
                          setStateDialog(() {});
                        },
                      ),
                      title: Text(rank),
                      children: names.isEmpty
                          ? [const Padding(padding: EdgeInsets.all(8), child: Text("Brak zapisanych nazw"))]
                          : names.map((name) => CheckboxListTile(
                        dense: true,
                        title: Text(name),
                        value: vm.isNameSelected(rank, name),
                        onChanged: (val) {
                          vm.toggleNameSelection(rank, name);
                          setStateDialog(() {});
                        },
                      )).toList(),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK")
            )
          ],
        ),
      ),
    );
  }

  // ... (Metoda _showEditDeleteDialog pozostaje bez zmian jak w Twoim pliku) ...
  void _showEditDeleteDialog(BuildContext context, Releve releve, PlantsViewModel vm) {
    final nameController = TextEditingController(text: releve.name);
    String currentType = releve.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Edytuj: ${releve.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nazwa")),
              DropdownButtonFormField<String>(
                value: currentType,
                items: ["Zespół", "Związek", "Rząd", "Klasa"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setStateDialog(() => currentType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                vm.deleteReleve(releve.id);
                Navigator.pop(ctx);
              },
              child: const Text("USUŃ", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                vm.updateReleve(releve.id, nameController.text, currentType);
                Navigator.pop(ctx);
              },
              child: const Text("ZAPISZ ZMIANY"),
            ),
          ],
        ),
      ),
    );
  }
}