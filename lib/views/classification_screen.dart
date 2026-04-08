// lib/views/classification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_vm.dart';
import '../viewmodels/plants_view_model.dart';
import '../models/plant_observation.dart';
import 'form_screen.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  String? _selectedType;
  String? _selectedLayer;
  String? _selectedAbundance;
  String? _selectedVitality;
  String? _selectedSociability;

  final List<String> _types = ["Drzewo", "Krzew", "Krzewinka", "Zielona"];
  final Map<String, String> _layerDescriptions = {
    "A": "Warstwa drzew (>7m)",
    "B": "Warstwa krzewów (0.5-7m)",
    "C": "Warstwa runa (rośliny zielne)",
    "D": "Warstwa mszysta (mchy, porosty)"
  };

  final Map<String, String> _abundanceDescriptions = {
    "5": "75-100% pokrycia",
    "4": "50-75% pokrycia",
    "3": "25-50% pokrycia",
    "2": "5-25% pokrycia",
    "1": "<5%, licznie ",
    "+": "<5%, nielicznie",
    "r": "pojedynczo"
  };

  final Map<String, String> _sociabilityDescriptions = {
    "1": "Pojedynczo",
    "2": "Kępkowo / grupowo",
    "3": "W małych płatach",
    "4": "W dużych płatach / łanowo",
    "5": "Tworzy gęste zbiorowisko"
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Klasyfikacja i Fitosocjologia")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Typ biologiczny:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _types.length,
              itemBuilder: (ctx, i) {
                final t = _types[i];
                final isSelected = _selectedType == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSelected ? Colors.green : Colors.grey),
                    ),
                    child: Center(
                      child: Text(t, style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87
                      )),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // POPRAWKA: Przekazujemy mapę do nowej wersji _buildDropdown
            _buildDetailedDropdown(
                "Warstwa fitosocjologiczna",
                _layerDescriptions,
                    (v) => setState(() => _selectedLayer = v)
            ),
            _buildDetailedDropdown(
                "Ilościowość",
                _abundanceDescriptions,
                    (v) => setState(() => _selectedAbundance = v)
            ),
            _buildDetailedDropdown(
                "Towarzyskość",
                _sociabilityDescriptions,
                    (v) => setState(() => _selectedSociability = v)
            ),

            // Opcjonalnie Żywotność (dropdown bez mapy opisów)
            _buildDropdown("Żywotność", ["Bardzo dobra", "Dobra", "Słaba", "Zamierająca"], (v) => setState(() => _selectedVitality = v)),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _selectedType == null ? null : () => _navigateToDetailedForm(),
                child: const Text("DALEJ DO OPISU", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailedDropdown(String label, Map<String, String> dataMap, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: dataMap.entries.map((e) => DropdownMenuItem(
            value: e.key,
            child: Text("${e.key} - ${e.value}")
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }
  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), hintText: hint),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _navigateToDetailedForm() {
    final obsVm = context.read<ObservationViewModel>();

    final newObs = PlantObservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      photoPaths: List.from(obsVm.currentPhotoPaths),
      latitude: obsVm.currentPosition?.latitude ?? 0.0,
      longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(),
      characteristics: {}, // Pusta mapa, wypełniona w FormScreen
      biologicalType: _selectedType,
      phytosociologicalLayer: _selectedLayer,
      abundance: _selectedAbundance,
      vitality: _selectedVitality,
      sociability: _selectedSociability,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormScreen(observation: newObs)),
    );
  }
}