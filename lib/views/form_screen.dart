import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_vm.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';
import '../models/description_schema.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  // Przechowujemy wybory w mapie: "Kategoria_Podkategoria" -> "Wybrana Wartość"
  final Map<String, String> _selectedValues = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Szczegółowy opis terenu')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: plantDescriptionSchema.length,
              itemBuilder: (context, index) {
                final category = plantDescriptionSchema[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(category.letter, style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
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
                      _selectedValues.remove(title); // Możliwość odznaczenia
                    } else {
                      _selectedValues[title] = opt;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: _pokazPodsumowanie,
        child: const Text("ZAPISZ DANE TERENOWE", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _pokazPodsumowanie() {
    final obsVm = context.read<ObservationViewModel>();

    final newObs = PlantObservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      photoPaths: List.from(obsVm.currentPhotoPaths),
      latitude: obsVm.currentPosition?.latitude ?? 0.0,
      longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(),
      characteristics: Map.from(_selectedValues), // Zapis strukturalny
    );

    context.read<PlantsViewModel>().addObservation(newObs);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Zapisano!"),
        content: Text("Zebrano opis dla ${newObs.characteristics.length} cech. Roślina czeka w kolejce na pełną identyfikację."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              obsVm.reset();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}