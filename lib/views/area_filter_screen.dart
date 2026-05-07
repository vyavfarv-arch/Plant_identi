// lib/views/area_filter_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habitat_info.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import 'filtered_areas_map_screen.dart';

class AreaFilterScreen extends StatefulWidget {
  const AreaFilterScreen({super.key});

  @override
  State<AreaFilterScreen> createState() => _AreaFilterScreenState();
}

class _AreaFilterScreenState extends State<AreaFilterScreen> {
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
      appBar: AppBar(
        title: const Text("Filtruj Obszary"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _tmpType = _tmpCanopy = _tmpWater = _tmpSlope = null;
              _tmpSubstrates.clear();
              _tmpPh = const RangeValues(3.0, 9.0);
            }),
            child: const Text("RESET", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDropdown("Typ obszaru", HabitatInfo.areaTypeOptions, _tmpType, (v) => setState(() => _tmpType = v)),
          _buildDropdown("Zwarcie koron", HabitatInfo.canopyCoverOptions, _tmpCanopy, (v) => setState(() => _tmpCanopy = v)),
          _buildDropdown("Dynamika wody", HabitatInfo.waterDynamicsOptions, _tmpWater, (v) => setState(() => _tmpWater = v)),
          _buildDropdown("Kąt nachylenia", HabitatInfo.slopeAngleOptions, _tmpSlope, (v) => setState(() => _tmpSlope = v)),

          const Divider(height: 30),
          const Text("Typ podłoża (musi zawierać wybrane):", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: HabitatInfo.substrateOptions.map((opt) {
              final isSelected = _tmpSubstrates.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: isSelected,
                selectedColor: Colors.indigo.shade100,
                onSelected: (s) => setState(() => s ? _tmpSubstrates.add(opt) : _tmpSubstrates.remove(opt)),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
          Text("Zakres pH: ${_tmpPh.start.toStringAsFixed(1)} - ${_tmpPh.end.toStringAsFixed(1)}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _tmpPh,
            min: 3.0,
            max: 9.0,
            divisions: 60,
            activeColor: Colors.indigo,
            onChanged: (v) => setState(() => _tmpPh = v),
          ),

          const SizedBox(height: 40),

          // PRZYCISK 1: ZASTOSUJ I WRÓĆ
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: () {
              _applyFiltersToViewModel();
              Navigator.pop(context);
            },
            child: const Text("ZASTOSUJ FILTRY (LISTA)", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 12),

          // PRZYCISK 2: POKAŻ NA MAPIE
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(15),
              side: const BorderSide(color: Colors.indigo, width: 2),
              foregroundColor: Colors.indigo,
            ),
            onPressed: () => _showResultsOnMap(),
            icon: const Icon(Icons.map),
            label: const Text("POKAŻ WYNIKI NA MAPIE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _applyFiltersToViewModel() {
    context.read<SearchFilterViewModel>().updateAreaFilters(
      type: _tmpType,
      canopy: _tmpCanopy,
      water: _tmpWater,
      slope: _tmpSlope,
      substrates: _tmpSubstrates,
      ph: _tmpPh,
    );
  }

  void _showResultsOnMap() {
    final allReleves = context.read<ReleveViewModel>().allReleves;

    final filtered = allReleves.where((r) {
      final h = r.habitat;
      if (h == null) return false;

      if (_tmpType != null && h.areaType != _tmpType) return false;
      if (_tmpCanopy != null && h.canopyCover != _tmpCanopy) return false;
      if (_tmpWater != null && h.waterDynamics != _tmpWater) return false;
      if (_tmpSlope != null && h.slopeAngle != _tmpSlope) return false;

      // Logika AND dla podłoży
      if (_tmpSubstrates.isNotEmpty) {
        bool hasAll = _tmpSubstrates.every((s) => h.substrateType.contains(s));
        if (!hasAll) return false;
      }

      if (h.ph != null) {
        if (h.ph! < _tmpPh.start || h.ph! > _tmpPh.end) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Brak obszarów spełniających wybrane kryteria.")));
      return;
    }

    _applyFiltersToViewModel();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FilteredAreasMapScreen(filteredAreas: filtered)),
    );
  }
}