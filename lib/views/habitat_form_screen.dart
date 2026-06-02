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
  int _canopyDensity = 1;

  String? _areaType;
  String? _exposure;
  String? _waterMovement;
  String? _slopeAngle;
  String? _hydrologicalContext;
  String? _soilSurfaceCover;
  String? _humanImpact;

  @override
  void initState() {
    super.initState();
    if (widget.releve.habitat != null) {
      final h = widget.releve.habitat!;
      _selectedSubstrates.addAll(h.substrateType);
      _phController.text = h.ph?.toString() ?? "";
      _canopyDensity = h.canopyDensity;
      _areaType = h.areaType;
      _exposure = h.exposure;
      _waterMovement = h.waterMovement;
      _slopeAngle = h.slopeAngle;
      _hydrologicalContext = h.hydrologicalContext;
      _soilSurfaceCover = h.soilSurfaceCover;
      _humanImpact = h.humanImpact;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pełen opis siedliska"), backgroundColor: Colors.brown.shade700, foregroundColor: Colors.white),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("Parametry Siedliskowe (Wskaźniki Ellenberga)"),
          _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _areaType, (v) => setState(() => _areaType = v)),

          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text("Stopń zacienienia okapu (1-9):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          DropdownButtonFormField<int>(
            value: _canopyDensity, isExpanded: true, decoration: const InputDecoration(border: OutlineInputBorder()),
            items: List.generate(9, (index) => DropdownMenuItem(value: index + 1, child: Text(HabitatInfo.canopyDensityLabels[index], style: const TextStyle(fontSize: 12)))),
            onChanged: (v) => setState(() => _canopyDensity = v ?? 1),
          ),
          const SizedBox(height: 12),
          _buildDropdown("Ruch i natlenienie wody", HabitatInfo.waterMovementOptions, _waterMovement, (v) => setState(() => _waterMovement = v)),
          _buildDropdown("Režim wodno-retencyjny", HabitatInfo.hydrologicalContextOptions, _hydrologicalContext, (v) => setState(() => _hydrologicalContext = v)),
          _buildDropdown("Struktura okrywy glebowej", HabitatInfo.soilSurfaceCoverOptions, _soilSurfaceCover, (v) => setState(() => _soilSurfaceCover = v)),
          _buildDropdown("Antropopresja / Zaburzenia", HabitatInfo.humanImpactOptions, _humanImpact, (v) => setState(() => _humanImpact = v)),
          _buildDropdown("Ekspozycja stoku", HabitatInfo.exposureOptions, _exposure, (v) => setState(() => _exposure = v)),
          _buildDropdown("Kąt nachylenia stoku", HabitatInfo.slopeAngleOptions, _slopeAngle, (v) => setState(() => _slopeAngle = v)),

          const SizedBox(height: 20),
          _sectionTitle("Parametry Glebowe"),
          _buildMultiSelect("Typ podłoża", HabitatInfo.substrateOptions, _selectedSubstrates),
          const SizedBox(height: 20),
          TextField(controller: _phController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Wartość pH (opcjonalnie)", border: OutlineInputBorder())),

          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            onPressed: _saveHabitat, icon: const Icon(Icons.save), label: const Text("ZAPISZ INFORMACJE O SIEDLISKU"),
          ),
        ],
      ),),
    );
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 15, top: 5), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)));
  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) => Padding(padding: const EdgeInsets.only(bottom: 15), child: DropdownButtonFormField<String>(value: options.contains(value) ? value : null, isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(), onChanged: onChanged));
  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 8), Wrap(spacing: 8, children: options.map((opt) { final isSelected = targetList.contains(opt); return FilterChip(label: Text(opt, style: const TextStyle(fontSize: 12)), selected: isSelected, onSelected: (s) => setState(() => s ? targetList.add(opt) : targetList.remove(opt))); }).toList())]);

  void _saveHabitat() {
    final info = HabitatInfo(
      areaType: _areaType, canopyDensity: _canopyDensity, waterMovement: _waterMovement,
      substrateType: List.from(_selectedSubstrates), exposure: _exposure, slopeAngle: _slopeAngle,
      hydrologicalContext: _hydrologicalContext, soilSurfaceCover: _soilSurfaceCover, humanImpact: _humanImpact,
      ph: double.tryParse(_phController.text),
    );
    context.read<ReleveViewModel>().updateReleveHabitat(widget.releve.id, info);
    Navigator.pop(context);
  }
}