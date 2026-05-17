// lib/views/browse_plants_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../services/spatial_service.dart';
import 'species_details_screen.dart'; // Import nowego widoku szczegółów

class BrowsePlantsScreen extends StatelessWidget {
  const BrowsePlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    // MAPOWANIE I GRUPOWANIE: Zabezpieczenie przed dublowaniem rekordów
    final Map<String, List<PlantObservation>> groupedByCommonName = {};
    final Map<String, PlantSpecies?> representativeSpecies = {};

    for (var obs in obsVm.completeObservations) {
      final species = obsVm.getSpeciesById(obs.speciesId);
      final String name = (species?.polishName.isNotEmpty == true ? species!.polishName : obs.displayName).trim();
      final key = name.isEmpty ? "Nieznana roślina" : name;

      // APLIKOWANIE FILTRÓW GLOBALNYCH
      if (filterVm.selectedFamilies.isNotEmpty) {
        if (species == null || !filterVm.selectedFamilies.contains(species.family)) continue;
      }
      if (filterVm.filterDateRange != null) {
        final date = obs.observationDate ?? obs.timestamp;
        if (date.isBefore(filterVm.filterDateRange!.start) || date.isAfter(filterVm.filterDateRange!.end.add(const Duration(days: 1)))) continue;
      }
      if (filterVm.filterArea != null) {
        if (!SpatialService.isPointInPolygon(LatLng(obs.latitude, obs.longitude), filterVm.filterArea!.points)) continue;
      }

      groupedByCommonName.putIfAbsent(key, () => []).add(obs);
      if (species != null && !representativeSpecies.containsKey(key)) {
        representativeSpecies[key] = species;
      }
    }

    final sortedKeys = groupedByCommonName.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magazyn Gatunków'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: filterVm.filterDateRange);
              filterVm.setFilterDateRange(picked);
            },
          ),
          IconButton(icon: Icon(Icons.layers, color: filterVm.filterArea != null ? Colors.orange : null), onPressed: () => _showAreaFilterDialog(context, releveVm, filterVm)),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: () => filterVm.resetAllFilters()),
          IconButton(icon: Icon(Icons.account_tree_outlined, color: filterVm.selectedFamilies.isNotEmpty ? Colors.orange : null), onPressed: () => _showFamilyFilterDialog(context, obsVm, filterVm)),
        ],
      ),
      body: SafeArea(
        child: sortedKeys.isEmpty
            ? const Center(child: Text("Brak gatunków spełniających kryteria filtrów."))
            : ListView.builder(
          itemCount: sortedKeys.length,
          itemBuilder: (ctx, index) {
            final String nameKey = sortedKeys[index];
            final List<PlantObservation> speciesObservations = groupedByCommonName[nameKey]!;
            final PlantSpecies? speciesInfo = representativeSpecies[nameKey];

            // Wybór reprezentatywnego zdjęcia dla kafelka głównego
            final firstObsWithPhoto = speciesObservations.firstWhere((o) => o.photoPaths.isNotEmpty, orElse: () => speciesObservations.first);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: firstObsWithPhoto.photoPaths.isNotEmpty ? FileImage(File(firstObsWithPhoto.photoPaths.first)) : null,
                  child: firstObsWithPhoto.photoPaths.isEmpty ? const Icon(Icons.eco, color: Colors.teal) : null,
                ),
                title: Text(nameKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "${speciesInfo?.latinName ?? 'Brak nazwy łacińskiej'} (${speciesObservations.length} ${speciesObservations.length == 1 ? 'okaz' : 'okazów'})",
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                // NAWIGACJA DO PEŁNEGO WIDOKU MATRYCY
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpeciesDetailsScreen(
                      commonName: nameKey,
                      observations: speciesObservations,
                      species: speciesInfo,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFamilyFilterDialog(BuildContext context, ObservationViewModel obsVm, SearchFilterViewModel filterVm) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Filtruj rodziny"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: obsVm.uniqueFamilies.map((family) => CheckboxListTile(
                title: Text(family),
                value: filterVm.selectedFamilies.contains(family),
                onChanged: (val) {
                  filterVm.toggleFamilyFilter(family);
                  setDialogState(() {});
                },
              )).toList(),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
        ),
      ),
    );
  }

  void _showAreaFilterDialog(BuildContext context, ReleveViewModel releveVm, SearchFilterViewModel filterVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Filtruj według obszaru"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text("Wszystkie obszary"), onTap: () { filterVm.setFilterArea(null); Navigator.pop(ctx); }),
              const Divider(),
              ...releveVm.allReleves.map((releve) => ListTile(
                leading: const Icon(Icons.border_outer, color: Colors.indigo),
                title: Text(releve.commonName),
                subtitle: Text(releve.type),
                selected: filterVm.filterArea?.id == releve.id,
                onTap: () { filterVm.setFilterArea(releve); Navigator.pop(ctx); },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}