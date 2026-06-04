// lib/views/add_observation_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../models/description_schema.dart';
import '../viewmodels/observation_view_model.dart';

class AddObservationScreen extends StatefulWidget {
  final PlantSpecies? preselectedSpecies;
  final bool forcedQuickMode;

  const AddObservationScreen({super.key, this.preselectedSpecies, this.forcedQuickMode = false});

  @override
  State<AddObservationScreen> createState() => _AddObservationScreenState();
}

class _AddObservationScreenState extends State<AddObservationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();
  String? _targetSpeciesId;
  bool _isQuickMode = false;
  String? _selectedType;

  String? _selectedPhenology;
  String? _selectedAbundance;
  String? _selectedVitality;
  final Map<String, List<String>> _morphologyValues = {};

  final List<String> _biologicalTypes = ["Drzewo", "Krzew", "Zielne", "Grzyb", "Mszaki"];

  final Map<String, String> _phenologyOptions = {"Wegetatywny": "Rozwój pędów/liści", "Pączkowanie": "Widoczne pąki kwiatowe", "Kwitnienie": "Rozwinięte kwiaty", "Owocowanie": "Zawiązywanie owoców", "Rozsiewanie": "Wysiew nasion", "Spoczynek": "Stan zimowy"};
  final Map<String, String> _abundanceOptions = {"5": "75-100% pokrycia", "4": "50-75%", "3": "25-50%", "2": "5-25%", "1": "<5%", "0": "nielicznie"};
  final Map<String, String> _vitalityOptions = {"4": "Bardzo dobra", "3": "Dobra", "2": "Słaba", "1": "Zamierająca"};

  @override
  void initState() {
    super.initState();
    _isQuickMode = widget.preselectedSpecies != null || widget.forcedQuickMode;
    if (widget.preselectedSpecies != null) {
      _nameController.text = widget.preselectedSpecies!.polishName;
      _latinController.text = widget.preselectedSpecies!.latinName;
      _targetSpeciesId = widget.preselectedSpecies!.speciesID;
      _selectedType = widget.preselectedSpecies!.biologicalType;
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
    final totalPages = _isQuickMode ? 2 : 3;

    return Scaffold(
      appBar: AppBar(title: Text(_isQuickMode ? "Szybki wpis: Krok ${_currentPage + 1}/2" : "Pełny opis: Krok ${_currentPage + 1}/3"), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController, physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildPhotoPage(obsVm),
                  _isQuickMode ? _buildQuickPopulationPage() : _buildLongTaxonomyPage(obsVm),
                  if (!_isQuickMode) _buildMorphologyChecklistPage(),
                ],
              ),
            ),
            _buildNavigationRow(obsVm, totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPage(ObservationViewModel vm) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Krok 1: Dokumentacja fotograficzna okazu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 15), Container(height: 240, width: double.infinity, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)), child: vm.currentPhotoPaths.isNotEmpty ? Image.file(File(vm.currentPhotoPaths.first), fit: BoxFit.cover) : (vm.controller != null && vm.controller!.value.isInitialized ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CameraPreview(vm.controller!)) : const Center(child: CircularProgressIndicator()))), const SizedBox(height: 15), if (vm.currentPhotoPaths.isEmpty) SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text("ZRÓB ZDJĘCIE"), onPressed: () => vm.takePhoto())) else SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text("POWTÓRZ ZDJĘCIE"), onPressed: () => vm.removePhoto(0)))]));

  Widget _buildQuickPopulationPage() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Krok 2: Stan stanowiska: ${_nameController.text}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 15), _buildDropdown("Etap fenologiczny rozwoju", _phenologyOptions, _selectedPhenology, (v) => setState(() => _selectedPhenology = v)), _buildDropdown("Ilościowość w skali", _abundanceOptions, _selectedAbundance, (v) => setState(() => _selectedAbundance = v)), _buildDropdown("Żywotność stanowiska", _vitalityOptions, _selectedVitality, (v) => setState(() => _selectedVitality = v))]));

  Widget _buildLongTaxonomyPage(ObservationViewModel vm) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Krok 2: Identyfikacja taksonu i parametry ekologiczne", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 15), Autocomplete<String>(optionsBuilder: (val) => val.text.isEmpty ? const Iterable.empty() : vm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())), onSelected: (sel) { final s = vm.findSpeciesByLatinName(sel); if (s != null) _applyFoundSpecies(s); }, fieldViewBuilder: (ctx, ctrl, node, onSub) { if (_latinController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _latinController.text; return Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Nazwa łacińska...", border: OutlineInputBorder()), onChanged: (v) => _latinController.text = v)); }), Autocomplete<String>(optionsBuilder: (val) => val.text.isEmpty ? const Iterable.empty() : vm.speciesDictionary.map((s) => s.polishName).where((n) => n.toLowerCase().contains(val.text.toLowerCase())), onSelected: (sel) { final s = vm.findSpeciesByPolishName(sel); if (s != null) _applyFoundSpecies(s); }, fieldViewBuilder: (ctx, ctrl, node, onSub) { if (_nameController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _nameController.text; return Padding(padding: const EdgeInsets.only(bottom: 15), child: TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Nazwa polska...", border: OutlineInputBorder()), onChanged: (v) => _nameController.text = v)); }), const Padding(padding: EdgeInsets.symmetric(vertical: 4.0), child: Text("Wybierz typ biologiczny:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))), GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2), itemCount: _biologicalTypes.length, itemBuilder: (ctx, i) { final t = _biologicalTypes[i]; final isSelected = _selectedType == t; return GestureDetector(onTap: () => setState(() => _selectedType = t), child: Container(decoration: BoxDecoration(color: isSelected ? Colors.green : Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400)), child: Center(child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87))))); }), const Divider(height: 30), _buildDropdown("Etap fenologiczny rozwoju", _phenologyOptions, _selectedPhenology, (v) => setState(() => _selectedPhenology = v)), _buildDropdown("Ilościowość w skali", _abundanceOptions, _selectedAbundance, (v) => setState(() => _selectedAbundance = v)), _buildDropdown("Żywotność stanowiska", _vitalityOptions, _selectedVitality, (v) => setState(() => _selectedVitality = v))]));

  Widget _buildMorphologyChecklistPage() {
    final schema = SchemaGenerator.getForType(_selectedType ?? "Zielne");
    return ListView.builder(
      itemCount: schema.length,
      itemBuilder: (context, index) {
        final category = schema[index];
        return ExpansionTile(
          leading: CircleAvatar(backgroundColor: Colors.green, child: Text(category.number, style: const TextStyle(color: Colors.white))),
          title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: category.subCategories.entries.map((sub) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sub.key, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: sub.value.map((opt) {
                final isSelected = _morphologyValues[sub.key]?.contains(opt) ?? false;
                return ChoiceChip(label: Text(opt), selected: isSelected, onSelected: (s) => setState(() { if (s) _morphologyValues.putIfAbsent(sub.key, () => []).add(opt); else _morphologyValues[sub.key]?.remove(opt); }));
              }).toList())
            ]),
          )).toList(),
        );
      },
    );
  }

  Widget _buildDropdown(String label, Map<String, String> map, String? value, Function(String?) onChanged) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: DropdownButtonFormField<String>(value: value, isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), items: map.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.key} - ${e.value}", style: const TextStyle(fontSize: 13)))).toList(), onChanged: onChanged));

  Widget _buildNavigationRow(ObservationViewModel vm, int totalPages) {
    final bool canGoNext = _currentPage == 0 ? vm.currentPhotoPaths.isNotEmpty : (_currentPage == 1 ? (_nameController.text.isNotEmpty && _selectedType != null && _selectedPhenology != null && _selectedAbundance != null && _selectedVitality != null) : true);

    return Container(
      padding: const EdgeInsets.all(16), color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(onPressed: () { if (_currentPage == 0) { Navigator.pop(context); } else { _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut); } }, child: Text(_currentPage == 0 ? "ANULUJ" : "WSTECZ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: !canGoNext ? null : () { if (_currentPage < (totalPages - 1)) { _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut); } else { _finalizeSave(vm); } },
            child: Text(_currentPage == (totalPages - 1) ? "ZAPISZ OBSZAR" : "DALEJ"),
          ),
        ],
      ),
    );
  }

  void _finalizeSave(ObservationViewModel obsVm) async {
    String finalSpeciesId = _targetSpeciesId ?? const Uuid().v4();

    // Dla trybu długiego, jeśli dodajemy nowy gatunek
    if (!_isQuickMode && _targetSpeciesId == null) {
      final newSpecies = PlantSpecies(speciesID: finalSpeciesId, latinName: _latinController.text.trim(), polishName: _nameController.text.trim(), family: "Nieokreślona", biologicalType: _selectedType!);
      await obsVm.addSpecies(newSpecies);
    }

    final newObs = PlantObservation(
      id: const Uuid().v4(), speciesId: finalSpeciesId, localName: _nameController.text.trim(), subspecies: "", latitude: obsVm.currentPosition?.latitude ?? 0.0, longitude: obsVm.currentPosition?.longitude ?? 0.0, timestamp: DateTime.now(), observationDate: DateTime.now(), photoPaths: List.from(obsVm.currentPhotoPaths), phenologicalStage: _selectedPhenology, abundance: _selectedAbundance, vitality: _selectedVitality, tempBiologicalType: _selectedType,
      characteristics: Map.from(_morphologyValues), // Zapis cech morfologicznych dla trybu długiego (pusta mapa dla trybu szybkiego)
    );

    await obsVm.addObservation(newObs);
    obsVm.reset();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.teal, content: Text("Ewidencja okazu zakończona pomyślnie.")));
    }
  }
}