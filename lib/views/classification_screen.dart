import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../models/plant_observation.dart';
import 'form_screen.dart';
import 'package:uuid/uuid.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  final TextEditingController _familyController = TextEditingController();
  String? _selectedType;
  String? _selectedAbundance;
  String? _selectedVitality;
  String? _selectedPurity;

  final List<String> _types = ["Drzewo", "Krzew", "Zielne", "Grzyb", "Mszaki"];

  final Map<String, String> _purityDescriptions = {
    "4": "Obszar Dziki ",
    "3": "Czysty ( 500m od dróg)",
    "2": "Średni (pobliża pól uprawnych)",
    "1": "Zanieczyszczony (miejski, przy drogach)"
  };

  final Map<String, String> _abundanceDescriptions = {
    "5": "75-100% pokrycia",
    "4": "50-75% pokrycia",
    "3": "25-50% pokrycia",
    "2": "5-25% pokrycia",
    "1": "<5%, licznie ",
    "0": "nielicznie"
  };


  final Map<String, String> _vitalityDescriptions = {
    "4": "Bardzo dobra",
    "3": "Dobra",
    "2": "Słaba",
    "1": "Zamierająca",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Klasyfikacja")),
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


            _buildDetailedDropdown(
                "Czystość obszaru",
                _purityDescriptions,
                    (v) => setState(() => _selectedPurity = v)
            ),
            _buildDetailedDropdown(
                "Ilościowość",
                _abundanceDescriptions,
                    (v) => setState(() => _selectedAbundance = v)
            ),
            _buildDetailedDropdown(
                "Żywotność",
                _vitalityDescriptions,
                    (v) => setState(() => _selectedVitality = v)
            ),

            // Opcjonalnie Żywotność (dropdown bez mapy opisów
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _familyController,
                decoration: const InputDecoration(
                  labelText: "Rodzina (np. Asteraceae)",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Divider(),
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
            const SizedBox(height: 20),
            const Divider(),
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

  void _navigateToDetailedForm() {
    final obsVm = context.read<ObservationViewModel>();

    final newObs = PlantObservation(
      id: const Uuid().v4(),
      photoPaths: List.from(obsVm.currentPhotoPaths),
      latitude: obsVm.currentPosition?.latitude ?? 0.0,
      longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(),
      characteristics: {},
      biologicalType: _selectedType,
      family: _familyController.text,
      areaPurity: _selectedPurity,
      abundance: _selectedAbundance,
      vitality: _selectedVitality,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormScreen(observation: newObs)),
    );
  }
}