import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_observation.dart';
import '../viewmodels/observation_view_model.dart';

class AddSoughtPlantScreen extends StatefulWidget {
  const AddSoughtPlantScreen({super.key});

  @override
  State<AddSoughtPlantScreen> createState() => _AddSoughtPlantScreenState();
}

class _AddSoughtPlantScreenState extends State<AddSoughtPlantScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();

  double _prefPhMin = 5.5;
  double _prefPhMax = 7.5;
  final List<String> _prefSubstrateList = [];
  double _prefMoisture = 1.0;
  double _prefSunlight = 2.0;

  final List<String> _substrateOptions = [
    "Gliniasta", "Piaskowa", "Żwirowa", "Torfowa",
    "Kamienista", "Próchnicza", "Wapienna", "Krzemianowa"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowa roślina poszukiwana")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dane podstawowe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nazwa polska", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _latinController,
              decoration: const InputDecoration(labelText: "Nazwa łacińska", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Ekologia (pod ML)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text("Przedział pH gleby: ${_prefPhMin.toStringAsFixed(1)} - ${_prefPhMax.toStringAsFixed(1)}"),
            RangeSlider(
              values: RangeValues(_prefPhMin, _prefPhMax),
              min: 3.0, max: 9.0,
              divisions: 60,
              labels: RangeLabels(_prefPhMin.toStringAsFixed(1), _prefPhMax.toStringAsFixed(1)),
              onChanged: (v) => setState(() { _prefPhMin = v.start; _prefPhMax = v.end; }),
            ),
            const SizedBox(height: 15),
            const Text("Preferowane typy gleby:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _substrateOptions.map((substrate) {
                final isSelected = _prefSubstrateList.contains(substrate);
                return FilterChip(
                  label: Text(substrate, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                  selected: isSelected,
                  selectedColor: Colors.teal,
                  checkmarkColor: Colors.white,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _prefSubstrateList.add(substrate);
                      } else {
                        _prefSubstrateList.remove(substrate);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            _buildSlider("Wilgotność:", _prefMoisture, 3, ["Sucho", "Świeżo", "Wilgotno", "Mokro"], (v) => setState(() => _prefMoisture = v)),
            _buildSlider("Nasłonecznienie:", _prefSunlight, 4, ["Pełne słońce", "Przewaga słońca", "Półcień", "Przewaga cienia", "Cień"], (v) => setState(() => _prefSunlight = v)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _saveSoughtPlant,
                child: const Text("DODAJ CEL POSZUKIWAŃ"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String title, double value, int divisions, List<String> labels, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(value: value, min: 0, max: divisions.toDouble(), divisions: divisions, label: labels[value.round()], onChanged: onChanged),
        Center(child: Text(labels[value.round()], style: const TextStyle(color: Colors.blue))),
      ],
    );
  }

  void _saveSoughtPlant() {
    if (_nameController.text.isEmpty) return;

    final soughtObs = PlantObservation(
      id: const Uuid().v4(),
      photoPaths: [],
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      characteristics: {},
      localName: _nameController.text,
      latinName: _latinController.text,
      isSought: true,
      prefPhMin: _prefPhMin,
      prefPhMax: _prefPhMax,
      prefSubstrate: _prefSubstrateList,
      prefMoisture: _prefMoisture,
      prefSunlight: _prefSunlight,
      observationDate: DateTime.now(),
    );

    context.read<ObservationViewModel>().addObservation(soughtObs);
    Navigator.pop(context);
  }
}