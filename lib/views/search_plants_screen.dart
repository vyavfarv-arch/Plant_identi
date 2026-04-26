import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../services/ml_prediction_service.dart';
import 'add_sought_plant_screen.dart';
import '../models/plant_observation.dart';
import 'results_map_screen.dart';

class SearchPlantsScreen extends StatefulWidget {
  const SearchPlantsScreen({super.key});

  @override
  State<SearchPlantsScreen> createState() => _SearchPlantsScreenState();
}

class _SearchPlantsScreenState extends State<SearchPlantsScreen> {
  String? _selectedPlantId;
  String _searchQuery = "";
  String _filterType = "Wszystkie";

  final Map<String, List<String>> _analysisResults = {};
  final MlPredictionService _mlService = MlPredictionService();

  @override
  void initState() {
    super.initState();
    _mlService.loadModel();
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.read<ReleveViewModel>();

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
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlants.length,
              itemBuilder: (context, index) {
                final plant = filteredPlants[index];

// LOGIKA KOLORU IKONY
                Color iconColor = Colors.grey;
                // Jeśli ostatnia analiza została wykonana (liczba obszarów podczas analizy > 0)
                if (plant.lastAnalysisAreaCount > 0) {
                  // Jeśli dodano nowe obszary po analizie -> POMARAŃCZOWY
                  if (plant.lastAnalysisAreaCount != releveVm.allReleves.length) {
                    iconColor = Colors.orange;
                  } else {
                    iconColor = Colors.green; // Aktualne wyniki
                  }
                }

                return RadioListTile<String>(
                  title: Text(plant.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plant.isSought ? "POSZUKIWANA" : "W MAGAZYNIE"),
                  secondary: IconButton(
                    icon: Icon(Icons.info_outline, color: iconColor),
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
            _buildActionFooter(obsVm.allObservations.firstWhere((p) => p.id == _selectedPlantId), releveVm),
        ],
      ),
    );
  }

  Widget _buildActionFooter(PlantObservation plant, ReleveViewModel releveVm) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final results = _mlService.getMatchingAreas(plant, releveVm.allReleves);

            // ZAPISANIE WYNIKÓW NA STAŁE W BAZIE
            await context.read<ObservationViewModel>().saveAnalysisResults(
                plant.id,
                results,
                releveVm.allReleves.length
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Analiza zakończona. Znaleziono ${results.length} obszarów.")),
            );
          },
          icon: const Icon(Icons.psychology),
          label: const Text("URUCHOM ANALIZĘ ML"),
        ),
      ),
    );
  }

  void _showPlantEcoDetails(BuildContext context, PlantObservation plant, ObservationViewModel obsVm, ReleveViewModel releveVm) {
    // DODANO: Pobranie wyników analizy dla tego konkretnego ID
    final results = _analysisResults[plant.id];

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
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ekologia i siedlisko:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("pH: ${plant.prefPhMin?.toStringAsFixed(1) ?? '?'} - ${plant.prefPhMax?.toStringAsFixed(1) ?? '?'}"),
            Text("Podłoże: ${plant.prefSubstrate.isNotEmpty ? plant.prefSubstrate.join(', ') : 'Brak'}"),

            // Sekcja wyników ML
            if (plant.lastAnalysisAreaCount > 0) ...[
              const Divider(),
              const Text("Ostatnie wyniki analizy:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Pasujących obszarów: ${plant.analyzedAreaIds.length}"),
              const SizedBox(height: 10),

              // Pokazuj przycisk z mapą TYLKO, gdy są jakiekolwiek pasujące obszary
              if (plant.analyzedAreaIds.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final matchingObjects = releveVm.allReleves
                        .where((r) => plant.analyzedAreaIds.contains(r.id))
                        .toList();

                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ResultsMapScreen(
                            matchingAreas: matchingObjects,
                            plantName: plant.displayName
                        )
                    ));
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text("POKAŻ WYNIKI NA MAPIE"),
                ),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ")),
        ],
      ),
    );
  }
}