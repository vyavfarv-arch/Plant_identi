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

          final Map<String, List<PlantObservation>> grouped = {};
          for (var p in plants) {
            final name = p.displayName; // Poprawione
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text(obs.displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)), // Poprawione
              const Divider(),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: obs.photoPaths.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(obs.photoPaths[i]), width: 240, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _infoItem(Icons.analytics, "Ilościowość", obs.abundance ?? "-"),
              _infoItem(Icons.calendar_today, "Data obserwacji", DateFormat('yyyy-MM-dd').format(obs.observationDate!)),
              _infoItem(Icons.location_on, "GPS", "${obs.latitude.toStringAsFixed(6)}, ${obs.longitude.toStringAsFixed(6)}"),
              const Divider(),
              if (obs.characteristics.isNotEmpty)
                ...obs.characteristics.entries.map((e) => _infoItem(Icons.eco_outlined, e.key, e.value)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 15),
          Expanded(child: Text("$label: $value", style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}