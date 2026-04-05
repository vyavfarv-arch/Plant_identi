import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/plants_view_model.dart';
import 'package:intl/intl.dart';

class BrowsePlantsScreen extends StatelessWidget {
  const BrowsePlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magazyn Roślin'),
        actions: [
          // PRZYCISK FILTROWANIA
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              context.read<PlantsViewModel>().setFilterDate(picked);
            },
          ),
          // RESET FILTRA
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () => context.read<PlantsViewModel>().setFilterDate(null),
          ),
        ],
      ),
      body: Consumer<PlantsViewModel>(
        builder: (context, vm, child) {
          final plants = vm.filteredCompleteObservations;

          if (plants.isEmpty) {
            return const Center(child: Text("Brak roślin spełniających kryteria."));
          }

          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final obs = plants[index];
              return ListTile(
                leading: Image.file(File(obs.photoPaths[0]), width: 50, height: 50, fit: BoxFit.cover),
                title: Text(obs.plantName ?? "Nieznana"),
                subtitle: Text("Data: ${DateFormat('yyyy-MM-dd').format(obs.observationDate!)}"),
                trailing: const Icon(Icons.more_vert),
              );
            },
          );
        },
      ),
    );
  }
}