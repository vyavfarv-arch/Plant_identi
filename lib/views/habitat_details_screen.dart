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
  int _canopyDensity = 1;
  String? _areaType;
  String? _exposure;
  String? _waterMovement;
  String? _slopeAngle;
  String? _hydrologicalContext;
  String? _soilSurfaceCover;
  String? _humanImpact;
  final List<String> _selectedSubstrates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Szczegóły nowego obszaru")),
      body: SafeArea(child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("1. Informacje ogólne"),
              TextFormField(controller: _commonNameController, decoration: const InputDecoration(labelText: "Nazwa zwyczajowa", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "To pole jest wymagane" : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _selectedType, items: ["Obszar", "Podobszar"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedType = v!), decoration: const InputDecoration(labelText: "Ranga", border: OutlineInputBorder())),

              const SizedBox(height: 30),
              _sectionTitle("2. Parametry Krytyczne (Skala Ellenberga)"),
              _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _areaType, (v) => setState(() => _areaType = v)),

              const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text("Stopń zacienienia okapu (1-9):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              DropdownButtonFormField<int>(
                value: _canopyDensity, isExpanded: true, decoration: const InputDecoration(border: OutlineInputBorder()),
                items: List.generate(9, (index) => DropdownMenuItem(value: index + 1, child: Text(HabitatInfo.canopyDensityLabels[index], style: const TextStyle(fontSize: 12)))),
                onChanged: (v) => setState(() => _canopyDensity = v ?? 1),
              ),
              const SizedBox(height: 12),
              _buildDropdown("Ruch i natlenienie wody", HabitatInfo.waterMovementOptions, _waterMovement, (v) => setState(() => _waterMovement = v)),
              _buildDropdown("Reżim wodno-retencyjny", HabitatInfo.hydrologicalContextOptions, _hydrologicalContext, (v) => setState(() => _hydrologicalContext = v)),
              _buildDropdown("Struktura okrywy glebowej", HabitatInfo.soilSurfaceCoverOptions, _soilSurfaceCover, (v) => setState(() => _soilSurfaceCover = v)),
              _buildDropdown("Zaburzenia", HabitatInfo.humanImpactOptions, _humanImpact, (v) => setState(() => _humanImpact = v)),
              _buildDropdown("Ekspozycja stoku", HabitatInfo.exposureOptions, _exposure, (v) => setState(() => _exposure = v)),
              _buildDropdown("Kąt nachylenia stoku", HabitatInfo.slopeAngleOptions, _slopeAngle, (v) => setState(() => _slopeAngle = v)),

              const SizedBox(height: 20),
              _sectionTitle("3. Parametry Glebowe"),
              TextFormField(controller: _phController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Wartość pH gleby (opcjonalnie)", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              _buildMultiSelect("Typ podłoża:", HabitatInfo.substrateOptions, _selectedSubstrates),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _saveAll,
                  child: const Text("ZAPISZ OBSZAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12, top: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)));
  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) => Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: value, isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(), onChanged: onChanged));
  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 8), Wrap(spacing: 8, children: options.map((opt) { final isSelected = targetList.contains(opt); return FilterChip(label: Text(opt, style: const TextStyle(fontSize: 12)), selected: isSelected, onSelected: (s) => setState(() => s ? targetList.add(opt) : targetList.remove(opt))); }).toList())]);

  void _saveAll() {
    if (!_formKey.currentState!.validate()) return;
    final habitat = HabitatInfo(
      areaType: _areaType, canopyDensity: _canopyDensity, waterMovement: _waterMovement,
      substrateType: List.from(_selectedSubstrates), exposure: _exposure, slopeAngle: _slopeAngle,
      hydrologicalContext: _hydrologicalContext, soilSurfaceCover: _soilSurfaceCover, humanImpact: _humanImpact,
      ph: double.tryParse(_phController.text),
    );
    final newReleve = Releve(id: const Uuid().v4(), commonName: _commonNameController.text, phytosociologicalName: "", type: _selectedType, points: widget.points, date: DateTime.now(), habitat: habitat);
    context.read<ReleveViewModel>().saveNewReleve(newReleve);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}