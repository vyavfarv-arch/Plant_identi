// lib/views/area_filter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habitat_info.dart';
import '../viewmodels/search_filter_view_model.dart';

class AreaFilterScreen extends StatefulWidget {
  const AreaFilterScreen({super.key});

  @override
  State<AreaFilterScreen> createState() => _AreaFilterScreenState();
}

class _AreaFilterScreenState extends State<AreaFilterScreen> {
  // Lokalne zmienne do edycji przed "Zastosowaniem"
  String? _tmpType, _tmpCanopy, _tmpWater, _tmpSlope;
  List<String> _tmpSubstrates = [];
  RangeValues _tmpPh = const RangeValues(3.0, 9.0);

  @override
  void initState() {
    super.initState();
    final vm = context.read<SearchFilterViewModel>();
    _tmpType = vm.areaFilterType;
    _tmpCanopy = vm.areaFilterCanopy;
    _tmpWater = vm.areaFilterWater;
    _tmpSlope = vm.areaFilterSlope;
    _tmpSubstrates = List.from(vm.areaFilterSubstrates);
    _tmpPh = vm.areaFilterPh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      app_bar: AppBar(title: const Text("Filtruj Obszary"), actions: [
        TextButton(onPressed: () => setState(() {
          _tmpType = _tmpCanopy = _tmpWater = _tmpSlope = null;
          _tmpSubstrates.clear();
          _tmpPh = const RangeValues(3.0, 9.0);
        }), child: const Text("RESET", style: TextStyle(color: Colors.white)))
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _tmpType, (v) => setState(() => _tmpType = v)),
          _buildDropdown("Zwarcie koron", HabitatInfo.canopyCoverOptions, _tmpCanopy, (v) => setState(() => _tmpCanopy = v)),
          _buildDropdown("Dynamika wody", HabitatInfo.waterDynamicsOptions, _tmpWater, (v) => setState(() => _tmpWater = v)),
          _buildDropdown("Kąt nachylenia", HabitatInfo.slopeAngleOptions, _tmpSlope, (v) => setState(() => _tmpSlope = v)),

          const Divider(height: 30),
          const Text("Typ podłoża (Musi zawierać wybrane):", style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: HabitatInfo.substrateOptions.map((opt) {
              final isSelected = _tmpSubstrates.contains(opt);
              return FilterChip(
                label: Text(opt), selected: isSelected,
                onSelected: (s) => setState(() => s ? _tmpSubstrates.add(opt) : _tmpSubstrates.remove(opt)),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
          Text("Zakres pH: ${_tmpPh.start.toStringAsFixed(1)} - ${_tmpPh.end.toStringAsFixed(1)}"),
          RangeSlider(
            values: _tmpPh, min: 3.0, max: 9.0, divisions: 60,
            onChanged: (v) => setState(() => _tmpPh = v),
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            onPressed: () {
              context.read<SearchFilterViewModel>().updateAreaFilters(
                  type: _tmpType, canopy: _tmpCanopy, water: _tmpWater, slope: _tmpSlope,
                  substrates: _tmpSubstrates, ph: _tmpPh
              );
              Navigator.pop(context);
            },
            child: const Text("ZASTOSUJ FILTRY", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null, // Zabezpieczenie przed błędem asercji
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}