import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';

class DetailDescriptionScreen extends StatefulWidget {
  final PlantObservation observation;
  const DetailDescriptionScreen({super.key, required this.observation});

  @override
  State<DetailDescriptionScreen> createState() => _DetailDescriptionScreenState();
}

class _DetailDescriptionScreenState extends State<DetailDescriptionScreen> {
  // Kontrolery dla pól tekstowych
  final Map<String, TextEditingController> _controllers = {};

  String? _selectedAbundance;
  String? _selectedCertainty;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final obs = widget.observation;
    // Inicjalizacja kontrolerów danymi z modelu
    _controllers['family'] = TextEditingController(text: obs.family);
    _controllers['genus'] = TextEditingController(text: obs.genus);
    _controllers['species'] = TextEditingController(text: obs.species);
    _controllers['subspecies'] = TextEditingController(text: obs.subspecies);
    _controllers['latinName'] = TextEditingController(text: obs.latinName);
    _controllers['polishName'] = TextEditingController(text: obs.polishName);
    _controllers['localName'] = TextEditingController(text: obs.localName);
    _controllers['idDoubts'] = TextEditingController(text: obs.idDoubts);
    _controllers['keyTraits'] = TextEditingController(text: obs.keyMorphologicalTraits);
    _controllers['microTraits'] = TextEditingController(text: obs.microscopicTraits);
    _controllers['diffs'] = TextEditingController(text: obs.differences);
    _controllers['confusing'] = TextEditingController(text: obs.confusingSpecies);
    _controllers['usage'] = TextEditingController(text: obs.plantUsage);

    _selectedAbundance = obs.abundance;
    _selectedCertainty = obs.certainty;
    _selectedDate = obs.observationDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Szczegółowa Identifikacja")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildCoreInfoSection(),
          const Divider(),
          _buildTaxonomySection(),
          _buildNamingSection(),
          _buildCertaintySection(),
          _buildDiagnosticSection(),
          _buildUsageSection(),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
            onPressed: _saveAndGoBack,
            child: const Text("ZAPISZ I WRÓĆ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- SEKCJE FORMULARZA ---

  Widget _buildCoreInfoSection() {
    return Column(children: [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(labelText: "Ilościowość (Braun-Blanquet)"),
        value: _selectedAbundance,
        items: ['5', '4', '3', '2', '1', 'r', '+'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _selectedAbundance = v),
      ),
      ListTile(
        title: Text(_selectedDate == null ? "Data obserwacji" : "Data: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}"),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (p != null) setState(() => _selectedDate = p);
        },
      ),
    ]);
  }

  Widget _buildTaxonomySection() {
    return ExpansionTile(
      title: const Text("A. Pozycja systematyczna"),
      children: [
        _inputField(_controllers['family']!, "Rodzina (Familia)"),
        _inputField(_controllers['genus']!, "Rodzaj (Genus)"),
        _inputField(_controllers['species']!, "Gatunek (Species)"),
        _inputField(_controllers['subspecies']!, "Podgatunek / odmiana"),
      ],
    );
  }

  Widget _buildNamingSection() {
    return ExpansionTile(
      title: const Text("B. Nazewnictwo"),
      children: [
        _inputField(_controllers['latinName']!, "Nazwa łacińska"),
        _inputField(_controllers['polishName']!, "Nazwa polska"),
        _inputField(_controllers['localName']!, "Nazwa zwyczajowa / lokalna", hint: "Ta nazwa będzie głównym identyfikatorem"),
      ],
    );
  }

  Widget _buildCertaintySection() {
    return ExpansionTile(
      title: const Text("C. Stopień pewności"),
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCertainty,
          items: ['wysoki', 'średni', 'niski'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedCertainty = v),
          decoration: const InputDecoration(labelText: "Stopień pewności"),
        ),
        _inputField(_controllers['idDoubts']!, "Ewentualne wątpliwości", isLong: true),
      ],
    );
  }

  Widget _buildDiagnosticSection() {
    return ExpansionTile(
      title: const Text("D. Cechy diagnostyczne"),
      children: [
        _inputField(_controllers['keyTraits']!, "Cechy morfologiczne kluczowe", isLong: true),
        _inputField(_controllers['microTraits']!, "Cechy mikroskopowe", isLong: true),
        _inputField(_controllers['diffs']!, "Różnice względem gatunków podobnych", isLong: true),
        _inputField(_controllers['confusing']!, "Gatunki mylone z...", isLong: true),
      ],
    );
  }

  Widget _buildUsageSection() {
    return ExpansionTile(
      title: const Text("E. Wykorzystanie rośliny"),
      children: [
        _inputField(_controllers['usage']!, "Opisz zastosowanie", isLong: true),
      ],
    );
  }

  // --- POMOCNICZE ---

  Widget _inputField(TextEditingController controller, String label, {bool isLong = false, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
      child: TextField(
        controller: controller,
        maxLines: isLong ? 3 : 1,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }

  void _saveAndGoBack() {
    final vm = context.read<PlantsViewModel>();
    final obs = widget.observation;

    // Przekazujemy wszystkie nowe dane do ViewModelu (musimy tam zaktualizować metodę update)
    vm.updateObservationDetailed(
      id: obs.id,
      abundance: _selectedAbundance,
      date: _selectedDate,
      family: _controllers['family']!.text,
      genus: _controllers['genus']!.text,
      species: _controllers['species']!.text,
      subspecies: _controllers['subspecies']!.text,
      latinName: _controllers['latinName']!.text,
      polishName: _controllers['polishName']!.text,
      localName: _controllers['localName']!.text,
      certainty: _selectedCertainty,
      doubts: _controllers['idDoubts']!.text,
      keyTraits: _controllers['keyTraits']!.text,
      microTraits: _controllers['microTraits']!.text,
      diffs: _controllers['diffs']!.text,
      confusing: _controllers['confusing']!.text,
      usage: _controllers['usage']!.text,
    );

    Navigator.pop(context);
  }
}