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
            final name = p.displayName;
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
      title: Text("Obserwacja z ${DateFormat('yyyy-MM-dd').format(obs.observationDate ?? obs.timestamp)}"),
      subtitle: Text("Ilość: ${obs.abundance} | Pewność: ${obs.certainty ?? 'brak'}"),
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
          const PopupMenuItem(value: 'edit', child: Text('Edytuj opis')),
          const PopupMenuItem(value: 'delete', child: Text('Usuń rekord')),
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
        initialChildSize: 0.8,
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
              Text(obs.displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
              Text(obs.latinName ?? "Brak nazwy łacińskiej", style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
              const Divider(),

              // Galeria zdjęć
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

              _sectionHeader("1. Pozycja systematyczna"),
              _infoItem(Icons.account_tree, "Rodzina", obs.family ?? "-"),
              _infoItem(Icons.label, "Rodzaj", obs.genus ?? "-"),
              _infoItem(Icons.eco, "Gatunek", obs.species ?? "-"),

              _sectionHeader("2. Dane fitosocjologiczne"),
              _infoItem(Icons.layers, "Warstwa", obs.phytosociologicalLayer ?? "-"),
              _infoItem(Icons.analytics, "Ilościowość", obs.abundance ?? "-"),
              _infoItem(Icons.pie_chart, "Pokrycie", obs.coverage ?? "-"),
              _infoItem(Icons.favorite, "Żywotność", obs.vitality ?? "-"),

              _sectionHeader("3. Cechy charakterystyczne i pewność"),
              _infoItem(Icons.verified, "Stopień pewności", obs.certainty ?? "-"),
              _infoItem(Icons.psychology, "Wątpliwości", obs.idDoubts ?? "-"),
              _infoItem(Icons.star, "Cecha kluczowa", obs.characteristicFeature ?? "-"),

              _sectionHeader("4. Wykorzystanie i Hodowla"),
              _infoItem(Icons.handyman, "Zastosowanie", obs.plantUsage ?? "-"),
              _infoItem(Icons.home, "Hodowla", obs.cultivation ?? "-"),

              const SizedBox(height: 15),
              _sectionHeader("Cechy z terenu"),
              if (obs.characteristics.isEmpty)
                const Text("Brak dodatkowych cech.")
              else
                ...obs.characteristics.entries.map((e) => _infoItem(Icons.check_circle_outline, e.key, e.value)).toList(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 15),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}