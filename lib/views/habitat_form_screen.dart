// lib/views/habitat_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../viewmodels/releve_view_model.dart';

class HabitatFormScreen extends StatefulWidget {
  final Releve releve;
  const HabitatFormScreen({super.key, required this.releve});

  @override
  State<HabitatFormScreen> createState() => _HabitatFormScreenState();
}

class _HabitatFormScreenState extends State<HabitatFormScreen> {
  final List<String> _selectedSubstrates = [];
  final TextEditingController _phController = TextEditingController();
  double _moisture = 1.0;

  String? _areaType;
  String? _canopyCover;
  String? _waterDynamics;
  String? _litterThickness;

  final List<String> _moistureLabels = ["Sucho", "Świeżo", "Wilgotno", "Mokro"];
  final List<String> _areaTypeOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Teren miejski", "Skraj lasu"];
  final List<String> _canopyCoverOptions = ["Otwarte (0-25%)", "Półotwarte (25-60%)", "Zacienione (60-85%)", "Gęste (>85%)"];
  final List<String> _waterDynamicsOptions = ["Stale wilgotne", "Sezonowo zalewane", "Sezonowo wysychające", "Stale suche"];
  final List<String> _litterThicknessOptions = ["Brak", "Cienka (<2cm)", "Umiarkowana (2-10cm)", "Gruba (>10cm)"];

  @override
  void initState() {
    super.initState();
    if (widget.releve.habitat != null) {
      final h = widget.releve.habitat!;
      _selectedSubstrates.addAll(h.substrateType);
      _moisture = h.moisture;
      _phController.text = h.ph?.toString() ?? "";
      _areaType = h.areaType;
      _canopyCover = h.canopyCover;
      _waterDynamics = h.waterDynamics;
      _litterThickness = h.litterThickness;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pełen opis siedliska")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMultiSelect("Typ podłoża", ["Piasek", "Glina", "Torf", "Skała wapienna", "Skała krzemianowa"], _selectedSubstrates),
          const SizedBox(height: 20),

          const Text("Wilgotność:", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _moisture, min: 0, max: 3, divisions: 3,
            label: _moistureLabels[_moisture.round()],
            onChanged: (v) => setState(() => _moisture = v),
          ),
          Center(child: Text(_moistureLabels[_moisture.round()], style: const TextStyle(color: Colors.blue))),

          const SizedBox(height: 20),
          TextField(
            controller: _phController, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Wartość pH (opcjonalnie)", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 20),
          _buildDropdown("Typ obszaru", _areaTypeOptions, _areaType, (v) => setState(() => _areaType = v)),
          _buildDropdown("Zwarcie koron", _canopyCoverOptions, _canopyCover, (v) => setState(() => _canopyCover = v)),
          _buildDropdown("Dynamika wody", _waterDynamicsOptions, _waterDynamics, (v) => setState(() => _waterDynamics = v)),
          _buildDropdown("Warstwa ściółki", _litterThicknessOptions, _litterThickness, (v) => setState(() => _litterThickness = v)),

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

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
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
              label: Text(opt), selected: isSelected,
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
      areaType: _areaType,
      canopyCover: _canopyCover,
      waterDynamics: _waterDynamics,
      litterThickness: _litterThickness,
    );
    context.read<ReleveViewModel>().updateReleveHabitat(widget.releve.id, info);
    Navigator.pop(context);
  }
}