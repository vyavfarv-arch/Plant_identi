// lib/viewmodels/search_filter_view_model.dart
import 'package:flutter/material.dart';
import '../models/releve.dart';
import '../models/sought_plant.dart';
import '../services/database_helper.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Zarządza stanem globalnych filtrów interfejsu użytkownika. Zaktualizowany o pełne
 * numeryczne i słownikowe odwzorowanie parametrów krytycznych siedliska HabitatInfo.
 * ============================================================================
 */
class SearchFilterViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<SoughtPlant> _soughtPlants = [];
  List<SoughtPlant> get soughtPlants => _soughtPlants;

  Future<void> loadSoughtPlants() async {
    _soughtPlants = await _db.getSoughtPlants();
    notifyListeners();
  }

  // --- FILTRY OBSERWACJI (ROŚLIN) ---
  DateTimeRange? _filterDateRange;
  final List<String> _selectedFamilies = [];
  final List<String> _selectedPlantNames = [];
  Releve? _filterArea;

  // --- FILTRY OBSZARÓW (RELEVES) ---
  String _areaSearchQuery = "";
  final List<String> _selectedReleveTypes = ["Zespół", "Związek", "Rząd", "Klasa"];
  final Map<String, Set<String>> _selectedSpecificNames = {};

  String? _soughtPlantLatinName;
  bool _habitatMatchMode = false;

  DateTimeRange? get filterDateRange => _filterDateRange;
  List<String> get selectedFamilies => _selectedFamilies;
  List<String> get selectedPlantNames => _selectedPlantNames;
  Releve? get filterArea => _filterArea;
  String get areaSearchQuery => _areaSearchQuery;
  List<String> get selectedReleveTypes => _selectedReleveTypes;
  String? get soughtPlantLatinName => _soughtPlantLatinName;
  bool get habitatMatchMode => _habitatMatchMode;

  // --- PEŁNE PARAMETRY FILTROWANIA SIEDLISKOWEGO (Zsynchronizowane z HabitatInfo) ---
  String? areaFilterAreaType;
  RangeValues areaFilterCanopyRange = const RangeValues(1.0, 9.0);
  String? areaFilterWaterMovement;
  String? areaFilterSlopeAngle;
  String? areaFilterExposure;
  String? areaFilterHydrologicalContext;
  String? areaFilterSoilSurfaceCover;
  String? areaFilterHumanImpact;
  List<String> areaFilterSubstrates = [];
  RangeValues areaFilterPh = const RangeValues(3.0, 9.0);
  String? areaFilterReleveRank; // Obszar / Podobszar

  void updateAreaFilters({
    String? areaType,
    RangeValues? canopyRange,
    String? waterMovement,
    String? slopeAngle,
    String? exposure,
    String? hydrologicalContext,
    String? soilSurfaceCover,
    String? humanImpact,
    List<String>? substrates,
    RangeValues? ph,
    String? releveRank,
  }) {
    areaFilterAreaType = areaType;
    if (canopyRange != null) areaFilterCanopyRange = canopyRange;
    areaFilterWaterMovement = waterMovement;
    areaFilterSlopeAngle = slopeAngle;
    areaFilterExposure = exposure;
    areaFilterHydrologicalContext = hydrologicalContext;
    areaFilterSoilSurfaceCover = soilSurfaceCover;
    areaFilterHumanImpact = humanImpact;
    if (substrates != null) areaFilterSubstrates = List.from(substrates);
    if (ph != null) areaFilterPh = ph;
    areaFilterReleveRank = releveRank;
    notifyListeners();
  }

  void resetAreaFilters() {
    areaFilterAreaType = null;
    areaFilterCanopyRange = const RangeValues(1.0, 9.0);
    areaFilterWaterMovement = null;
    areaFilterSlopeAngle = null;
    areaFilterExposure = null;
    areaFilterHydrologicalContext = null;
    areaFilterSoilSurfaceCover = null;
    areaFilterHumanImpact = null;
    areaFilterSubstrates.clear();
    areaFilterPh = const RangeValues(3.0, 9.0);
    areaFilterReleveRank = null;
    notifyListeners();
  }

  bool isAnyAreaFilterActive() {
    return areaFilterAreaType != null ||
        areaFilterCanopyRange.start > 1.1 || areaFilterCanopyRange.end < 8.9 ||
        areaFilterWaterMovement != null ||
        areaFilterSlopeAngle != null ||
        areaFilterExposure != null ||
        areaFilterHydrologicalContext != null ||
        areaFilterSoilSurfaceCover != null ||
        areaFilterHumanImpact != null ||
        areaFilterSubstrates.isNotEmpty ||
        areaFilterPh.start > 3.1 || areaFilterPh.end < 8.9 ||
        areaFilterReleveRank != null;
  }

  void setFilterDateRange(DateTimeRange? range) {
    _filterDateRange = range;
    notifyListeners();
  }

  void toggleFamilyFilter(String family) {
    if (_selectedFamilies.contains(family)) _selectedFamilies.remove(family);
    else _selectedFamilies.add(family);
    notifyListeners();
  }

  void togglePlantNameFilter(String name) {
    if (_selectedPlantNames.contains(name)) _selectedPlantNames.remove(name);
    else _selectedPlantNames.add(name);
    notifyListeners();
  }

  void setFilterArea(Releve? area) {
    _filterArea = area;
    notifyListeners();
  }

  void setAreaSearchQuery(String query) {
    _areaSearchQuery = query;
    notifyListeners();
  }

  void clearAreaSearchQuery() {
    _areaSearchQuery = "";
    notifyListeners();
  }

  void toggleReleveTypeFilter(String type) {
    if (_selectedReleveTypes.contains(type)) _selectedReleveTypes.remove(type);
    else _selectedReleveTypes.add(type);
    notifyListeners();
  }

  void toggleNameSelection(String rank, String name) {
    _selectedSpecificNames.putIfAbsent(rank, () => {});
    if (_selectedSpecificNames[rank]!.contains(name)) _selectedSpecificNames[rank]!.remove(name);
    else _selectedSpecificNames[rank]!.add(name);
    notifyListeners();
  }

  bool isNameSelected(String rank, String name) => _selectedSpecificNames[rank]?.contains(name) ?? false;
  Set<String>? getSelectedNamesForRank(String rank) => _selectedSpecificNames[rank];

  void setSoughtPlant(String? latinName) {
    _soughtPlantLatinName = latinName;
    _habitatMatchMode = latinName != null;
    notifyListeners();
  }

  Future<void> deleteSoughtPlant(String id) async {
    await _db.deleteSoughtPlant(id);
    await loadSoughtPlants();
  }

  void resetAllFilters() {
    _filterDateRange = null;
    _selectedFamilies.clear();
    _selectedPlantNames.clear();
    _filterArea = null;
    _areaSearchQuery = "";
    _selectedSpecificNames.clear();
    _soughtPlantLatinName = null;
    _habitatMatchMode = false;
    notifyListeners();
  }
}