// lib/views/quick_add_observation_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';

class QuickAddObservationScreen extends StatefulWidget {
  final PlantSpecies? preselectedSpecies;

  const QuickAddObservationScreen({super.key, this.preselectedSpecies});

  @override
  State<QuickAddObservationScreen> createState() => _QuickAddObservationScreenState();
}

class _QuickAddObservationScreenState extends State<QuickAddObservationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();
  String? _targetSpeciesId;
  bool _isReadOnly = false;

  String? _selectedPhenology;
  String? _selectedAbundance;
  String? _selectedVitality;

  final Map<String, String> _phenologyOptions = {
    "Wegetatywny": "Rozwój pędów/liści", "Pączkowanie": "Pąki kwiatowe",
    "Kwitnienie": "Rozwinięte kwiaty", "Owocowanie": "Dojrzewanie owoców",
    "Rozsiewanie": "Wysiew nasion", "Spoczynek": "Stan zimowy"
  };

  final Map<String, String> _abundanceOptions = {"5": "75-100%", "4": "50-75%", "3": "25-50%", "2": "5-25%", "1": "<5%", "0": "nielicznie"};
  final Map<String, String> _vitalityOptions = {"4": "Bardzo dobra", "3": "Dobra", "2": "Słaba", "1": "Zamierająca"};

  @override
  void initState() {
    super.initState();
    _checkPreselectedData();
    Future.microtask(() => context.read<ObservationViewModel>().reset());
    Future.microtask(() => context.read<ObservationViewModel>().init());
  }

  void _checkPreselectedData() {
    if (widget.preselectedSpecies != null) {
      _nameController.text = widget.preselectedSpecies!.polishName;
      _latinController.text = widget.preselectedSpecies!.latinName;
      _targetSpeciesId = widget.preselectedSpecies!.speciesID;
      _isReadOnly = true;
    }
  }

  void _applyFoundSpecies(PlantSpecies species) {
    setState(() {
      _nameController.text = species.polishName;
      _latinController.text = species.latinName;
      _targetSpeciesId = species.speciesID;
    });
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();

    return Scaffold(
      appBar: AppBar(
          title: Text(_isReadOnly ? "Szybki wpis: ${_nameController.text}" : "Szybki Zapis Okazu"),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("1. Identyfikacja gatunku", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              if (!_isReadOnly) ...[
                Autocomplete<String>(
                  optionsBuilder: (val) => val.text.isEmpty
                      ? const Iterable.empty()
                      : obsVm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())),
                  onSelected: (selection) {
                    final species = obsVm.findSpeciesByLatinName(selection);
                    if (species != null) _applyFoundSpecies(species);
                  },
                  fieldViewBuilder: (ctx, ctrl, node, onSub) {
                    if (_latinController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _latinController.text;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Szukaj nazwy łacińskiej...", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => _latinController.text = v),
                    );
                  },
                ),

                Autocomplete<String>(
                  optionsBuilder: (val) => val.text.isEmpty
                      ? const Iterable.empty()
                      : obsVm.speciesDictionary.map((s) => s.polishName).where((name) => name.toLowerCase().contains(val.text.toLowerCase())),
                  onSelected: (selection) {
                    final species = obsVm.findSpeciesByPolishName(selection);
                    if (species != null) _applyFoundSpecies(species);
                  },
                  fieldViewBuilder: (ctx, ctrl, node, onSub) {
                    if (_nameController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _nameController.text;
                    return TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Szukaj nazwy polskiej (zwyczajowej)...", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => _nameController.text = v);
                  },
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Text("Gatunek zweryfikowany: ${_nameController.text} (${_latinController.text})", style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ),

              const Divider(height: 40),
              const Text("2. Dokumentacja foto (Wymagana)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                child: obsVm.currentPhotoPaths.isNotEmpty
                    ? Image.file(File(obsVm.currentPhotoPaths.first), fit: BoxFit.cover)
                    : (obsVm.controller != null && obsVm.controller!.value.isInitialized
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CameraPreview(obsVm.controller!))
                    : const Center(child: CircularProgressIndicator())),
              ),
              const SizedBox(height: 10),
              if (obsVm.currentPhotoPaths.isEmpty)
                SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text("ZRÓB ZDJĘCIE"), onPressed: () => obsVm.takePhoto()))
              else
                SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text("POWTÓRZ ZDJĘCIE"), onPressed: () => obsVm.removePhoto(0))),

              const Divider(height: 40),
              const Text("3. Ocena populacji", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDropdown("Etap fenologiczny", _phenologyOptions, (v) => setState(() => _selectedPhenology = v)),
              _buildDropdown("Ilościowość", _abundanceOptions, (v) => setState(() => _selectedAbundance = v)),
              _buildDropdown("Żywotność", _vitalityOptions, (v) => setState(() => _selectedVitality = v)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: (obsVm.currentPhotoPaths.isEmpty || _nameController.text.isEmpty || _selectedPhenology == null || _selectedAbundance == null || _selectedVitality == null)
                      ? null
                      : _handleQuickSave,
                  child: const Text("ZAPISZ SZYBKO OKAZ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, Map<String, String> map, Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), items: map.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.key} - ${e.value}", style: const TextStyle(fontSize: 13)))).toList(), onChanged: onChanged),
  );

  void _handleQuickSave() async {
    final obsVm = context.read<ObservationViewModel>();

    if (_targetSpeciesId == null) {
      final found = obsVm.findSpeciesByLatinName(_latinController.text) ?? obsVm.findSpeciesByPolishName(_nameController.text);
      if (found != null) _targetSpeciesId = found.speciesID;
    }

    String finalSpeciesId = _targetSpeciesId ?? const Uuid().v4();

    if (_targetSpeciesId == null) {
      final newSpecies = PlantSpecies(
        speciesID: finalSpeciesId,
        latinName: _latinController.text.trim(),
        polishName: _nameController.text.trim(),
        family: "Nieokreślona (Szybki zapis)",
        biologicalType: "Zielne",
      );
      await obsVm.addSpecies(newSpecies);
    }

    final newObs = PlantObservation(
      id: const Uuid().v4(), speciesId: finalSpeciesId, localName: _nameController.text.trim(), subspecies: "",
      latitude: obsVm.currentPosition?.latitude ?? 0.0, longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(), observationDate: DateTime.now(),
      photoPaths: List.from(obsVm.currentPhotoPaths), characteristics: {},
      phenologicalStage: _selectedPhenology, abundance: _selectedAbundance, vitality: _selectedVitality,
    );

    await obsVm.addObservation(newObs);
    obsVm.reset();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.teal, content: Text("Pomyślnie dodano kolejny okaz do bazy.")));
    }
  }
}