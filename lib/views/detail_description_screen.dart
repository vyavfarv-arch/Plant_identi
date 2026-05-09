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
      _selectedSeasons = List.from(s.harvestSeasons);
    });

    _ecoController.updateData(
      newPhMin: s.prefPhMin,
      newPhMax: s.prefPhMax,
      newAreaTypes: s.prefAreaTypes,
      newWaterDynamics: s.prefWaterDynamics,
      newLightLevels: s.prefLightLevels,
      newSoilTypes: s.prefSoilTypes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edycja Wiedzy o Gatunku"),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEKCJA 1: KONTEKST OKAZU (Tylko do odczytu)
          _buildSpecimenReferenceHeader(),

          const Divider(height: 1),

          // SEKCJA 2: FORMULARZ GATUNKU (Przewijalny)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sectionHeader("TAKSONOMIA I IDENTYFIKACJA", Icons.account_tree),
                _buildNamingAndCertaintySection(),

                _sectionHeader("SUROWCE I ZBIORY", Icons.shopping_basket_outlined),
                _buildHarvestSection(),

                _sectionHeader("AMPLITUDA EKOLOGICZNA", Icons.landscape),
                _buildEnvironmentalSection(),

                _sectionHeader("WYKORZYSTANIE I HODOWLA", Icons.menu_book),
                _buildUsageSection(),

                const SizedBox(height: 30),
                _buildSaveButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETY SEKCJI ---

  Widget _buildSpecimenReferenceHeader() {
    final obs = widget.observation;
    return Container(
      color: Colors.blueGrey.shade50,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.remove_red_eye, color: Colors.blueGrey),
        title: Text("KONTEKST OKAZU: ${obs.localName ?? 'Brak nazwy'}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14)),
        subtitle: const Text("Dane zebrane w terenie", style: TextStyle(fontSize: 11)),
        children: [
          _buildCapturedPhotosPreview(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBadge("Witalność", obs.vitality, Colors.orange),
                    _infoBadge("Obfitość", obs.abundance, Colors.blue),
                    _infoBadge("Pokrycie", obs.coverage, Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Cechy morfologiczne okazu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: obs.characteristics.entries.expand((e) =>
                      e.value.map((v) => Chip(
                        label: Text("${e.key}: $v", style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                      ))
                  ).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamingAndCertaintySection() {
    final obsVm = context.watch<ObservationViewModel>();
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (val) => val.text.isEmpty ? const Iterable<String>.empty() : obsVm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())),
          onSelected: (selection) {
            _controllers['latinName']!.text = selection;
            final found = obsVm.findSpeciesByLatinName(selection);
            if (found != null) _applySpeciesData(found);
          },
          fieldViewBuilder: (ctx, ctrl, node, onSub) {
            if (_controllers['latinName']!.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _controllers['latinName']!.text;
            return _inputField(ctrl, "Nazwa Łacińska", icon: Icons.search, focus: node);
          },
        ),
        _inputField(_controllers['localName']!, "Nazwa polska"),
        _inputField(_controllers['family']!, "Rodzina"),
        _inputField(_controllers['subspecies']!, "Odmiana/Podgatunek"),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedCertainty,
          items: ['Wysoka', 'Średnia', 'Niska'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedCertainty = v),
          decoration: const InputDecoration(labelText: "Pewność identyfikacji (Twoja)", border: OutlineInputBorder()),
        ),
        _inputField(_controllers['idDoubts']!, "Wątpliwości co do tego okazu", isLong: true),
      ],
    );
  }

  Widget _buildHarvestSection() {
    return HarvestSeasonPicker(
      initialSeasons: _selectedSeasons,
      onChanged: (seasons) => _selectedSeasons = seasons,
    );
  }

  Widget _buildEnvironmentalSection() {
    return EcologicalAmplitudePicker(controller: _ecoController);
  }

  Widget _buildUsageSection() {
    return Column(
      children: [
        _inputField(_controllers['usage']!, "Ogólne zastosowanie gatunku", isLong: true),
        _inputField(_controllers['cultivation']!, "Wymagania hodowlane", isLong: true),
      ],
    );
  }

  // --- POMOCNICZE ---

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, String? value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        Text(value ?? "-", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _inputField(TextEditingController controller, String label, {bool isLong = false, IconData? icon, FocusNode? focus}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        focusNode: focus,
        maxLines: isLong ? null : 1,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCapturedPhotosPreview() {
    final photos = widget.observation.photoPaths;
    if (photos.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: photos.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(photos[index]), width: 80, height: 80, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text("ZAPISZ DO ATLASU GATUNKÓW"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _saveAndGoBack,
      ),
    );
  }

  void _saveAndGoBack() async {
    final polskaNazwa = _controllers['localName']!.text.trim();
    final lacinskaNazwa = _controllers['latinName']!.text.trim();
    if (polskaNazwa.isEmpty || lacinskaNazwa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Błąd: Musisz podać nazwę polską oraz łacińską przed zapisem."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    await _saveLogic();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveLogic() async {
    final obsVm = context.read<ObservationViewModel>();
    final remVm = context.read<ReminderViewModel>();

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

    await obsVm.updateObservationDetailed(
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
      harvestSeasons: _selectedSeasons,
      prefPhMin: _ecoController.phMin,
      prefPhMax: _ecoController.phMax,
      prefAreaTypes: _ecoController.areaTypes,
      prefWaterDynamics: _ecoController.waterDynamics,
      prefLightLevels: _ecoController.lightLevels,
      prefSoilTypes: _ecoController.soilTypes,
    );
  }
}