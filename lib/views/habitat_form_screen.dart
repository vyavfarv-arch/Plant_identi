import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../viewmodels/plants_view_model.dart';

class HabitatFormScreen extends StatefulWidget {
  final Releve releve;
  const HabitatFormScreen({super.key, required this.releve});

  @override
  State<HabitatFormScreen> createState() => _HabitatFormScreenState();
}

class _HabitatFormScreenState extends State<HabitatFormScreen> {
  final List<String> _selectedSubstrates = [];
  final List<String> _selectedLitter = [];
  double _moisture = 1.0;
  final TextEditingController _phController = TextEditingController();

  final List<String> _moistureLabels = ["Sucho", "Świeżo", "Wilgotno", "Mokro"];

  @override
  void initState() {
    super.initState();
    if (widget.releve.habitat != null) {
      final h = widget.releve.habitat!;
      _selectedSubstrates.addAll(h.substrateType);
      _selectedLitter.addAll(h.litterLayer);
      _moisture = h.moisture;
      _phController.text = h.ph?.toString() ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Opis siedliska")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMultiSelect("Typ podłoża", ["Piasek", "Glina", "Torf", "Skała wapienna", "Skała krzemianowa"], _selectedSubstrates),
          const SizedBox(height: 20),

          const Text("Wilgotność:", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _moisture,
            min: 0, max: 3, divisions: 3,
            label: _moistureLabels[_moisture.round()],
            onChanged: (v) => setState(() => _moisture = v),
          ),
          Center(child: Text(_moistureLabels[_moisture.round()], style: const TextStyle(color: Colors.blue))),

          const SizedBox(height: 20),
          TextField(
            controller: _phController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Wartość pH (opcjonalnie)", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 20),
          _buildMultiSelect("Warstwa ściółki", ["Brak", "Cienka warstwa", "Gruba warstwa"], _selectedLitter),

          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            onPressed: _saveHabitat,
            child: const Text("ZAPISZ INFORMACJE O SIEDLISKU"),
          )
        ],
      ),
    );
  }

  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = targetList.contains(opt);
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (s) => setState(() => s ? targetList.add(opt) : targetList.remove(opt)),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveHabitat() {
    final info = HabitatInfo(
      substrateType: _selectedSubstrates,
      moisture: _moisture,
      ph: double.tryParse(_phController.text),
      litterLayer: _selectedLitter,
    );
    context.read<PlantsViewModel>().updateReleveHabitat(widget.releve.id, info);
    Navigator.pop(context);
  }
}