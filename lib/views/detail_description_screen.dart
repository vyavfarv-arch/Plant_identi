// lib/views/detail_description_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
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

  double _prefPhMin = 5.5;
  double _prefPhMax = 7.5;
  final List<String> _prefSubstrateList = [];
  double _prefMoisture = 1.0;
  double _prefSunlight = 2.0;

  final List<String> _substrateOptions = [
    "Gliniasta", "Piaskowa", "Żwirowa", "Torfowa",
    "Kamienista", "Próchnicza", "Wapienna", "Krzemianowa"
  ];

  @override
  void initState() {
    super.initState();
    final obs = widget.observation;
    // Pobranie powiązanego gatunku ze słownika!
    final species = context.read<ObservationViewModel>().getSpeciesById(obs.speciesId);

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
    _prefPhMin = species?.prefPhMin ?? 5.5;
    _prefPhMax = species?.prefPhMax ?? 7.5;
    _prefSubstrateList.clear();
    if (species != null) _prefSubstrateList.addAll(species.prefSubstrate);
    _prefMoisture = species?.prefMoisture ?? 1.0;
    _prefSunlight = species?.prefSunlight ?? 2.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Szczegóły Gatunku")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildCapturedPhotosPreview(),
          _buildNamingSection(),
          _buildEnvironmentalSection(),
          _buildUsageSection(),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _saveAndGoBack,
            child: const Text("ZAPISZ DO MAGAZYNU", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildNamingSection() {
    return ExpansionTile(
      title: const Text("Taksonomia i Pewność", style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        _inputField(_controllers['localName']!, "Nazwa zwyczajowa (np. Mniszek)"),
        _inputField(_controllers['latinName']!, "Nazwa Łacińska"),
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

  Widget _buildEnvironmentalSection() {
    return ExpansionTile(
      title: const Text("Preferencje środowiskowe ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Przedział pH gleby: ${_prefPhMin.toStringAsFixed(1)} - ${_prefPhMax.toStringAsFixed(1)}"),
              RangeSlider(values: RangeValues(_prefPhMin, _prefPhMax), min: 3.0, max: 9.0, divisions: 60, labels: RangeLabels(_prefPhMin.toStringAsFixed(1), _prefPhMax.toStringAsFixed(1)), onChanged: (v) => setState(() { _prefPhMin = v.start; _prefPhMax = v.end; })),
              const SizedBox(height: 15),
              const Text("Preferowane typy gleby:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: _substrateOptions.map((substrate) {
                  final isSelected = _prefSubstrateList.contains(substrate);
                  return FilterChip(
                    label: Text(substrate, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected, selectedColor: Colors.teal, checkmarkColor: Colors.white,
                    onSelected: (bool selected) => setState(() { selected ? _prefSubstrateList.add(substrate) : _prefSubstrateList.remove(substrate); }),
                  );
                }).toList(),
              ),
              _buildSlider("Wilgotność:", _prefMoisture, 3, ["Sucho", "Świeżo", "Wilgotno", "Mokro"], (v) => setState(() => _prefMoisture = v)),
              _buildSlider("Nasłonecznienie:", _prefSunlight, 4, ["Pełne słońce", "Przewaga słońca", "Półcień", "Przewaga cienia", "Cień"], (v) => setState(() => _prefSunlight = v)),
            ],
          ),
        )
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

  Widget _buildSlider(String title, double value, int divisions, List<String> labels, Function(double) onChanged) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(value: value, min: 0, max: divisions.toDouble(), divisions: divisions, label: labels[value.round()], onChanged: onChanged),
        Text(labels[value.round()], style: const TextStyle(color: Colors.blue)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nazwa główna jest wymagana!")));
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
      prefSubstrate: _prefSubstrateList,
      prefMoisture: _prefMoisture,
      prefSunlight: _prefSunlight,
    );
    Navigator.pop(context);
  }
}