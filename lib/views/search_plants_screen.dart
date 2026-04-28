// lib/views/search_plants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../services/ml_prediction_service.dart';
import '../services/database_helper.dart';
import 'add_sought_plant_screen.dart';
import 'results_map_screen.dart';
import '../models/sought_plant.dart';

class _SearchListItem {
  final String id;
  final String name;
  final String subtitle;
  final bool isSought;
  final dynamic originalObject;
  _SearchListItem({required this.id, required this.name, required this.subtitle, required this.isSought, required this.originalObject});
}

class SearchPlantsScreen extends StatefulWidget {
  const SearchPlantsScreen({super.key});

  @override
  State<SearchPlantsScreen> createState() => _SearchPlantsScreenState();
}

class _SearchPlantsScreenState extends State<SearchPlantsScreen> {
  String? _selectedPlantId;
  String _searchQuery = "";
  String _filterType = "Wszystkie";

  final MlPredictionService _mlService = MlPredictionService();

  @override
  void initState() {
    super.initState();
    _mlService.loadModel();
    // Odświeżenie roślin poszukiwanych na wejściu w ekran
    Future.microtask(() => context.read<SearchFilterViewModel>().loadSoughtPlants());
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    // 1. Mapujemy Słownik Gatunków
    final speciesItems = obsVm.speciesDictionary.map((s) => _SearchListItem(
      id: s.speciesID,
      name: s.polishName.isNotEmpty ? s.polishName : s.latinName,
      subtitle: "W MAGAZYNIE",
      isSought: false,
      originalObject: s,
    )).toList();

    // 2. Mapujemy Rośliny Poszukiwane
    final soughtItems = filterVm.soughtPlants.map((s) => _SearchListItem(
      id: s.id,
      name: s.polishName.isNotEmpty ? s.polishName : s.latinName,
      subtitle: "POSZUKIWANA",
      isSought: true,
      originalObject: s,
    )).toList();

    // 3. Łączymy i filtrujemy
    List<_SearchListItem> allItems = [...speciesItems, ...soughtItems];

    final filteredItems = allItems.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesFilter = true;
      if (_filterType == "Magazyn") matchesFilter = !p.isSought;
      if (_filterType == "Poszukiwane") matchesFilter = p.isSought;

      return matchesSearch && matchesFilter;
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: "Szukaj rośliny...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["Wszystkie", "Magazyn", "Poszukiwane"].map((type) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(label: Text(type), selected: _filterType == type, onSelected: (val) => setState(() => _filterType = type)),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return RadioListTile<String>(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.subtitle),
                  secondary: IconButton(
                    icon: Icon(Icons.info_outline, color: item.isSought ? Colors.orange : Colors.green),
                    onPressed: () => _showPlantEcoDetails(context, item, filterVm, releveVm),
                  ),
                  value: item.id,
                  groupValue: _selectedPlantId,
                  onChanged: (v) => setState(() => _selectedPlantId = v),
                );
              },
            ),
          ),
          if (_selectedPlantId != null)
            _buildActionFooter(allItems.firstWhere((p) => p.id == _selectedPlantId), releveVm),
        ],
      ),
    );
  }

  Widget _buildActionFooter(_SearchListItem item, ReleveViewModel releveVm) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            // Zamieniamy na SoughtPlant dla algorytmu ML, żeby miał jednorodny input
            SoughtPlant targetPlant;
            if (item.originalObject is SoughtPlant) {
              targetPlant = item.originalObject;
            } else {
              final sp = item.originalObject; // PlantSpecies
              targetPlant = SoughtPlant(
                id: sp.speciesID, polishName: sp.polishName, latinName: sp.latinName,
                prefPhMin: sp.prefPhMin, prefPhMax: sp.prefPhMax, prefSubstrate: sp.prefSubstrate,
                prefMoisture: sp.prefMoisture, prefSunlight: sp.prefSunlight,
              );
            }

            final resultsIds = _mlService.getMatchingAreas(targetPlant, releveVm.allReleves);

            final matchingObjects = releveVm.allReleves.where((r) => resultsIds.contains(r.id)).toList();

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analiza zakończona. Znaleziono ${resultsIds.length} obszarów.")));

            if (matchingObjects.isNotEmpty) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ResultsMapScreen(matchingAreas: matchingObjects, plantName: item.name)
              ));
            }
          },
          icon: const Icon(Icons.search),
          label: const Text("ZNAJDŹ OBSZARY (ML)"),
        ),
      ),
    );
  }

  void _showPlantEcoDetails(BuildContext context, _SearchListItem item, SearchFilterViewModel filterVm, ReleveViewModel releveVm) {
    String ph = "? - ?";
    String substrate = "Brak";

    if (item.originalObject is SoughtPlant) {
      final p = item.originalObject as SoughtPlant;
      ph = "${p.prefPhMin?.toStringAsFixed(1) ?? '?'} - ${p.prefPhMax?.toStringAsFixed(1) ?? '?'}";
      substrate = p.prefSubstrate.isNotEmpty ? p.prefSubstrate.join(', ') : 'Brak';
    } else {
      final p = item.originalObject; // PlantSpecies
      ph = "${p.prefPhMin?.toStringAsFixed(1) ?? '?'} - ${p.prefPhMax?.toStringAsFixed(1) ?? '?'}";
      substrate = p.prefSubstrate.isNotEmpty ? p.prefSubstrate.join(', ') : 'Brak';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(item.name)),
            if (item.isSought) // Usuwanie dozwolone tylko dla Poszukiwanych
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () {
                  DatabaseHelper().deleteSoughtPlant(item.id);
                  filterVm.loadSoughtPlants();
                  Navigator.pop(ctx);
                  setState(() => _selectedPlantId = null);
                },
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ekologia i siedlisko:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("pH: $ph"),
            Text("Podłoże: $substrate"),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ"))],
      ),
    );
  }
}