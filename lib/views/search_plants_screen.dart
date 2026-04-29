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
    Future.microtask(() => context.read<SearchFilterViewModel>().loadSoughtPlants());
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    final speciesItems = obsVm.speciesDictionary.map((s) => _SearchListItem(
      id: s.speciesID, name: s.polishName.isNotEmpty ? s.polishName : s.latinName, subtitle: "Magazyn (Zbadana)", isSought: false, originalObject: s,
    )).toList();

    final soughtItems = filterVm.soughtPlants.map((s) => _SearchListItem(
      id: s.id, name: s.polishName.isNotEmpty ? s.polishName : s.latinName, subtitle: "Poszukiwana (Tylko ML)", isSought: true, originalObject: s,
    )).toList();

    List<_SearchListItem> allItems = [...speciesItems, ...soughtItems];

    final filteredItems = allItems.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterType == "Magazyn") return matchesSearch && !p.isSought;
      if (_filterType == "Poszukiwane") return matchesSearch && p.isSought;
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Znajdź Obszary (ML)"),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: "Dodaj nowy cel poszukiwań", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSoughtPlantScreen()))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: "Wybierz roślinę do analizy...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
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
                  activeColor: Colors.deepOrange,
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.subtitle, style: TextStyle(color: item.isSought ? Colors.deepOrange : Colors.green)),
                  value: item.id,
                  groupValue: _selectedPlantId,
                  onChanged: (v) => setState(() => _selectedPlantId = v),
                  secondary: item.isSought ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      DatabaseHelper().deleteSoughtPlant(item.id);
                      filterVm.loadSoughtPlants();
                      if (_selectedPlantId == item.id) setState(() => _selectedPlantId = null);
                    },
                  ) : null,
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
      color: Colors.deepOrange.shade50,
      child: SizedBox(
        width: double.infinity, height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
          onPressed: () async {
            SoughtPlant targetPlant;
            String? knownSpeciesId;

            if (item.originalObject is SoughtPlant) {
              targetPlant = item.originalObject;
            } else {
              final sp = item.originalObject;
              knownSpeciesId = sp.speciesID; // Zapisujemy ID, jeśli to znana roślina
              targetPlant = SoughtPlant(
                id: sp.speciesID, polishName: sp.polishName, latinName: sp.latinName,
                prefPhMin: sp.prefPhMin, prefPhMax: sp.prefPhMax,
                prefAreaTypes: sp.prefAreaTypes, prefExposures: sp.prefExposures,
                prefCanopyCovers: sp.prefCanopyCovers, prefWaterDynamics: sp.prefWaterDynamics,
                prefSoilDepths: sp.prefSoilDepths,
              );
            }

            final resultsIds = _mlService.getMatchingAreas(targetPlant, releveVm.allReleves);
            final matchingObjects = releveVm.allReleves.where((r) => resultsIds.contains(r.id)).toList();

            if (matchingObjects.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Model ML nie wytypował żadnego odpowiedniego obszaru.")));
              return;
            }

            Navigator.push(context, MaterialPageRoute(
                builder: (_) => ResultsMapScreen(
                  matchingAreas: matchingObjects,
                  plantName: item.name,
                  speciesId: knownSpeciesId, // Przekazujemy na mapę
                )
            ));
          },
          icon: const Icon(Icons.map),
          label: Text("POKAŻ POTENCJALNE OBSZARY (${item.name.toUpperCase()})"),
        ),
      ),
    );
  }
}