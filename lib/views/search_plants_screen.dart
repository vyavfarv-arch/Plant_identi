import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../services/spatial_service.dart';
import 'add_sought_plant_screen.dart';
import '../models/plant_observation.dart';

class SearchPlantsScreen extends StatefulWidget {
  const SearchPlantsScreen({super.key});

  @override
  State<SearchPlantsScreen> createState() => _SearchPlantsScreenState();
}

class _SearchPlantsScreenState extends State<SearchPlantsScreen> {
  String? _selectedPlantId;
  String _searchQuery = "";
  String _filterType = "Wszystkie"; // Opcje: Wszystkie, Magazyn, Poszukiwane

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    // FILTRACJA LISTY
    final List<PlantObservation> filteredPlants = obsVm.allObservations.where((p) {
      final name = p.displayName.toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_filterType == "Magazyn") matchesFilter = !p.isSought;
      if (_filterType == "Poszukiwane") matchesFilter = p.isSought;

      return matchesSearch && matchesFilter && (p.localName != null);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Baza i Poszukiwania"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'add') Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSoughtPlantScreen()));
            },
            itemBuilder: (ctx) => [const PopupMenuItem(value: 'add', child: Text("Dodaj szukaną roślinę"))],
          )
        ],
      ),
      body: Column(
        children: [
          // PASEK WYSZUKIWANIA I FILTRY
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Szukaj rośliny...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Wszystkie", "Magazyn", "Poszukiwane"].map((type) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: _filterType == type,
                          onSelected: (val) => setState(() => _filterType = type),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // LISTA
          Expanded(
            child: filteredPlants.isEmpty
                ? const Center(child: Text("Nie znaleziono roślin."))
                : ListView.builder(
              itemCount: filteredPlants.length,
              itemBuilder: (context, index) {
                final plant = filteredPlants[index];
                return RadioListTile<String>(
                  title: Text(plant.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plant.isSought ? "TAG: POSZUKIWANA" : "W MAGAZYNIE"),
                  secondary: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showPlantEcoDetails(context, plant, obsVm, releveVm),
                  ),
                  value: plant.id,
                  groupValue: _selectedPlantId,
                  onChanged: (v) => setState(() => _selectedPlantId = v),
                );
              },
            ),
          ),
          if (_selectedPlantId != null)
            _buildActionFooter(filteredPlants.firstWhere((p) => p.id == _selectedPlantId)),
        ],
      ),
    );
  }

  Widget _buildActionFooter(PlantObservation plant) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          onPressed: () => print("Analiza ML dla ${plant.displayName}"),
          icon: const Icon(Icons.psychology),
          label: const Text("WYSZUKAJ OBSZARY"),
        ),
      ),
    );
  }

  void _showPlantEcoDetails(BuildContext context, PlantObservation plant, ObservationViewModel obsVm, ReleveViewModel releveVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(plant.displayName)),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () {
                obsVm.deleteObservation(plant.id);
                Navigator.pop(ctx);
                setState(() => _selectedPlantId = null);
              },
            )
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Charakterystyka siedliska:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const Divider(),
              Text("pH: ${plant.prefPhMin?.toStringAsFixed(1) ?? '?' } - ${plant.prefPhMax?.toStringAsFixed(1) ?? '?' }"),
              Text("Podłoże: ${plant.prefSubstrate.isNotEmpty ? plant.prefSubstrate.join(", ") : "brak" }"),
              Text("Wilgotność: ${_translateSingleMoisture(plant.prefMoisture)}"),
              const SizedBox(height: 10),
              if (plant.isSought) const Text("Status: POSZUKIWANA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ"))],
      ),
    );
  }

  String _translateSingleMoisture(double? v) {
    if (v == null) return "brak danych";
    return ["Sucho", "Świeżo", "Wilgotno", "Mokro"][v.round()];
  }
}