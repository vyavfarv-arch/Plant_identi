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

  // Zmienne dla pól siedliskowych
  String? _areaType;
  String? _exposure;
  String? _canopyCover;
  String? _waterDynamics;
  String? _slopeAngle;
  String? _litterThickness;
  String? _distanceToWater;

  @override
  void initState() {
    super.initState();
    // Inicjalizacja danymi z istniejącego obiektu releve
    if (widget.releve.habitat != null) {
      final h = widget.releve.habitat!;
      _selectedSubstrates.addAll(h.substrateType);
      _moisture = h.moisture;
      _phController.text = h.ph?.toString() ?? "";
      _areaType = h.areaType;
      _exposure = h.exposure;
      _canopyCover = h.canopyCover;
      _waterDynamics = h.waterDynamics;
      _slopeAngle = h.slopeAngle;
      _litterThickness = h.litterThickness;
      _distanceToWater = h.distanceToWater;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pełen opis siedliska"),
        backgroundColor: Colors.brown.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child:  ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("1. Parametry Krytyczne (Wysokie znaczenie)"),
          _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _areaType, (v) => setState(() => _areaType = v)),
          _buildDropdown("Zwarcie koron", HabitatInfo.canopyCoverOptions, _canopyCover, (v) => setState(() => _canopyCover = v)),
          _buildDropdown("Dynamika wody", HabitatInfo.waterDynamicsOptions, _waterDynamics, (v) => setState(() => _waterDynamics = v)),
          _buildDropdown("Ekspozycja stoku", HabitatInfo.exposureOptions, _exposure, (v) => setState(() => _exposure = v)),

          const SizedBox(height: 20),
          _sectionTitle("2. Parametry Ważne (Średnie znaczenie)"),
          _buildDropdown("Kąt nachylenia stoku", HabitatInfo.slopeAngleOptions, _slopeAngle, (v) => setState(() => _slopeAngle = v)),
          _buildDropdown("Warstwa ściółki", HabitatInfo.litterThicknessOptions, _litterThickness, (v) => setState(() => _litterThickness = v)),
          _buildDropdown("Odległość do wody", HabitatInfo.distanceToWaterOptions, _distanceToWater, (v) => setState(() => _distanceToWater = v)),

          const SizedBox(height: 20),
          _sectionTitle("3. Parametry Glebowe"),
          _buildMultiSelect("Typ podłoża", HabitatInfo.substrateOptions, _selectedSubstrates),

          const SizedBox(height: 20),
          const Text("Chwilowa wilgotność gleby:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Slider(
            value: _moisture,
            min: 0,
            max: (HabitatInfo.moistureLabels.length - 1).toDouble(),
            divisions: HabitatInfo.moistureLabels.length - 1,
            label: HabitatInfo.moistureLabels[_moisture.round()],
            onChanged: (v) => setState(() => _moisture = v),
          ),
          Center(child: Text(HabitatInfo.moistureLabels[_moisture.round()], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),

          const SizedBox(height: 20),
          TextField(
            controller: _phController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Wartość pH (opcjonalnie)", border: OutlineInputBorder()),
          ),

          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _saveHabitat,
            icon: const Icon(Icons.save),
            label: const Text("ZAPISZ INFORMACJE O SIEDLISKU", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
        ],
      ),),
    );
  }

  // --- WIDGETY POMOCNICZE (zgodne z habitat_details_screen.dart) ---

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 5),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
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

  void _saveHabitat() {
    final info = HabitatInfo(
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

    context.read<ReleveViewModel>().updateReleveHabitat(widget.releve.id, info);
    Navigator.pop(context);
  }
}