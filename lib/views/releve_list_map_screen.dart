import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../models/releve.dart';
import 'releve_details_screen.dart';
import 'releve_map_screen.dart'; // Import ekranu rysowania obszarów

class ReleveListMapScreen extends StatefulWidget {
  const ReleveListMapScreen({super.key});

  @override
  State<ReleveListMapScreen> createState() => _ReleveListMapScreenState();
}

class _ReleveListMapScreenState extends State<ReleveListMapScreen> {
  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

    // Filtrowanie obszarów na podstawie stanu z SearchFilterViewModel
    final filteredReleves = releveVm.allReleves.where((r) {
      final matchesType = filterVm.selectedReleveTypes.contains(r.type);
      final matchesSearch = filterVm.areaSearchQuery.isEmpty ||
          r.commonName.toLowerCase().contains(filterVm.areaSearchQuery.toLowerCase()) ||
          r.phytosociologicalName.toLowerCase().contains(filterVm.areaSearchQuery.toLowerCase());

      final specificNames = filterVm.getSelectedNamesForRank(r.type) ?? {};
      final matchesSpecific = specificNames.isEmpty || specificNames.contains(r.commonName);

      return matchesType && matchesSearch && matchesSpecific;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa Obszarów"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, releveVm, filterVm),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              initialValue: filterVm.areaSearchQuery,
              onChanged: (v) => filterVm.setAreaSearchQuery(v),
              decoration: InputDecoration(
                labelText: "Szukaj po nazwie",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filterVm.areaSearchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => filterVm.clearAreaSearchQuery(),
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(52.0, 19.0), // Centrum Polski
                zoom: 6,
              ),
              mapType: MapType.satellite, // ZMIANA: Mapa satelitarna
              polygons: _buildPolygons(filteredReleves),
              myLocationEnabled: true,
            ),
          ),
        ],
      ),
      // PRZYCISK DODAWANIA OBSZARU
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReleveMapScreen()),
          );
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text("DODAJ OBSZAR", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Set<Polygon> _buildPolygons(List<Releve> releves) {
    return releves.map((r) {
      return Polygon(
        polygonId: PolygonId(r.id),
        points: r.points,
        strokeWidth: 3,
        strokeColor: _getColorForType(r.type),
        fillColor: _getColorForType(r.type).withValues(alpha: 0.35),
        consumeTapEvents: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ReleveDetailsScreen(releve: r),
            ),
          );
        },
      );
    }).toSet();
  }

  Color _getColorForType(String type) {
    switch (type) {
      case "Klasa": return Colors.red;
      case "Rząd": return Colors.orange;
      case "Związek": return Colors.purple;
      case "Zespół": return Colors.blue;
      default: return Colors.green;
    }
  }

  void _showFilterDialog(BuildContext context, ReleveViewModel releveVm, SearchFilterViewModel filterVm) {
    final ranks = ["Klasa", "Rząd", "Związek", "Zespół"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Filtruj Obszary"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ranks.map((rank) {
                    final uniqueNames = releveVm.allReleves
                        .where((r) => r.type == rank)
                        .map((r) => r.commonName)
                        .toSet()
                        .toList();

                    return ExpansionTile(
                      title: Row(
                        children: [
                          Checkbox(
                            value: filterVm.selectedReleveTypes.contains(rank),
                            onChanged: (val) {
                              filterVm.toggleReleveTypeFilter(rank);
                              setDialogState(() {});
                            },
                          ),
                          Text(rank, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      children: uniqueNames.map((name) {
                        return CheckboxListTile(
                          title: Text(name),
                          value: filterVm.isNameSelected(rank, name),
                          onChanged: (val) {
                            filterVm.toggleNameSelection(rank, name);
                            setDialogState(() {});
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("ZAMKNIJ"),
              )
            ],
          );
        },
      ),
    );
  }
}