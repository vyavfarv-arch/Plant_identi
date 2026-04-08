import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_vm.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';
import '../models/description_schema.dart';

class FormScreen extends StatefulWidget {
  final PlantObservation observation;
  const FormScreen({super.key, required this.observation});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final Map<String, String> _selectedValues = {};

  @override
  Widget build(BuildContext context) {
    final schema = SchemaGenerator.getForType(
        widget.observation.biologicalType ?? "Zielona");

    return Scaffold(
      appBar: AppBar(title: Text('Opis: ${widget.observation.biologicalType}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: schema.length,
              itemBuilder: (context, index) {
                final category = schema[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(category.number,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(category.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: category.subCategories.entries.map((sub) {
                    return _buildSubCategorySection(sub.key, sub.value);
                  }).toList(),
                );
              },
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSubCategorySection(String title, List<String> options) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = _selectedValues[title] == opt;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedValues.remove(title);
                    } else {
                      _selectedValues[title] = opt;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.green : Colors
                        .grey.shade400),
                  ),
                  child: Text(opt, style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: _zapiszFinalnie,
        child: const Text("ZAPISZ OBSERWACJĘ TERENOWĄ",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _zapiszFinalnie() {
    final now = DateTime.now();

    final finalObs = PlantObservation(
      id: widget.observation.id,
      photoPaths: widget.observation.photoPaths,
      latitude: widget.observation.latitude,
      longitude: widget.observation.longitude,
      timestamp: widget.observation.timestamp,
      characteristics: Map.from(_selectedValues),
      biologicalType: widget.observation.biologicalType,
      phytosociologicalLayer: widget.observation.phytosociologicalLayer,
      abundance: widget.observation.abundance,
      coverage: widget.observation.coverage,
      vitality: widget.observation.vitality,
      sociability: widget.observation.sociability,
      observationDate: now, // USTAWIA DATE - teraz roślina "zniknie" po dodaniu nazwy
    );

    context.read<PlantsViewModel>().addObservation(finalObs);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          AlertDialog(
            title: const Text("Zapisano!"),
            content: const Text(
                "Dane terenowe zapisane. Przejdź do 'Opisz spotkane rośliny'."),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<ObservationViewModel>().reset();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text("OK"),
              )
            ],
          ),
    );
  }
}