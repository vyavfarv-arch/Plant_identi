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

  // Dane preferencji środowiskowych
  double _prefPhMin = 5.5;
  double _prefPhMax = 7.5;
  String? _prefSubstrate;
  double _prefMoisture = 1.0;
  double _prefSunlight = 2.0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final obs = widget.observation;
    _controllers['family'] = TextEditingController(text: obs.family);
    _controllers['subspecies'] = TextEditingController(text: obs.subspecies);
    _controllers['localName'] = TextEditingController(text: obs.localName);
    _controllers['latinName'] = TextEditingController(text: obs.latinName);
    _controllers['idDoubts'] = TextEditingController(text: obs.idDoubts);
    _controllers['keyTraits'] = TextEditingController(text: obs.keyMorphologicalTraits);
    _controllers['confusing'] = TextEditingController(text: obs.confusingSpecies);
    _controllers['characteristic'] = TextEditingController(text: obs.characteristicFeature);
    _controllers['usage'] = TextEditingController(text: obs.plantUsage);
    _controllers['cultivation'] = TextEditingController(text: obs.cultivation);

    _selectedCertainty = obs.certainty;
    _prefPhMin = obs.prefPhMin ?? 5.5;
    _prefPhMax = obs.prefPhMax ?? 7.5;
    _prefSubstrate = obs.prefSubstrate;
    _prefMoisture = obs.prefMoisture ?? 1.0;
    _prefSunlight = obs.prefSunlight ?? 2.0;
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
          _buildCertaintySection(),
          _buildUsageSection(),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15)
            ),
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
      title: const Text("Taksonomia", style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        _inputField(_controllers['localName']!, "Nazwa Główna (np. Mniszek)"),
        _inputField(_controllers['latinName']!, "Nazwa Łacińska"),
        _inputField(_controllers['family']!, "Rodzina"),
        _inputField(_controllers['subspecies']!, "Odmiana/Podgatunek"),
      ],
    );
  }

  Widget _buildEnvironmentalSection() {
    return ExpansionTile(
      title: const Text("Preferencje środowiskowe", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text("Przedział pH gleby: ${_prefPhMin.toStringAsFixed(1)} - ${_prefPhMax.toStringAsFixed(1)}"),
              RangeSlider(
                values: RangeValues(_prefPhMin, _prefPhMax),
                min: 3.0, max: 9.0,
                divisions: 60,
                labels: RangeLabels(_prefPhMin.toStringAsFixed(1), _prefPhMax.toStringAsFixed(1)),
                onChanged: (v) => setState(() { _prefPhMin = v.start; _prefPhMax = v.end; }),
              ),
              DropdownButtonFormField<String>(
                value: _prefSubstrate,
                decoration: const InputDecoration(labelText: "Preferowane podłoże"),
                items: ["Piasek", "Glina", "Torf", "Kamienie"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _prefSubstrate = v),
              ),
              _buildSlider("Wilgotność:", _prefMoisture, 3, ["Sucho", "Świeżo", "Wilgotno", "Mokro"], (v) => setState(() => _prefMoisture = v)),
              _buildSlider("Nasłonecznienie:", _prefSunlight, 4, ["Pełne słońce", "Przewaga słońca", "Półcień", "Przewaga cienia", "Cień"], (v) => setState(() => _prefSunlight = v)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildCertaintySection() {
    return ExpansionTile(
      title: const Text("Pewność identyfikacji"),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCertainty,
          items: ['Wysoka', 'Średnia', 'Niska'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedCertainty = v),
          decoration: const InputDecoration(labelText: "Stopień pewności"),
        ),
        _inputField(_controllers['idDoubts']!, "Wątpliwości/Uwagi", isLong: true),
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
        Text(title),
        Slider(value: value, min: 0, max: divisions.toDouble(), divisions: divisions, label: labels[value.round()], onChanged: onChanged),
      ],
    );
  }

  Widget _buildCapturedPhotosPreview() {
    final photos = widget.observation.photoPaths;
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final path = photos[index];
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, path),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 100, height: 100, fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(child: Image.file(File(imagePath))),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, {bool isLong = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: TextField(
        controller: controller,
        maxLines: isLong ? null : 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _saveAndGoBack() {
    if (_controllers['localName']!.text.isEmpty) return;
    context.read<ObservationViewModel>().updateObservationDetailed(
      id: widget.observation.id,
      family: _controllers['family']!.text,
      subspecies: _controllers['subspecies']!.text,
      localName: _controllers['localName']!.text,
      latinName: _controllers['latinName']!.text,
      certainty: _selectedCertainty,
      doubts: _controllers['idDoubts']!.text,
      keyTraits: _controllers['keyTraits']!.text,
      confusing: _controllers['confusing']!.text,
      characteristic: _controllers['characteristic']!.text,
      usage: _controllers['usage']!.text,
      cultivation: _controllers['cultivation']!.text,
      prefPhMin: _prefPhMin,
      prefPhMax: _prefPhMax,
      prefSubstrate: _prefSubstrate,
      prefMoisture: _prefMoisture,
      prefSunlight: _prefSunlight,
    );
    Navigator.pop(context);
  }
}