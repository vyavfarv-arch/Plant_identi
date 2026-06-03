// lib/views/add_observation_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import 'form_screen.dart';

class AddObservationScreen extends StatefulWidget {
  final PlantSpecies? preselectedSpecies;

  const AddObservationScreen({super.key, this.preselectedSpecies});

  @override
  State<AddObservationScreen> createState() => _AddObservationScreenState();
}

class _AddObservationScreenState extends State<AddObservationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();
  String? _targetSpeciesId;
  bool _isQuickAddMode = false;
  String? _selectedType;

  String? _selectedPhenology;
  String? _selectedAbundance;
  String? _selectedVitality;

  final List<String> _biologicalTypes = ["Drzewo", "Krzew", "Zielne", "Grzyb", "Mszaki"];

  // JEDNO ZUNIFIKOWANE ŹRÓDŁO PRAWDY DLA SŁOWNIKÓW BOTANICZNYCH
  final Map<String, String> _phenologyOptions = {
    "Wegetatywny": "Rozwój pędów i liści",
    "Pączkowanie": "Widoczne pąki kwiatowe",
    "Kwitnienie": "Rozwinięte kwiaty",
    "Owocowanie": "Zawiązywanie i dojrzewanie owoców",
    "Rozsiewanie": "Wysiew nasion/zarodników",
    "Spoczynek": "Zamieranie jesienne / stan zimowy"
  };

  final Map<String, String> _abundanceOptions = {
    "5": "75-100% pokrycia", "4": "50-75% pokrycia", "3": "25-50%", "2": "5-25%", "1": "<5%", "0": "nielicznie"
  };

  final Map<String, String> _vitalityOptions = {
    "4": "Bardzo dobra", "3": "Dobra", "2": "Słaba", "1": "Zamierająca"
  };

  @override
  void initState() {
    super.initState();
    if (widget.preselectedSpecies != null) {
      _nameController.text = widget.preselectedSpecies!.polishName;
      _latinController.text = widget.preselectedSpecies!.latinName;
      _targetSpeciesId = widget.preselectedSpecies!.speciesID;
      _selectedType = widget.preselectedSpecies!.biologicalType;
      _isQuickAddMode = true;
    }
    Future.microtask(() => context.read<ObservationViewModel>().reset());
    Future.microtask(() => context.read<ObservationViewModel>().init());
  }

  void _applyFoundSpecies(PlantSpecies species) {
    setState(() {
      _nameController.text = species.polishName;
      _latinController.text = species.latinName;
      _targetSpeciesId = species.speciesID;
      _selectedType = species.biologicalType;
    });
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final bool isFormValid = obsVm.currentPhotoPaths.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _selectedPhenology != null &&
        _selectedAbundance != null &&
        _selectedVitality != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isQuickAddMode ? "Szybki wpis: ${_nameController.text}" : "Klasyfikacja Nowego Okazu"),
        backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("1. Identyfikacja i Typ taksonomiczny", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              if (_isQuickAddMode)
                Container(
                  padding: const EdgeInsets.all(12), width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Text("Gatunek zweryfikowany z bazy: ${_nameController.text} (${_latinController.text})", style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                )
              else ...[
                Autocomplete<String>(
                  optionsBuilder: (val) => val.text.isEmpty ? const Iterable.empty() : obsVm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())),
                  onSelected: (sel) { final s = obsVm.findSpeciesByLatinName(sel); if (s != null) _applyFoundSpecies(s); },
                  fieldViewBuilder: (ctx, ctrl, node, onSub) {
                    if (_latinController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _latinController.text;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Szukaj nazwy łacińskiej...", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => _latinController.text = v),
                    );
                  },
                ),
                Autocomplete<String>(
                  optionsBuilder: (val) => val.text.isEmpty ? const Iterable.empty() : obsVm.speciesDictionary.map((s) => s.polishName).where((n) => n.toLowerCase().contains(val.text.toLowerCase())),
                  onSelected: (sel) { final s = obsVm.findSpeciesByPolishName(sel); if (s != null) _applyFoundSpecies(s); },
                  fieldViewBuilder: (ctx, ctrl, node, onSub) {
                    if (_nameController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _nameController.text;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Szukaj nazwy polskiej...", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => _nameController.text = v),
                    );
                  },
                ),

                if (_selectedType == null) ...[
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Wybierz typ biologiczny:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2),
                    itemCount: _biologicalTypes.length,
                    itemBuilder: (ctx, i) {
                      final t = _biologicalTypes[i];
                      final isSelected = _selectedType == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = t),
                        child: Container(
                          decoration: BoxDecoration(color: isSelected ? Colors.green : Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400)),
                          child: Center(child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87))),
                        ),
                      );
                    },
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [Text("Typ biologiczny: $_selectedType", style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.edit, size: 16), onPressed: () => setState(() => _selectedType = null))]),
                  )
              ],

              const Divider(height: 40),
              const Text("2. Dokumentacja foto (Wymagana)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                height: 180, width: double.infinity,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                child: obsVm.currentPhotoPaths.isNotEmpty
                    ? Image.file(File(obsVm.currentPhotoPaths.first), fit: BoxFit.cover)
                    : (obsVm.controller != null && obsVm.controller!.value.isInitialized
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CameraPreview(obsVm.controller!))
                    : const Center(child: CircularProgressIndicator())),
              ),
              const SizedBox(height: 10),
              if (obsVm.currentPhotoPaths.isEmpty)
                SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text("URUCHOM I ZRÓB ZDJĘCIE"), onPressed: () => obsVm.takePhoto()))
              else
                SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text("POWTÓRZ FOTKĘ"), onPressed: () => obsVm.removePhoto(0))),

              const Divider(height: 40),
              const Text("3. Parametry ekologiczne okazu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildDropdown("Etap fenologiczny rozwoju", _phenologyOptions, (v) => setState(() => _selectedPhenology = v)),
              _buildDropdown("Ilościowość w skali", _abundanceOptions, (v) => setState(() => _selectedAbundance = v)),
              _buildDropdown("Żywotność stanowiska", _vitalityOptions, (v) => setState(() => _selectedVitality = v)),

              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                  onPressed: (!isFormValid || (_selectedType == null)) ? null : _executeSaveFlow,
                  child: Text(_isQuickAddMode ? "ZAPISZ EKSPRESOWO OKAZ" : "DALEJ DO OPISU MORFOLOGII", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, Map<String, String> map, Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<String>(isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), items: map.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.key} - ${e.value}", style: const TextStyle(fontSize: 13)))).toList(), onChanged: onChanged),
  );

  void _executeSaveFlow() async {
    final obsVm = context.read<ObservationViewModel>();

    final newObs = PlantObservation(
      id: const Uuid().v4(), speciesId: _targetSpeciesId ?? const Uuid().v4(), localName: _nameController.text.trim(), subspecies: "",
      latitude: obsVm.currentPosition?.latitude ?? 0.0, longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(), observationDate: DateTime.now(), photoPaths: List.from(obsVm.currentPhotoPaths), characteristics: {},
      tempBiologicalType: _selectedType, phenologicalStage: _selectedPhenology, abundance: _selectedAbundance, vitality: _selectedVitality,
    );

    if (_isQuickAddMode) {
      // SZYBKI ZAPIS (Zgodnie z wytyczną: pomija opis cech morfologicznych FormScreen)
      await obsVm.addObservation(newObs);
      obsVm.reset();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.teal, content: Text("Okaz został ekspresowo zaewidencjonowany w Magazynie.")));
      }
    } else {
      // NOWY GATUNEK: Przekierowanie do FormScreen w celu zebrania unikalnych cech wizualnych
      if (_targetSpeciesId == null) {
        final newSpecies = PlantSpecies(speciesID: newObs.speciesId!, latinName: _latinController.text.trim(), polishName: _nameController.text.trim(), family: "Nieokreślona", biologicalType: _selectedType!);
        await obsVm.addSpecies(newSpecies);
      }
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FormScreen(observation: newObs)));
      }
    }
  }
}