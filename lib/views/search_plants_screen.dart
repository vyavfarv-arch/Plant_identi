// lib/views/search_plants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../services/ml_prediction_service.dart';
import 'add_sought_plant_screen.dart';
import 'results_map_screen.dart';
import '../models/sought_plant.dart';
import '../models/releve.dart';
import 'plant_card_view.dart'; // IMPORT KARTY

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

  // LOGIKA PRZYTRZYMANIA (LONG PRESS)
  void _handleLongPress(BuildContext context, _SearchListItem item) {
    final obsVm = context.read<ObservationViewModel>();

    if (!item.isSought) {
      // Jeśli to roślina z magazynu, znajdź dowolną obserwację tego gatunku, by pokazać kartę
      try {
        final obs = obsVm.allObservations.firstWhere((o) => o.speciesId == item.id);
        PlantCardView.show(context, obs);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Brak szczegółowych danych obserwacji dla tego gatunku.")));
      }
    } else {
      // Jeśli to poszukiwana, otwórz dialog (podobnie jak w Terminarzu)
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(item.name),
          content: const Text("To jest roślina poszukiwana. Czy chcesz przejść do edycji jej wymagań?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSoughtPlantScreen()));
                },
                child: const Text("EDYTUJ")
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();
    final releveVm = context.read<ReleveViewModel>();

    final Map<String, _SearchListItem> uniqueItemsMap = {};
    for (var s in obsVm.speciesDictionary) {
      final nameKey = s.latinName.isNotEmpty ? s.latinName.toLowerCase() : s.polishName.toLowerCase();
      if (!uniqueItemsMap.containsKey(nameKey)) {
        uniqueItemsMap[nameKey] = _SearchListItem(id: s.speciesID, name: s.polishName.isNotEmpty ? s.polishName : s.latinName, subtitle: "Magazyn (Zbadana)", isSought: false, originalObject: s);
      }
    }
    for (var s in filterVm.soughtPlants) {
      final nameKey = s.latinName.isNotEmpty ? s.latinName.toLowerCase() : s.polishName.toLowerCase();
      if (!uniqueItemsMap.containsKey(nameKey)) {
        uniqueItemsMap[nameKey] = _SearchListItem(id: s.id, name: s.polishName.isNotEmpty ? s.polishName : s.latinName, subtitle: "Poszukiwana (Tylko ML)", isSought: true, originalObject: s);
      }
    }

    List<_SearchListItem> allItems = uniqueItemsMap.values.toList();
    final filteredItems = allItems.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterType == "Magazyn") return matchesSearch && !p.isSought;
      if (_filterType == "Poszukiwane") return matchesSearch && p.isSought;
      return matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Znajdź Obszary (ML)"), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSoughtPlantScreen())))]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(decoration: const InputDecoration(hintText: "Szukaj...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()), onChanged: (v) => setState(() => _searchQuery = v)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return GestureDetector( // OPAKOWANIE W GESTURE DETECTOR
                  onLongPress: () => _handleLongPress(context, item),
                  child: RadioListTile<String>(
                    activeColor: Colors.deepOrange,
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.subtitle, style: TextStyle(color: item.isSought ? Colors.deepOrange : Colors.green)),
                    value: item.id,
                    groupValue: _selectedPlantId,
                    onChanged: (v) => setState(() => _selectedPlantId = v),
                  ),
                );
              },
            ),
          ),
          if (_selectedPlantId != null) _buildActionFooter(allItems.firstWhere((p) => p.id == _selectedPlantId), releveVm),
        ],
      ),
    );
  }

  // ... (metoda _buildActionFooter pozostaje bez zmian jak ostatnio)
  Widget _buildActionFooter(_SearchListItem item, ReleveViewModel releveVm) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepOrange.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
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
                  knownSpeciesId = sp.speciesID;
                  targetPlant = SoughtPlant(id: sp.speciesID, polishName: sp.polishName, latinName: sp.latinName, prefPhMin: sp.prefPhMin, prefPhMax: sp.prefPhMax, prefAreaTypes: sp.prefAreaTypes, prefExposures: sp.prefExposures, prefCanopyCovers: sp.prefCanopyCovers, prefWaterDynamics: sp.prefWaterDynamics, prefSoilDepths: sp.prefSoilDepths);
                }
                final resultsIds = _mlService.getMatchingAreas(targetPlant, releveVm.allReleves);
                final matchingObjects = releveVm.allReleves.where((r) => resultsIds.contains(r.id)).toList();
                if (matchingObjects.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Brak dopasowań ML.")));
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsMapScreen(matchingAreas: matchingObjects, plantName: item.name, speciesId: knownSpeciesId)));
              },
              icon: const Icon(Icons.map), label: const Text("POKAŻ POTENCJALNE OBSZARY ML"),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 45,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.deepOrange, side: const BorderSide(color: Colors.deepOrange)),
              onPressed: () {
                final allAreas = List<Releve>.from(releveVm.allReleves);
                if (allAreas.isEmpty) return;
                allAreas.shuffle();
                final randomAreas = allAreas.take(3).toList();
                Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsMapScreen(matchingAreas: randomAreas, plantName: item.name)));
              },
              icon: const Icon(Icons.bug_report), label: const Text("TEST MAPY (3 LOSOWE)"),
            ),
          ),
        ],
      ),
    );
  }
}