import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../services/location_service.dart';
import 'releve_map_screen.dart';
import 'releve_details_screen.dart';

class ReleveListMapScreen extends StatefulWidget {
  const ReleveListMapScreen({super.key});

  @override
  State<ReleveListMapScreen> createState() => _ReleveListMapScreenState();
}

class _ReleveListMapScreenState extends State<ReleveListMapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  Future<void> _centerOnUser() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

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
        title: const Text("Zapisane obszary"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showTypeFilterDialog(context, releveVm, filterVm),
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
              initialCameraPosition: const CameraPosition(target: LatLng(52.0, 19.0), zoom: 6),
              mapType: MapType.satellite,
              myLocationEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                _centerOnUser();
              },
              polygons: filteredReleves.map((releve) => Polygon(
                polygonId: PolygonId(releve.id),
                points: releve.points,
                fillColor: _getColorForType(releve.type).withOpacity(0.35),
                strokeColor: _getColorForType(releve.type),
                strokeWidth: 3,
                consumeTapEvents: true,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: releve))
                  );
                },
              )).toSet(),
            ),
          ),
        ],
      ),
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

  Color _getColorForType(String type) {
    switch (type) {
      case "Zespół": return Colors.blue;
      case "Związek": return Colors.purple;
      case "Rząd": return Colors.orange;
      case "Klasa": return Colors.red;
      default: return Colors.green;
    }
  }

  void _showTypeFilterDialog(BuildContext context, ReleveViewModel vm, SearchFilterViewModel filterVm) {
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
                children: ["Klasa", "Rząd", "Związek", "Zespół"].map((rank) {
                  final uniqueNames = vm.allReleves
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
                            setStateDialog(() {});
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
                          setStateDialog(() {});
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
                child: const Text("ZAMKNIJ")
            )
          ],
        ),
      ),
    );
  }
}