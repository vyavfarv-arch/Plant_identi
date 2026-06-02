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
  String? _tmpType, _tmpWater, _tmpSlope;
  List<String> _tmpSubstrates = [];
  RangeValues _tmpPh = const RangeValues(3.0, 9.0);

  @override
  void initState() {
    super.initState();
    final vm = context.read<SearchFilterViewModel>();
    _tmpType = vm.areaFilterType;
    _tmpWater = vm.areaFilterWater;
    _tmpSlope = vm.areaFilterSlope;
    _tmpSubstrates = List.from(vm.areaFilterSubstrates);
    _tmpPh = vm.areaFilterPh;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Filtruj Obszary"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _tmpType = _tmpWater = _tmpSlope = null;
              _tmpSubstrates.clear();
              _tmpPh = const RangeValues(3.0, 9.0);
            }),
            child: const Text("RESET", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _tmpType, (v) => setState(() => _tmpType = v)),
          _buildDropdown("Ruch i natlenienie wody", HabitatInfo.waterMovementOptions, _tmpWater, (v) => setState(() => _tmpWater = v)),
          _buildDropdown("Kąt nachylenia stoku", HabitatInfo.slopeAngleOptions, _tmpSlope, (v) => setState(() => _tmpSlope = v)),

          const Divider(height: 30),
          const Text("Typ podłoża mineralno-organicznego:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: HabitatInfo.substrateOptions.map((opt) {
              final isSelected = _tmpSubstrates.contains(opt);
              return FilterChip(
                label: Text(opt), selected: isSelected, selectedColor: Colors.indigo.shade100,
                onSelected: (s) => setState(() => s ? _tmpSubstrates.add(opt) : _tmpSubstrates.remove(opt)),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
          Text("Zakres pH gleby: ${_tmpPh.start.toStringAsFixed(1)} - ${_tmpPh.end.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _tmpPh, min: 3.0, max: 9.0, divisions: 60, activeColor: Colors.indigo,
            onChanged: (v) => setState(() => _tmpPh = v),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: () { _applyFiltersToViewModel(); Navigator.pop(context); },
            child: const Text("ZASTOSUJ FILTRY (LISTA)", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _applyFiltersToViewModel() {
    context.read<SearchFilterViewModel>().updateAreaFilters(
      type: _tmpType, canopy: null, water: _tmpWater, slope: _tmpSlope, substrates: _tmpSubstrates, ph: _tmpPh,
    );
  }
}