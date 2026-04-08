// lib/views/detail_description_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';
import '../models/description_schema.dart';

class DetailDescriptionScreen extends StatefulWidget {
  final PlantObservation observation;
  const DetailDescriptionScreen({super.key, required this.observation});

  @override
  State<DetailDescriptionScreen> createState() => _DetailDescriptionScreenState();
}

class _DetailDescriptionScreenState extends State<DetailDescriptionScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedCertainty;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();

    _initData();
  }

  void _initData() {
    final obs = widget.observation;
    _controllers['family'] = TextEditingController(text: obs.family);
    _controllers['genus'] = TextEditingController(text: obs.genus);
    _controllers['species'] = TextEditingController(text: obs.species);
    _controllers['subspecies'] = TextEditingController(text: obs.subspecies);
    _controllers['localName'] = TextEditingController(text: obs.localName);
    _controllers['idDoubts'] = TextEditingController(text: obs.idDoubts);
    _controllers['keyTraits'] = TextEditingController(text: obs.keyMorphologicalTraits);
    _controllers['confusing'] = TextEditingController(text: obs.confusingSpecies);
    _controllers['characteristic'] = TextEditingController(text: obs.characteristicFeature);
    _controllers['usage'] = TextEditingController(text: obs.plantUsage);
    _controllers['cultivation'] = TextEditingController(text: obs.cultivation);

    _selectedStatus = obs.phytosociologicalStatus;
    _selectedCertainty = obs.certainty;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Szczegółowa Identifikacja")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildFieldObservationSummary(), // Podgląd cech z terenu
          const Divider(height: 40, thickness: 2),
          _buildNamingSection(), // 1. Nazewnictwo
          _buildCertaintySection(), // 2. Pewność
          _buildUsageSection(), // 3. Wykorzystanie
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15)
            ),
            onPressed: _saveAndGoBack,
            child: const Text("ZAPISZ I WRÓĆ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- PODGLĄD CECH TERENOWYCH ---
  Widget _buildFieldObservationSummary() {
    final obs = widget.observation;
    if (obs.characteristics.isEmpty) return const SizedBox.shrink();

    // Mapujemy surowe cechy na nagłówki ze schematu
    final schema = SchemaGenerator.getForType(obs.biologicalType ?? "Zielona");

    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text("Cechy zaobserwowane w terenie", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
      children: schema.map((category) {
        // Sprawdzamy czy w tej kategorii są jakieś wybrane cechy
        final entries = category.subCategories.keys
            .where((subKey) => obs.characteristics.containsKey(subKey))
            .map((subKey) => "${subKey}: ${obs.characteristics[subKey]}")
            .toList();

        if (entries.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${category.number}. ${category.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text("- $e", style: const TextStyle(fontSize: 14)),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- NOWE SEKCJE FORMULARZA ---

  Widget _buildNamingSection() {
    return ExpansionTile(
      title: const Text("Nazewnictwo (wymagane)"),
      children: [
        _inputField(_controllers['localName']!, "Nazwa (Główna)", hint: "Np. Babka lancetowata"),
        _inputField(_controllers['family']!, "Rodzina (Familia)"),
        _inputField(_controllers['genus']!, "Rodzaj (Genus)"),
        _inputField(_controllers['species']!, "Gatunek (Species)"),
        _inputField(_controllers['subspecies']!, "Odmiana (opcjonalnie)"),
      ],
    );
  }

  Widget _buildCertaintySection() {
    return ExpansionTile(
      title: const Text("Pewność"),
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text("Status fitosocjologiczny:", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Column(
          children: ["Charakterystyczny", "Wyróżniający", "Popularny"].map((status) =>
              RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: _selectedStatus,
                onChanged: (v) => setState(() => _selectedStatus = v),
              )
          ).toList(),
        ),
        const Divider(),
        DropdownButtonFormField<String>(
          value: _selectedCertainty,
          items: ['wysoki', 'średni', 'niski'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedCertainty = v),
          decoration: const InputDecoration(labelText: "Stopień pewności"),
        ),
        _inputField(_controllers['idDoubts']!, "Wątpliwość", isLong: true),
        _inputField(_controllers['keyTraits']!, "Cechy morfologiczne", isLong: true),
        _inputField(_controllers['confusing']!, "Gatunki mylone z..."),
        _inputField(_controllers['characteristic']!, "Cecha charakterystyczna"),
      ],
    );
  }

  Widget _buildUsageSection() {
    return ExpansionTile(
      title: const Text("Wykorzystanie"),
      children: [
        _inputField(_controllers['usage']!, "Zastosowanie", isLong: true),
        _inputField(_controllers['cultivation']!, "Hodowla", isLong: true),
      ],
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
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  void _saveAndGoBack() {
    if (_controllers['localName']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pole 'Nazwa' w sekcji Nazewnictwo jest wymagane!")),
      );
      return;
    }

    final vm = context.read<PlantsViewModel>();
    vm.updateObservationDetailed(
      id: widget.observation.id,
      family: _controllers['family']!.text,
      genus: _controllers['genus']!.text,
      species: _controllers['species']!.text,
      subspecies: _controllers['subspecies']!.text,
      localName: _controllers['localName']!.text,
      certainty: _selectedCertainty,
      doubts: _controllers['idDoubts']!.text,
      keyTraits: _controllers['keyTraits']!.text,
      confusing: _controllers['confusing']!.text,
      characteristic: _controllers['characteristic']!.text,
      usage: _controllers['usage']!.text,
      cultivation: _controllers['cultivation']!.text,
    );

    Navigator.pop(context);
  }
}