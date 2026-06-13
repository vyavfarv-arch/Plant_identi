// lib/views/detail_description_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // DODANO TEN IMPORT - naprawia błąd "The name 'Uuid' isn't a class"
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../models/harvest_season.dart';
import '../viewmodels/observation_view_model.dart';
import '../widgets/ecological_amplitude_picker.dart';
import '../widgets/harvest_season_picker.dart';
import '../widgets/specimen_reference_card.dart';
import 'form_screen.dart'; // Import ekranu modyfikacji cech

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Kompletny edytor wiedzy o gatunku i taksonomii okazu. Pozwala na powiązanie
 * okazu z nazwą łacińską za pomocą Autocomplete (podpowiedzi z bazy), edycję rodziny,
 * wywołanie formularza modyfikacji cech organów, konfigurację kalendarza zbioru
 * oraz sterowanie suwakami i siatką amplitudy ekologicznej Ellenberga.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z katalogu '../models/':
 * - Klasy [PlantObservation], [PlantSpecies], [HarvestSeason]: Odczyt i pakowanie do zapisu SQL.
 * * Z katalogu '../viewmodels/':
 * - Klasa [ObservationViewModel]: Służy do asynchronicznego wstrzyknięcia i zapisu encji gatunku oraz okazu.
 * * Z katalogów widoków i widżetów współdzielonych:
 * - Widżety: [EcologicalAmplitudePicker], [HarvestSeasonPicker], [SpecimenReferenceCard].
 * - Widoki: Ekran modyfikacji cech organowych [FormScreen].
 * ============================================================================
 */
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

  // FIX: Pełne, jawne zadeklarowanie wszystkich kontrolerów tekstu eliminuje ucinanie i blokowanie pól bazy
  void _initControllers() {
    final species = context.read<ObservationViewModel>().getSpeciesById(widget.observation.speciesId);

    _controllers['family'] = TextEditingController(text: species?.family ?? "");
    _controllers['subspecies'] = TextEditingController(text: widget.observation.subspecies ?? "");
    _controllers['localName'] = TextEditingController(text: widget.observation.localName ?? (species?.polishName ?? ""));
    _controllers['latinName'] = TextEditingController(text: species?.latinName ?? "");
    _controllers['idDoubts'] = TextEditingController(text: widget.observation.idDoubts ?? "");
    _controllers['keyTraits'] = TextEditingController(text: widget.observation.keyMorphologicalTraits ?? "");
    _controllers['confusing'] = TextEditingController(text: widget.observation.confusingSpecies ?? "");
    _controllers['characteristic'] = TextEditingController(text: widget.observation.characteristicFeature ?? "");
    _controllers['usage'] = TextEditingController(text: species?.plantUsage ?? "");
    _controllers['cultivation'] = TextEditingController(text: species?.cultivation ?? "");

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
      lL: s.ellenbergL, lF: s.ellenbergF, lR: s.ellenbergR, lN: s.ellenbergN, lT: s.ellenbergT, lK: s.ellenbergK, lS: s.ellenbergS,
    );
  }

  @override
  void dispose() {
    // FIX CODE REVIEW: Likwidacja wycieków pamięci RAM
    for (var controller in _controllers.values) { controller.dispose(); }
    super.dispose();
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

                  // NOWOŚĆ: Bezpośrednia możliwość uzupełnienia/edycji cech morfologicznych okazu z bazy danych
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: const BorderSide(color: Colors.teal, width: 1.5)),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text("MODYFIKUJ CECHY MORFOLOGICZNE OKAZU"),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormScreen(observation: widget.observation))),
                    ),
                  ),

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
      _input(_controllers['family']!, "Rodzina (np. Jaskrowate)"),
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

    final obsVm = context.read<ObservationViewModel>();
    final String enteredLatinName = _controllers['latinName']!.text.trim();
    final String enteredPolishName = _controllers['localName']!.text.trim();

    // 1. Sprawdzamy, czy gatunek o takiej nazwie już istnieje w lokalnym atlasie użytkownika (zapobiega dublowaniu)
    final existingSpecies = obsVm.findSpeciesByLatinName(enteredLatinName) ??
        obsVm.findSpeciesByPolishName(enteredPolishName);

    // 2. Ustalamy inteligentne ID dla gatunku (likwidacja krytycznego błędu pustego ID "")
    String targetSpeciesId = widget.observation.speciesId ?? "";

    if (targetSpeciesId.isEmpty) {
      if (existingSpecies != null) {
        // Jeśli użytkownik wpisał nazwę istniejącego gatunku, używamy jego oryginalnego ID
        targetSpeciesId = existingSpecies.speciesID;
      } else {
        // Jeśli to całkowicie nowy unikalny gatunek, tworzymy dla niego świeże UUID
        targetSpeciesId = const Uuid().v4();
      }
    }

    // 3. Budujemy poprawny obiekt wzorca gatunku (Atlasu)
    final species = PlantSpecies(
      speciesID: targetSpeciesId,
      latinName: enteredLatinName,
      polishName: enteredPolishName,
      family: _controllers['family']!.text.trim(),
      biologicalType: widget.observation.tempBiologicalType ?? "Zielne",
      plantUsage: _controllers['usage']!.text.trim(),
      cultivation: _controllers['cultivation']!.text.trim(),
      ellenbergL: Map.from(_ecoController.ellenbergL),
      ellenbergF: Map.from(_ecoController.ellenbergF),
      ellenbergR: Map.from(_ecoController.ellenbergR),
      ellenbergN: Map.from(_ecoController.ellenbergN),
      ellenbergT: Map.from(_ecoController.ellenbergT),
      ellenbergK: Map.from(_ecoController.ellenbergK),
      ellenbergS: Map.from(_ecoController.ellenbergS),
      harvestSeasons: _selectedSeasons,
    );

    // Zapisujemy/aktualizujemy gatunek w słowniku użytkownika
    await obsVm.addSpecies(species);

    // 4. Aktualizujemy rekord obserwacji terenowej, trwale wiążąc go z prawidłowym ID gatunku
    final updatedObs = PlantObservation(
      id: widget.observation.id,
      releveId: widget.observation.releveId,
      speciesId: species.speciesID, // Przypisanie bezpiecznego, niepustego identyfikatora
      localName: species.polishName,
      subspecies: _controllers['subspecies']!.text.trim(),
      tempBiologicalType: widget.observation.tempBiologicalType,
      photoPaths: widget.observation.photoPaths,
      characteristics: widget.observation.characteristics,
      latitude: widget.observation.latitude,
      longitude: widget.observation.longitude,
      timestamp: widget.observation.timestamp,
      observationDate: widget.observation.observationDate ?? DateTime.now(),
      phenologicalStage: widget.observation.phenologicalStage,
      abundance: widget.observation.abundance,
      coverage: widget.observation.coverage,
      vitality: widget.observation.vitality,
      certainty: _selectedCertainty,
      idDoubts: _controllers['idDoubts']!.text.trim(),
      keyMorphologicalTraits: _controllers['keyTraits']!.text.trim(),
      confusingSpecies: _controllers['confusing']!.text.trim(),
      characteristicFeature: _controllers['characteristic']!.text.trim(),
      customHarvestSeasons: widget.observation.customHarvestSeasons,
    );

    // Zapisujemy zaktualizowaną obserwację w bazie danych
    await obsVm.addObservation(updatedObs);

    if (mounted) Navigator.pop(context);
  }
}