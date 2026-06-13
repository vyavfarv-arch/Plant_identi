// lib/views/add_observation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import './add_observation_long_step1.dart';
import './add_observation_morphology_step2.dart';
import './add_observation_quick_steps.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Kontroler PageView zarządzający wielokrokowym kreatorem dodawania okazu.
 * Koordynuje przepływ walidacji, zarządza stanami lokalnymi kroków i finalizuje
 * zapis rekordu botanicznego w lokalnej bazie danych poprzez ViewModel.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z katalogu '../models/':
 * - Klasy [PlantObservation], [PlantSpecies]: Służą jako struktury inicjalizacyjne.
 * * Z pliku '../viewmodels/observation_view_model.dart':
 * - Klasa [ObservationViewModel]: Służy do asynchronicznego zapisu gotowego okazu.
 * * Pod-kroki formularza (Widżety):
 * - [AddObservationQuickPhotoStep], [AddObservationQuickPopulationStep],
 * [AddObservationLongStep1], [AddObservationMorphologyStep2].
 * ============================================================================
 */

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

  String? _targetSpeciesId;
  bool _isQuickMode = false;
  String? _selectedType;

  String? _selectedPhenology;
  String? _selectedAbundance;
  String? _selectedVitality;

  final Map<String, List<String>> _morphologyValues = {};

  @override
  void initState() {
    super.initState();
    _isQuickMode = widget.preselectedSpecies != null || widget.forcedQuickMode;
    if (widget.preselectedSpecies != null) {
      _targetSpeciesId = widget.preselectedSpecies!.speciesID;
      _selectedType = widget.preselectedSpecies!.biologicalType;
    }
    Future.microtask(() => context.read<ObservationViewModel>().init());
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    const totalPages = 2;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isQuickMode
              ? "Szybki wpis"
              : "Rejestracja okazu"),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _isQuickMode
                      ? AddObservationQuickPhotoStep(vm: obsVm)
                      : AddObservationLongStep1(
                    selectedType: _selectedType,
                    selectedPhenology: _selectedPhenology,
                    selectedAbundance: _selectedAbundance,
                    selectedVitality: _selectedVitality,
                    onTypeChanged: (v) => setState(() => _selectedType = v),
                    onPhenologyChanged: (v) => setState(() => _selectedPhenology = v),
                    onAbundanceChanged: (v) => setState(() => _selectedAbundance = v),
                    onVitalityChanged: (v) => setState(() => _selectedVitality = v),
                  ),
                  _isQuickMode
                      ? AddObservationQuickPopulationStep(
                    selectedPhenology: _selectedPhenology,
                    selectedAbundance: _selectedAbundance,
                    selectedVitality: _selectedVitality,
                    onPhenologyChanged: (v) => setState(() => _selectedPhenology = v),
                    onAbundanceChanged: (v) => setState(() => _selectedAbundance = v),
                    onVitalityChanged: (v) => setState(() => _selectedVitality = v),
                  )
                      : AddObservationMorphologyStep2(
                    selectedType: _selectedType,
                    morphologyValues: _morphologyValues,
                    onTraitToggled: (category, trait, isSelected) {
                      setState(() {
                        if (_morphologyValues[category] == null) _morphologyValues[category] = [];
                        if (isSelected) {
                          _morphologyValues[category]!.add(trait);
                        } else {
                          _morphologyValues[category]!.remove(trait);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            _buildNavigationRow(obsVm, totalPages),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRow(ObservationViewModel vm, int totalPages) {
    bool canGoNext = false;
    if (_isQuickMode) {
      if (_currentPage == 0) canGoNext = vm.currentPhotoPaths.isNotEmpty;
      if (_currentPage == 1) canGoNext = _selectedPhenology != null && _selectedAbundance != null && _selectedVitality != null;
    } else {
      if (_currentPage == 0) canGoNext = _selectedType != null && _selectedPhenology != null && _selectedAbundance != null && _selectedVitality != null;
      if (_currentPage == 1) canGoNext = true;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
              onPressed: () {
                if (_currentPage == 0) {
                  Navigator.pop(context);
                } else {
                  _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                }
              },
              child: Text(_currentPage == 0 ? "ANULUJ" : "WSTECZ")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: !canGoNext ? null : () {
              if (_currentPage < (totalPages - 1)) {
                _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
              } else {
                _finalizeSave(vm); // POPRAWIONE: Zmiana z obsVm na vm
              }
            },
            child: Text(_currentPage == (totalPages - 1) ? "ZAPISZ OKAZ" : "DALEJ"),
          ),
        ],
      ),
    );
  }

  void _finalizeSave(ObservationViewModel obsVm) async {
    final String observationId = const Uuid().v4();

    final newObs = PlantObservation(
      id: observationId,
      releveId: null,
      speciesId: _isQuickMode ? _targetSpeciesId : null,
      localName: _isQuickMode ? widget.preselectedSpecies?.polishName : null,
      subspecies: "",
      latitude: obsVm.currentPosition?.latitude ?? 0.0,
      longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(),
      observationDate: DateTime.now(),
      photoPaths: List.from(obsVm.currentPhotoPaths),
      phenologicalStage: _selectedPhenology,
      abundance: _selectedAbundance,
      vitality: _selectedVitality,
      tempBiologicalType: _selectedType,
      characteristics: _isQuickMode ? {} : Map.from(_morphologyValues),
    );

    await obsVm.addObservation(newObs);
    obsVm.reset();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: _isQuickMode ? Colors.teal : Colors.indigo,
              content: Text(_isQuickMode
                  ? "Okaz został pomyślnie dodany do Magazynu głównego."
                  : "Okaz został pomyślnie zarejestrowany w sekcji 'Opisz rośliny'.")
          )
      );
    }
  }
}