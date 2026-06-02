// lib/views/detail_description_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../models/harvest_season.dart';
import '../viewmodels/observation_view_model.dart';
import '../widgets/ecological_amplitude_picker.dart';
import '../widgets/harvest_season_picker.dart';
import '../widgets/specimen_reference_card.dart';

class DetailDescriptionScreen extends StatefulWidget {
  final PlantObservation observation;
  const DetailDescriptionScreen({super.key, required this.observation});

  @override
  State<DetailDescriptionScreen> createState() => _DetailDescriptionScreenState();
}

class _DetailDescriptionScreenState extends State<DetailDescriptionScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String? _selectedCertainty;
  List<HarvestSeason> _selectedSeasons = [];
  final EcologicalDataController _ecoController = EcologicalDataController();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final species = context.read<ObservationViewModel>().getSpeciesById(widget.observation.speciesId);
    final fields = ['family', 'subspecies', 'localName', 'latinName', 'idDoubts', 'keyTraits', 'confusing', 'characteristic', 'usage', 'cultivation'];

    for (var f in fields) {
      String initialValue = "";
      if (f == 'subspecies') initialValue = widget.observation.subspecies ?? "";
      else if (f == 'localName') initialValue = widget.observation.localName ?? "";
      else if (f == 'latinName') initialValue = species?.latinName ?? "";
      else if (f == 'family') initialValue = species?.family ?? "";
      _controllers[f] = TextEditingController(text: initialValue);
    }
    _selectedCertainty = widget.observation.certainty;
    if (species != null) _applySpeciesData(species);
  }

  void _applySpeciesData(PlantSpecies s) {
    setState(() {
      _controllers['family']!.text = s.family;
      _controllers['localName']!.text = s.polishName;
      _controllers['usage']!.text = s.plantUsage ?? "";
      _controllers['cultivation']!.text = s.cultivation ?? "";
      _selectedSeasons = List.from(s.harvestSeasons);
    });
    _ecoController.updateFromSpeciesData(
      newPhMin: s.prefPhMin, newPhMax: s.prefPhMax,
      lL: s.ellenbergL, fMap: s.ellenbergF, lR: s.ellenbergR,
      lN: s.ellenbergN, lT: s.ellenbergT, lK: s.ellenbergK, lS: s.ellenbergS,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edycja Wiedzy o Gatunku"), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            SpecimenReferenceCard(observation: widget.observation),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _section("TAKSONOMIA", Icons.account_tree, _buildNamingSection()),
                  _section("ZBIORY", Icons.shopping_basket, HarvestSeasonPicker(initialSeasons: _selectedSeasons, onChanged: (s) => _selectedSeasons = s)),
                  _section("EKOLOGIA", Icons.landscape, EcologicalAmplitudePicker(controller: _ecoController)),
                  _section("WYKORZYSTANIE", Icons.menu_book, _buildUsageFields()),
                  const SizedBox(height: 30),
                  _buildSaveButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(children: [Icon(icon, color: Colors.teal, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))]),
      ),
      child,
    ],
  );

  Widget _buildNamingSection() {
    final obsVm = context.watch<ObservationViewModel>();
    return Column(children: [
      Autocomplete<String>(
        optionsBuilder: (val) => val.text.isEmpty ? const Iterable.empty() : obsVm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())),
        onSelected: (selection) {
          _controllers['latinName']!.text = selection;
          final found = obsVm.findSpeciesByLatinName(selection);
          if (found != null) _applySpeciesData(found);
        },
        fieldViewBuilder: (ctx, ctrl, node, onSub) {
          if (_controllers['latinName']!.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _controllers['latinName']!.text;
          return _input(ctrl, "Nazwa Łacińska", icon: Icons.search, focus: node, onChanged: (v) => _controllers['latinName']!.text = v);
        },
      ),
      _input(_controllers['localName']!, "Nazwa polska"),
      _input(_controllers['family']!, "Rodzina"),
      _input(_controllers['subspecies']!, "Podgatunek"),
    ]);
  }

  Widget _buildUsageFields() => Column(children: [
    _input(_controllers['usage']!, "Zastosowanie", isLong: true),
    _input(_controllers['cultivation']!, "Uprawa", isLong: true),
  ]);

  Widget _input(TextEditingController ctrl, String label, {bool isLong = false, IconData? icon, FocusNode? focus, Function(String)? onChanged}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl, focusNode: focus, onChanged: onChanged, maxLines: isLong ? null : 1,
      decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon) : null, border: const OutlineInputBorder()),
    ),
  );

  Widget _buildSaveButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      icon: const Icon(Icons.save), label: const Text("ZAPISZ ZMIANY"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
      onPressed: _handleSave,
    ),
  );

  void _handleSave() async {
    if (_controllers['localName']!.text.isEmpty || _controllers['latinName']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Podaj obie nazwy!"), backgroundColor: Colors.redAccent));
      return;
    }
    await context.read<ObservationViewModel>().updateObservationDetailed(
      id: widget.observation.id, localName: _controllers['localName']!.text, latinName: _controllers['latinName']!.text,
      family: _controllers['family']!.text, biologicalType: widget.observation.tempBiologicalType,
      subspecies: _controllers['subspecies']!.text, certainty: _selectedCertainty, doubts: _controllers['idDoubts']!.text,
      keyTraits: _controllers['keyTraits']!.text, confusing: _controllers['confusing']!.text, characteristic: _controllers['characteristic']!.text,
      usage: _controllers['usage']!.text, cultivation: _controllers['cultivation']!.text, harvestSeasons: _selectedSeasons,
      prefPhMin: _ecoController.phMin, prefPhMax: _ecoController.phMax,
      ellenbergL: _ecoController.ellenbergL, ellenbergF: _ecoController.ellenbergF,
      ellenbergR: _ecoController.ellenbergR, ellenbergN: _ecoController.ellenbergN,
      ellenbergT: _ecoController.ellenbergT, ellenbergK: _ecoController.ellenbergK,
      ellenbergS: _ecoController.ellenbergS,
    );
    if (mounted) Navigator.pop(context);
  }
}