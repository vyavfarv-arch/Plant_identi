import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Dodano dla LatLng
import '../models/plant_observation.dart';
import '../viewmodels/observation_view_model.dart'; // Dane roślin
import '../viewmodels/releve_view_model.dart';    // Dane obszarów
import '../viewmodels/search_filter_view_model.dart'; // Stan filtrów
import '../services/spatial_service.dart'; // Logika geometryczna
import 'detail_description_screen.dart';
import 'plant_card_view.dart';

class BrowsePlantsScreen extends StatelessWidget {
  const BrowsePlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pobieramy dostęp do nowych modeli
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    // Ręczne filtrowanie listy obserwacji na podstawie stanu z filterVm
    final plants = obsVm.completeObservations.where((obs) {
      // Filtr daty
      if (filterVm.filterDateRange != null) {
        final date = obs.observationDate ?? obs.timestamp;
        if (date.isBefore(filterVm.filterDateRange!.start) ||
            date.isAfter(filterVm.filterDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Filtr rodziny
      if (filterVm.selectedFamilies.isNotEmpty) {
        if (obs.family == null || !filterVm.selectedFamilies.contains(obs.family)) {
          return false;
        }
      }

      // Filtr obszaru przy użyciu SpatialService
      if (filterVm.filterArea != null) {
        if (!SpatialService.isPointInPolygon(
            LatLng(obs.latitude, obs.longitude), filterVm.filterArea!.points)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magazyn Roślin'),
        actions: [
          // Filtr daty - korzysta z SearchFilterViewModel
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: filterVm.filterDateRange,
              );
              filterVm.setFilterDateRange(picked);
            },
          ),
          // Filtr obszaru
          IconButton(
            icon: Icon(
                Icons.layers,
                color: filterVm.filterArea != null ? Colors.orange : null
            ),
            onPressed: () => _showAreaFilterDialog(context, releveVm, filterVm),
          ),
          // Reset filtrów
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () => filterVm.resetAllFilters(),
          ),
          // Filtr rodzin
          IconButton(
            icon: Icon(Icons.account_tree_outlined,
                color: filterVm.selectedFamilies.isNotEmpty ? Colors.orange : null),
            onPressed: () => _showFamilyFilterDialog(context, obsVm, filterVm),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (plants.isEmpty) {
            return const Center(child: Text("Brak roślin spełniających kryteria filtrów."));
          }

          final Map<String, List<PlantObservation>> grouped = {};
          for (var p in plants) {
            final name = p.displayName;
            grouped.putIfAbsent(name, () => []).add(p);
          }

          return ListView(
            children: grouped.entries.map((entry) {
              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundImage: FileImage(File(entry.value.first.photoPaths.first)),
                ),
                title: Text("${entry.key} (${entry.value.length})"),
                children: entry.value
                    .map((obs) => _buildDetailTile(context, obs, obsVm))
                    .toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showFamilyFilterDialog(BuildContext context, ObservationViewModel obsVm, SearchFilterViewModel filterVm) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Filtruj według rodzin"),
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

  Widget _buildDetailTile(BuildContext context, PlantObservation obs, ObservationViewModel obsVm) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text("Obserwacja z ${DateFormat('yyyy-MM-dd').format(obs.observationDate ?? obs.timestamp)}"),
      subtitle: Text("Ilość: ${obs.abundance} | Pewność: ${obs.certainty ?? 'brak'}"),
      onTap: () => PlantCardView.show(context, obs),
      trailing: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'edit') {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs))
            );
          } else if (val == 'delete') {
            obsVm.deleteObservation(obs.id);
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'edit', child: Text('Edytuj opis')),
          const PopupMenuItem(value: 'delete', child: Text('Usuń rekord')),
        ],
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
              ListTile(
                title: const Text("Wszystkie obszary (Brak filtra)"),
                onTap: () {
                  filterVm.setFilterArea(null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ...releveVm.allReleves.map((releve) => ListTile(
                leading: const Icon(Icons.border_outer, color: Colors.indigo),
                title: Text(releve.commonName),
                subtitle: Text(releve.type),
                selected: filterVm.filterArea?.id == releve.id,
                onTap: () {
                  filterVm.setFilterArea(releve);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}