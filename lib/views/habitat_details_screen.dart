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

  final TextEditingController _commonNameController = TextEditingController();
  final TextEditingController _phytoNameController = TextEditingController();
  String _selectedType = "Obszar"; // NOWY PODZIAŁ HIERARCHII

  final TextEditingController _phController = TextEditingController();
  final List<String> _selectedSubstrates = [];
  double _moisture = 1.0;

  // NOWE KRYTYCZNE ZMIENNE EKOLOGICZNE
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
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ["Obszar", "Podobszar"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
              const SizedBox(height: 20),

              _buildDropdown("Typ obszaru", _areaTypeOptions, _areaType, (v) => setState(() => _areaType = v)),
              _buildDropdown("Zwarcie koron (nasłonecznienie)", _canopyCoverOptions, _canopyCover, (v) => setState(() => _canopyCover = v)),
              _buildDropdown("Dynamika wody", _waterDynamicsOptions, _waterDynamics, (v) => setState(() => _waterDynamics = v)),
              _buildDropdown("Grubość warstwy ściółki", _litterThicknessOptions, _litterThickness, (v) => setState(() => _litterThickness = v)),

              _buildSlider("Chwilowa wilgotność gleby:", _moisture, 3, _moistureLabels, (v) => setState(() => _moisture = v)),

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

  Widget _buildSlider(String title, double value, int divisions, List<String> labels, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: value, min: 0, max: divisions.toDouble(), divisions: divisions,
          label: labels[value.round()], onChanged: onChanged,
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
              label: Text(opt), selected: isSelected,
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
        areaType: _areaType,
        canopyCover: _canopyCover,
        waterDynamics: _waterDynamics,
        litterThickness: _litterThickness,
      ),
    );

    context.read<ReleveViewModel>().saveNewReleve(newReleve);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Obszar został zapisany!")));
  }
}