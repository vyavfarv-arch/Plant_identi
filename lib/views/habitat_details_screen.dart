// lib/views/habitat_details_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../viewmodels/releve_view_model.dart';

class HabitatDetailsScreen extends StatefulWidget {
  final List<LatLng> points;
  const HabitatDetailsScreen({super.key, required this.points});

  @override
  State<HabitatDetailsScreen> createState() => _HabitatDetailsScreenState();
}

class _HabitatDetailsScreenState extends State<HabitatDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Dane podstawowe
  final TextEditingController _commonNameController = TextEditingController();
  final TextEditingController _phytoNameController = TextEditingController();
  String _selectedType = "Zespół";

  // Dane siedliskowe (Numeryczne dla Random Forest)
  final TextEditingController _phController = TextEditingController();
  final List<String> _selectedSubstrates = [];
  final List<String> _selectedLitter = [];
  double _moisture = 1.0;
  double _sunlight = 2.0;
  double _pollution = 0.0;

  // Etykiety dla suwaków
  final List<String> _moistureLabels = ["Sucho", "Świeżo", "Wilgotno", "Mokro"];
  final List<String> _sunlightLabels = ["Pełne słońce", "Przewaga słońca", "Półcień", "Przewaga cienia", "Cień"];
  final List<String> _pollutionLabels = ["Dzikie", "Uczęszczane", "Przy polach uprawnych", "Przy drodze", "Zanieczyszczone"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Szczegóły nowego obszaru")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("1. Informacje ogólne", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _commonNameController,
                decoration: const InputDecoration(labelText: "Nazwa zwyczajowa (np. Polana)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "To pole jest wymagane" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phytoNameController,
                decoration: const InputDecoration(labelText: "Nazwa naukowa (Syntakson)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ["Zespół", "Związek", "Rząd", "Klasa"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
                decoration: const InputDecoration(labelText: "Ranga", border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),
              const Text("2. Parametry Siedliska", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              const Divider(),

              TextFormField(
                controller: _phController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Wartość pH gleby", border: OutlineInputBorder(), hintText: "np. 6.5"),
              ),

              const SizedBox(height: 20),
              _buildMultiSelect("Typ podłoża:", ["Piasek", "Glina", "Torf", "Skała wapienna", "Skała krzemianowa"], _selectedSubstrates),
              _buildMultiSelect("Warstwa ściółki:", ["Brak", "Cienka warstwa", "Gruba warstwa"], _selectedLitter),

              _buildSlider("Wilgotność:", _moisture, 3, _moistureLabels, (v) => setState(() => _moisture = v)),
              _buildSlider("Nasłonecznienie:", _sunlight, 4, _sunlightLabels, (v) => setState(() => _sunlight = v)),
              _buildSlider("Stopień zanieczyszczenia / antropopresji:", _pollution, 4, _pollutionLabels, (v) => setState(() => _pollution = v)),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _saveAll,
                  child: const Text("ZAPISZ OBSZAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String title, double value, int divisions, List<String> labels, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: value,
          min: 0, max: divisions.toDouble(),
          divisions: divisions,
          label: labels[value.round()],
          onChanged: onChanged,
        ),
        Center(child: Text(labels[value.round()], style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = targetList.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (s) => setState(() => s ? targetList.add(opt) : targetList.remove(opt)),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveAll() {
    if (!_formKey.currentState!.validate()) return;

    final newReleve = Releve(
      id: const Uuid().v4(),
      commonName: _commonNameController.text,
      phytosociologicalName: _phytoNameController.text,
      type: _selectedType,
      points: widget.points,
      date: DateTime.now(),
      habitat: HabitatInfo(
        substrateType: _selectedSubstrates,
        moisture: _moisture,
        ph: double.tryParse(_phController.text),
        litterLayer: _selectedLitter,
        sunlight: _sunlight,
        pollution: _pollution,
      ),
    );

    context.read<ReleveViewModel>().saveNewReleve(newReleve);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Obszar został zapisany!")));
  }
}