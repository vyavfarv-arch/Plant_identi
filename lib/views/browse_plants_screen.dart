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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text(obs.plantName ?? "Bez nazwy", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(),

              // Sekcja zdjęć
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

              // Podstawowe informacje
              _infoItem(Icons.analytics, "Ilościowość", obs.abundance ?? "-"),
              _infoItem(Icons.calendar_today, "Data obserwacji", DateFormat('yyyy-MM-dd').format(obs.observationDate!)),
              _infoItem(Icons.location_on, "GPS", "${obs.latitude.toStringAsFixed(6)}, ${obs.longitude.toStringAsFixed(6)}"),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text("Szczegóły morfologiczne:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              // DYNAMICZNE WYŚWIETLANIE KATEGORII Z FORMULARZA
              if (obs.characteristics.isEmpty)
                const Text("Brak dodatkowych cech opisowych.")
              else
                ...obs.characteristics.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.label_important_outline, size: 20, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black, fontSize: 15),
                            children: [
                              TextSpan(text: "${entry.key}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: entry.value),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              const SizedBox(height: 30),
            ],
          ),
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