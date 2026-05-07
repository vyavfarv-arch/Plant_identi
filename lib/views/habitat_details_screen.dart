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
  final TextEditingController _phController = TextEditingController();

  String _selectedType = "Obszar";
  double _moisture = 1.0;
  final List<String> _selectedSubstrates = [];

  // Zmienne stanowe formularza
  String? _areaType;
  String? _exposure;
  String? _canopyCover;
  String? _waterDynamics;
  String? _slopeAngle;
  String? _litterThickness;
  String? _distanceToWater;

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
              _sectionTitle("1. Informacje ogólne"),
              TextFormField(
                controller: _commonNameController,
                decoration: const InputDecoration(labelText: "Nazwa zwyczajowa ", border: OutlineInputBorder()),
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
              _sectionTitle("2. Parametry Krytyczne (Wysokie znaczenie)"),
              _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _areaType, (v) => setState(() => _areaType = v)),
              _buildDropdown("Zwarcie koron", HabitatInfo.canopyCoverOptions, _canopyCover, (v) => setState(() => _canopyCover = v)),
              _buildDropdown("Dynamika wody", HabitatInfo.waterDynamicsOptions, _waterDynamics, (v) => setState(() => _waterDynamics = v)),
              _buildDropdown("Ekspozycja stoku", HabitatInfo.exposureOptions, _exposure, (v) => setState(() => _exposure = v)),

              const SizedBox(height: 20),
              _sectionTitle("3. Parametry Ważne (Średnie znaczenie)"),
              _buildDropdown("Kąt nachylenia stoku", HabitatInfo.slopeAngleOptions, _slopeAngle, (v) => setState(() => _slopeAngle = v)),
              _buildDropdown("Grubość ściółki", HabitatInfo.litterThicknessOptions, _litterThickness, (v) => setState(() => _litterThickness = v)),
              _buildDropdown("Odległość do wody", HabitatInfo.distanceToWaterOptions, _distanceToWater, (v) => setState(() => _distanceToWater = v)),

              const SizedBox(height: 20),
              _sectionTitle("4. Parametry Glebowe"),
              TextFormField(
                controller: _phController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Wartość pH gleby", border: OutlineInputBorder(), hintText: "np. 6.5"),
              ),
              const SizedBox(height: 15),
              _buildMultiSelect("Typ podłoża:", HabitatInfo.substrateOptions, _selectedSubstrates),

              const SizedBox(height: 15),
              _buildSlider("Chwilowa wilgotność gleby:", _moisture, HabitatInfo.moistureLabels, (v) => setState(() => _moisture = v)),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _saveAll,
                  child: const Text("ZAPISZ OBSZAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETY POMOCNICZE ---

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSlider(String title, double value, List<String> labels, Function(double) onChanged) {
    int divisions = labels.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = targetList.contains(opt);
            return FilterChip(
              label: Text(opt, style: const TextStyle(fontSize: 12)),
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

    final habitat = HabitatInfo(
      areaType: _areaType,
      exposure: _exposure,
      canopyCover: _canopyCover,
      waterDynamics: _waterDynamics,
      slopeAngle: _slopeAngle,
      litterThickness: _litterThickness,
      distanceToWater: _distanceToWater,
      substrateType: List.from(_selectedSubstrates),
      moisture: _moisture,
      ph: double.tryParse(_phController.text),
    );

    final newReleve = Releve(
      id: const Uuid().v4(),
      commonName: _commonNameController.text,
      phytosociologicalName: "",
      type: _selectedType,
      points: widget.points,
      date: DateTime.now(),
      habitat: habitat,
    );

    context.read<ReleveViewModel>().saveNewReleve(newReleve);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Obszar i siedlisko zostały zapisane!")));
  }
}