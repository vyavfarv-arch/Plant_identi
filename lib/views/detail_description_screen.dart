// lib/views/detail_description_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import 'dart:io';

class DetailDescriptionScreen extends StatefulWidget {
  final PlantObservation observation;
  const DetailDescriptionScreen({super.key, required this.observation});

  @override
  State<DetailDescriptionScreen> createState() => _DetailDescriptionScreenState();
}

class _DetailDescriptionScreenState extends State<DetailDescriptionScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedCertainty;

  // Preferencje numeryczne
  double _prefPhMin = 5.5;
  double _prefPhMax = 7.5;

  // NOWE: Zaawansowane listy preferencji (Lustrzane odbicie HabitatInfo)
  final List<String> _prefAreaTypes = [];
  final List<String> _prefExposures = [];
  final List<String> _prefCanopyCovers = [];
  final List<String> _prefWaterDynamics = [];
  final List<String> _prefSoilDepths = [];

  // Opcje do wyboru
  final List<String> _areaTypeOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Teren miejski", "Skraj lasu"];
  final List<String> _exposureOptions = ["N", "S", "E", "W", "Płasko"];
  final List<String> _canopyOptions = ["Otwarte (0-25%)", "Półotwarte (25-60%)", "Zacienione (60-85%)", "Gęste (>85%)"];
  final List<String> _waterOptions = ["Stale wilgotne", "Sezonowo zalewane", "Sezonowo wysychające", "Stale suche"];
  final List<String> _soilOptions = ["Płytka skalista", "Średnia", "Głęboka próchnowa"];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final obs = widget.observation;
    final obsVm = context.read<ObservationViewModel>();
    final species = obsVm.getSpeciesById(obs.speciesId);

    _controllers['family'] = TextEditingController(text: species?.family ?? '');
    _controllers['subspecies'] = TextEditingController(text: obs.subspecies ?? '');
    _controllers['localName'] = TextEditingController(text: obs.localName ?? '');
    _controllers['latinName'] = TextEditingController(text: species?.latinName ?? '');
    _controllers['idDoubts'] = TextEditingController(text: obs.idDoubts ?? '');
    _controllers['keyTraits'] = TextEditingController(text: obs.keyMorphologicalTraits ?? '');
    _controllers['confusing'] = TextEditingController(text: obs.confusingSpecies ?? '');
    _controllers['characteristic'] = TextEditingController(text: obs.characteristicFeature ?? '');
    _controllers['usage'] = TextEditingController(text: species?.plantUsage ?? '');
    _controllers['cultivation'] = TextEditingController(text: species?.cultivation ?? '');

    _selectedCertainty = obs.certainty;
    if (species != null) _applySpeciesData(species);
  }

  // Funkcja aplikująca dane gatunku do formularza (Autouzupełnianie)
  void _applySpeciesData(PlantSpecies s) {
    setState(() {
      _controllers['family']!.text = s.family;
      _controllers['localName']!.text = s.polishName;
      _controllers['usage']!.text = s.plantUsage ?? "";
      _controllers['cultivation']!.text = s.cultivation ?? "";

      _prefPhMin = s.prefPhMin ?? 5.5;
      _prefPhMax = s.prefPhMax ?? 7.5;

      _prefAreaTypes.clear(); _prefAreaTypes.addAll(s.prefAreaTypes);
      _prefExposures.clear(); _prefExposures.addAll(s.prefExposures);
      _prefCanopyCovers.clear(); _prefCanopyCovers.addAll(s.prefCanopyCovers);
      _prefWaterDynamics.clear(); _prefWaterDynamics.addAll(s.prefWaterDynamics);
      _prefSoilDepths.clear(); _prefSoilDepths.addAll(s.prefSoilDepths);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj dane gatunku")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildCapturedPhotosPreview(),
          _buildNamingAndCertaintySection(),
          _buildAdvancedEcologicalSection(),
          _buildUsageSection(),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _saveAndGoBack,
            child: const Text("ZAPISZ I AKTUALIZUJ SŁOWNIK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildNamingAndCertaintySection() {
    final obsVm = context.watch<ObservationViewModel>();

    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text("Taksonomia i Pewność", style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        // INTELIGENTNE POLE: Nazwa Łacińska z Autocomplete
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return obsVm.allLatinNames.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _controllers['latinName']!.text = selection;
              final found = obsVm.findSpeciesByLatinName(selection);
              if (found != null) _applySpeciesData(found);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              if (_controllers['latinName']!.text.isNotEmpty && controller.text.isEmpty) {
                controller.text = _controllers['latinName']!.text;
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: "Nazwa Łacińska (szukaj...)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
                onChanged: (val) => _controllers['latinName']!.text = val,
              );
            },
          ),
        ),
        _inputField(_controllers['localName']!, "Nazwa polska"),
        _inputField(_controllers['family']!, "Rodzina"),
        _inputField(_controllers['subspecies']!, "Odmiana/Podgatunek"),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: _selectedCertainty,
            items: ['Wysoka', 'Średnia', 'Niska'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedCertainty = v),
            decoration: const InputDecoration(labelText: "Stopień pewności identyfikacji", border: OutlineInputBorder()),
          ),
        ),
        _inputField(_controllers['idDoubts']!, "Wątpliwości/Uwagi", isLong: true),
      ],
    );
  }

  Widget _buildAdvancedEcologicalSection() {
    return ExpansionTile(
      title: const Text("Amplituda ekologiczna (ML)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Zaznacz wszystkie warunki, w których ten gatunek występuje:", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
              const Divider(),
              _buildMultiSelect("Typy obszaru:", _areaTypeOptions, _prefAreaTypes),
              _buildMultiSelect("Ekspozycja stoku:", _exposureOptions, _prefExposures),
              _buildMultiSelect("Zwarcie koron:", _canopyOptions, _prefCanopyCovers),
              _buildMultiSelect("Dynamika wody:", _waterOptions, _prefWaterDynamics),
              _buildMultiSelect("Głębokość gleby:", _soilOptions, _prefSoilDepths),
              const Divider(),
              Text("Preferowane pH: ${_prefPhMin.toStringAsFixed(1)} - ${_prefPhMax.toStringAsFixed(1)}"),
              RangeSlider(values: RangeValues(_prefPhMin, _prefPhMax), min: 3.0, max: 9.0, divisions: 60, onChanged: (v) => setState(() { _prefPhMin = v.start; _prefPhMax = v.end; })),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = targetList.contains(opt);
            return FilterChip(
              label: Text(opt, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black)),
              selected: isSelected,
              selectedColor: Colors.teal,
              onSelected: (s) => setState(() => s ? targetList.add(opt) : targetList.remove(opt)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUsageSection() {
    return ExpansionTile(
      title: const Text("Wykorzystanie i Hodowla"),
      children: [
        _inputField(_controllers['usage']!, "Zastosowanie", isLong: true),
        _inputField(_controllers['cultivation']!, "Hodowla", isLong: true),
      ],
    );
  }

  Widget _buildCapturedPhotosPreview() {
    final photos = widget.observation.photoPaths;
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120, margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: photos.length,
        itemBuilder: (context, index) {
          final path = photos[index];
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, path),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover)),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.file(File(imagePath)))),
    );
  }

  Widget _inputField(TextEditingController controller, String label, {bool isLong = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: TextField(
        controller: controller, maxLines: isLong ? null : 1,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }

  void _saveAndGoBack() {
    if (_controllers['localName']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nazwa polska jest wymagana!")));
      return;
    }

    context.read<ObservationViewModel>().updateObservationDetailed(
      id: widget.observation.id,
      localName: _controllers['localName']!.text,
      latinName: _controllers['latinName']!.text,
      family: _controllers['family']!.text,
      biologicalType: widget.observation.tempBiologicalType,
      subspecies: _controllers['subspecies']!.text,
      certainty: _selectedCertainty,
      doubts: _controllers['idDoubts']!.text,
      keyTraits: _controllers['keyTraits']!.text,
      confusing: _controllers['confusing']!.text,
      characteristic: _controllers['characteristic']!.text,
      usage: _controllers['usage']!.text,
      cultivation: _controllers['cultivation']!.text,
      prefPhMin: _prefPhMin,
      prefPhMax: _prefPhMax,
      prefSubstrate: const [],
      prefMoisture: 1.0,
      prefSunlight: 2.0,
      prefAreaTypes: _prefAreaTypes,
      prefExposures: _prefExposures,
      prefCanopyCovers: _prefCanopyCovers,
      prefWaterDynamics: _prefWaterDynamics,
      prefSoilDepths: _prefSoilDepths,
    );
    Navigator.pop(context);
  }
}