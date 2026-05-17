// lib/views/browse_plants_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart'; // DODANY IMPORT
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../services/spatial_service.dart';
import 'detail_description_screen.dart';
import 'species_card_view.dart';
import 'plant_card_view.dart';

class BrowsePlantsScreen extends StatelessWidget {
  const BrowsePlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    final filteredSpecies = obsVm.speciesDictionary.where((species) {
      final speciesObs = obsVm.completeObservations.where((o) => o.speciesId == species.speciesID).toList();
      if (speciesObs.isEmpty) return false;

      if (filterVm.selectedFamilies.isNotEmpty && !filterVm.selectedFamilies.contains(species.family)) {
        return false;
      }

      if (filterVm.filterArea != null || filterVm.filterDateRange != null) {
        bool hasMatchingObservation = speciesObs.any((obs) {
          if (filterVm.filterDateRange != null) {
            final date = obs.observationDate ?? obs.timestamp;
            if (date.isBefore(filterVm.filterDateRange!.start) || date.isAfter(filterVm.filterDateRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }
          if (filterVm.filterArea != null) {
            if (!SpatialService.isPointInPolygon(LatLng(obs.latitude, obs.longitude), filterVm.filterArea!.points)) {
              return false;
            }
          }
          return true;
        });
        if (!hasMatchingObservation) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magazyn Gatunków'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: () async {
            final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: filterVm.filterDateRange);
            filterVm.setFilterDateRange(picked);
          }),
          IconButton(icon: Icon(Icons.layers, color: filterVm.filterArea != null ? Colors.orange : null), onPressed: () => _showAreaFilterDialog(context, releveVm, filterVm)),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: () => filterVm.resetAllFilters()),
          IconButton(icon: Icon(Icons.account_tree_outlined, color: filterVm.selectedFamilies.isNotEmpty ? Colors.orange : null), onPressed: () => _showFamilyFilterDialog(context, obsVm, filterVm)),
        ],
      ),
      body: SafeArea(
        child: filteredSpecies.isEmpty
            ? const Center(child: Text("Brak gatunków spełniających kryteria."))
            : ListView.builder(
          itemCount: filteredSpecies.length,
          itemBuilder: (ctx, index) {
            final species = filteredSpecies[index];
            final speciesObs = obsVm.completeObservations.where((o) => o.speciesId == species.speciesID).toList();
            final firstObsWithPhoto = speciesObs.firstWhere((o) => o.photoPaths.isNotEmpty, orElse: () => speciesObs.first);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: firstObsWithPhoto.photoPaths.isNotEmpty ? FileImage(File(firstObsWithPhoto.photoPaths.first)) : null,
                  child: firstObsWithPhoto.photoPaths.isEmpty ? const Icon(Icons.eco, color: Colors.teal) : null,
                ),
                title: Text(species.polishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${species.latinName} (${speciesObs.length} okazów)", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: Colors.teal),
                  tooltip: "Skumulowany Atlas Gatunku",
                  onPressed: () => SpeciesCardView.show(context, species, speciesObs),
                ),
                children: speciesObs.map((obs) => _buildObservationDetailTile(context, obs, obsVm)).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildObservationDetailTile(BuildContext context, PlantObservation obs, ObservationViewModel obsVm) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      dense: true,
      leading: const Icon(Icons.history_toggle_off, size: 18, color: Colors.blueGrey),
      title: Text("Okaz z terenu: ${DateFormat('yyyy-MM-dd').format(obs.observationDate ?? obs.timestamp)}"),
      subtitle: Text("Witalność: ${obs.vitality ?? '-'} | Ilość: ${obs.abundance ?? '-'}"),
      onTap: () => PlantCardView.show(context, obs),
      trailing: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'edit') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs)));
          } else if (val == 'delete') {
            obsVm.deleteObservation(obs.id);
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'edit', child: Text('Uzupełnij/Edytuj cechy')),
          const PopupMenuItem(value: 'delete', child: Text('Usuń ten rekord')),
        ],
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