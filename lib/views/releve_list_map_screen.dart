import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/releve_view_model.dart'; // ZMIANA: Import właściwego VM
import 'releve_map_screen.dart';
import 'releve_details_screen.dart';

class ReleveListMapScreen extends StatelessWidget {
  const ReleveListMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ZMIANA: Korzystamy z ReleveViewModel zamiast PlantsViewModel
    final releveVm = context.watch<ReleveViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zapisane obszary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showTypeFilterDialog(context, releveVm),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 12),
        mapType: MapType.hybrid,
        // ZMIANA: VM posiada własny getter filteredReleves uwzględniający nazwy i typy
        polygons: releveVm.filteredReleves.map((releve) => Polygon(
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

  void _showTypeFilterDialog(BuildContext context, ReleveViewModel vm) {
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
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Wybierz typy i konkretne płaty:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Divider(),

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

  void _showEditDeleteDialog(BuildContext context, Releve releve, ReleveViewModel vm) {
    // ZMIANA: Obsługa dwóch nazw w edycji
    final commonNameController = TextEditingController(text: releve.commonName);
    final phytoNameController = TextEditingController(text: releve.phytosociologicalName);
    String currentType = releve.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Edytuj: ${releve.commonName}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: commonNameController, decoration: const InputDecoration(labelText: "Nazwa zwyczajowa")),
              TextField(controller: phytoNameController, decoration: const InputDecoration(labelText: "Nazwa fitosocjologiczna")),
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
                // ZMIANA: Wywołanie aktualizacji z dwiema nazwami
                vm.updateReleve(releve.id, commonNameController.text, phytoNameController.text, currentType);
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