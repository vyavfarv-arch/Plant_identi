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
 * Zarządza stanem globalnych filtrów interfejsu użytkownika dla katalogu, mapy
 * oraz wyszukiwarki. Odpowiada za przechowywanie zaznaczonych rodzin, przedziałów
 * dat, zakresów suwaków pH gleby, typów podłoża oraz asynchroniczne ładowanie
 * i usuwanie celów z listy roślin poszukiwanych.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/releve.dart':
 * - Klasa [Releve]: Wykorzystywana jako typ zmiennej filtrowania obserwacji
 * według konkretnego wybranego płatu (filterArea).
 * * Z pliku '../models/sought_plant.dart':
 * - Klasa [SoughtPlant]: Rejestruje kolekcję i typ obiektów celów poszukiwań
 * ekologicznych ładowanych do widoków.
 * * Z pliku '../services/database_helper.dart':
 * - Klasa [DatabaseHelper]: Wywoływana do przeprowadzania operacji CRUD
 * (odczyt listy, usunięcie celu) na tabeli bazy danych 'sought_plants'.
 * ============================================================================
 */
class SearchFilterViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // NOWE: Ładowanie roślin poszukiwanych z nowej tabeli
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
  String? areaFilterType;
  String? areaFilterCanopy;
  String? areaFilterWater;
  String? areaFilterSlope;
  List<String> areaFilterSubstrates = [];
  RangeValues areaFilterPh = const RangeValues(3.0, 9.0);

  void updateAreaFilters({
    String? type, String? canopy, String? water, String? slope,
    List<String>? substrates, RangeValues? ph
  }) {
    areaFilterType = type;
    areaFilterCanopy = canopy;
    areaFilterWater = water;
    areaFilterSlope = slope;
    if (substrates != null) areaFilterSubstrates = List.from(substrates);
    if (ph != null) areaFilterPh = ph;
    notifyListeners();
  }

  void resetAreaFilters() {
    areaFilterType = null;
    areaFilterCanopy = null;
    areaFilterWater = null;
    areaFilterSlope = null;
    areaFilterSubstrates.clear();
    areaFilterPh = const RangeValues(3.0, 9.0);
    notifyListeners();
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
    await loadSoughtPlants(); // Odświeża listę
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