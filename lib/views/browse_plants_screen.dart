// lib/views/browse_plants_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';
import 'detail_description_screen.dart';

class BrowsePlantsScreen extends StatelessWidget {
  const BrowsePlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magazyn Roślin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              context.read<PlantsViewModel>().setFilterDate(picked);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () => context.read<PlantsViewModel>().setFilterDate(null),
          ),
        ],
      ),
      body: Consumer<PlantsViewModel>(
        builder: (context, vm, child) {
          final plants = vm.filteredCompleteObservations;

          // GRUPOWANIE PO NAZWIE
          final Map<String, List<PlantObservation>> grouped = {};
          for (var p in plants) {
            final name = p.plantName ?? "Nieznana";
            grouped.putIfAbsent(name, () => []).add(p);
          }

          if (grouped.isEmpty) return const Center(child: Text("Brak opisanych roślin."));

          return ListView(
            children: grouped.entries.map((entry) {
              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundImage: FileImage(File(entry.value.first.photoPaths.first)),
                ),
                title: Text("${entry.key} (${entry.value.length})"),
                children: entry.value.map((obs) => _buildDetailTile(context, obs, vm)).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDetailTile(BuildContext context, PlantObservation obs, PlantsViewModel vm) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      title: Text("Obserwacja z ${DateFormat('yyyy-MM-dd').format(obs.observationDate!)}"),
      subtitle: Text("Ilość: ${obs.abundance}"),
      onTap: () => _showPlantCard(context, obs),
      trailing: PopupMenuButton<String>(
        onSelected: (val) {
          if (val == 'edit') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs)));
          } else if (val == 'delete') {
            vm.deleteObservation(obs.id);
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'edit', child: Text('Edytuj')),
          const PopupMenuItem(value: 'delete', child: Text('Usuń')),
        ],
      ),
    );
  }

  void _showPlantCard(BuildContext context, PlantObservation obs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(obs.plantName ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
            _infoRow("Ilościowość:", obs.abundance ?? "-"),
            _infoRow("Cechy:", obs.characteristics.join(", ")),
            _infoRow("GPS:", "${obs.latitude}, ${obs.longitude}"),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: obs.photoPaths.map((p) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.file(File(p)),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value)),
      ]),
    );
  }
}