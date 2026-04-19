import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/plants_view_model.dart';
import 'detail_description_screen.dart';
import 'plant_card_view.dart';

class ReleveDetailsScreen extends StatelessWidget {
  final Releve releve;
  const ReleveDetailsScreen({super.key, required this.releve});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();
    final plantsInArea = vm.getPlantsInReleve(releve);

    return Scaffold(
      appBar: AppBar(
        title: Text("${releve.type}: ${releve.name}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Liczba gatunków: ${plantsInArea.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Data: ${releve.date.toString().substring(0, 10)}"),
              ],
            ),
          ),
          Expanded(
            child: plantsInArea.isEmpty
                ? const Center(child: Text("Brak zaobserwowanych roślin w tym obszarze."))
                : ListView.builder(
              itemCount: plantsInArea.length,
              itemBuilder: (context, index) {
                final plant = plantsInArea[index];
                return ListTile(
                  leading: const Icon(Icons.eco, color: Colors.green),
                  title: Text(plant.displayName),
                  subtitle: Text(plant.latinName ?? "Brak nazwy łacińskiej"),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: () {
                    // ZMIANA: Zamiast Navigator.push do edycji, pokazujemy Kartę Rośliny
                    PlantCardView.show(context, plant);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}