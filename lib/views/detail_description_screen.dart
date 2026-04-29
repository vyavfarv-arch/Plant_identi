// lib/views/detail_description_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import '../widgets/ecological_amplitude_picker.dart';
import 'dart:io';
import '../models/harvest_season.dart';
import '../widgets/harvest_season_picker.dart';
import '../viewmodels/reminder_view_model.dart';

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

  // Magia DRY - Jeden elegancki kontroler zamiast 7 list i 30 funkcji!
  final EcologicalDataController _ecoController = EcologicalDataController();

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

  void _applySpeciesData(PlantSpecies s) {
    setState(() {
      _controllers['family']!.text = s.family;
      _controllers['localName']!.text = s.polishName;
      _controllers['usage']!.text = s.plantUsage ?? "";
      _controllers['cultivation']!.text = s.cultivation ?? "";
      _selectedSeasons = List.from(s.harvestSeasons); // Wczytanie z bazy
    });

    // Autouzupełnianie logiki ML jednym poleceniem
    _ecoController.updateData(
      newPhMin: s.prefPhMin, newPhMax: s.prefPhMax, newAreaTypes: s.prefAreaTypes,
      newExposures: s.prefExposures, newCanopyCovers: s.prefCanopyCovers,
      newWaterDynamics: s.prefWaterDynamics, newSoilDepths: s.prefSoilDepths,
    );
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

          // NASZ NOWY WIDGET W AKCJI:
          ExpansionTile(
            title: const Text("Amplituda ekologiczna (ML)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            children: [ Padding(padding: const EdgeInsets.all(12), child: EcologicalAmplitudePicker(controller: _ecoController)) ],
          ),
          ExpansionTile(
            title: const Text("Surowce i Zbiory", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: HarvestSeasonPicker(
                  initialSeasons: _selectedSeasons,
                  onChanged: (seasons) => setState(() => _selectedSeasons = List.from(seasons)),
                ),
              )
            ],
          ),
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
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Autocomplete<String>(
            optionsBuilder: (val) => val.text.isEmpty ? const Iterable<String>.empty() : obsVm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())),
            onSelected: (selection) {
              _controllers['latinName']!.text = selection;
              final found = obsVm.findSpeciesByLatinName(selection);
              if (found != null) _applySpeciesData(found);
            },
            fieldViewBuilder: (ctx, ctrl, node, onSub) {
              if (_controllers['latinName']!.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _controllers['latinName']!.text;
              return TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Nazwa Łacińska", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => _controllers['latinName']!.text = v);
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
            value: _selectedCertainty, items: ['Wysoka', 'Średnia', 'Niska'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedCertainty = v), decoration: const InputDecoration(labelText: "Pewność identyfikacji", border: OutlineInputBorder()),
          ),
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

  Widget _buildCapturedPhotosPreview() {
    final photos = widget.observation.photoPaths;
    if (photos.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 120, margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: photos.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.file(File(photos[index]))))),
          child: Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(photos[index]), width: 100, height: 100, fit: BoxFit.cover))),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, {bool isLong = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10), child: TextField(controller: controller, maxLines: isLong ? null : 1, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  }

  void _saveAndGoBack() {
    if (_controllers['localName']!.text.isEmpty) return;

    final obsVm = context.read<ObservationViewModel>();
    final remVm = context.read<ReminderViewModel>();

    // NAPRAWA BŁĘDU: Używamy startDate zamiast months
    for (var season in _selectedSeasons) {
      if (season.reminderEnabled && season.startDate != null) {
        remVm.addHarvestReminder(
            plantName: _controllers['localName']!.text,
            material: season.material,
            startDate: season.startDate!,
            endDate: season.endDate ?? season.startDate!.add(const Duration(days: 30)),
            relatedId: widget.observation.id
        );
      }
    }

    obsVm.updateObservationDetailed(
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
      harvestSeasons: _selectedSeasons, // Wysyłamy nową strukturę Od-Do
      prefPhMin: _ecoController.phMin,
      prefPhMax: _ecoController.phMax,
      prefAreaTypes: _ecoController.areaTypes,
      prefExposures: _ecoController.exposures,
      prefCanopyCovers: _ecoController.canopyCovers,
      prefWaterDynamics: _ecoController.waterDynamics,
      prefSoilDepths: _ecoController.soilDepths,
    );
    Navigator.pop(context);
  }
}