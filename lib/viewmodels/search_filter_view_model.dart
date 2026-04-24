import 'package:flutter/material.dart';
import '../models/releve.dart';

class SearchFilterViewModel extends ChangeNotifier {
  // --- FILTRY OBSERWACJI (ROŚLIN) ---
  DateTimeRange? _filterDateRange;
  final List<String> _selectedFamilies = [];
  final List<String> _selectedPlantNames = []; // Do filtrów na mapie
  Releve? _filterArea; // Filtr roślin w konkretnym wielokącie

  // --- FILTRY OBSZARÓW (RELEVES) ---
  String _areaSearchQuery = "";
  final List<String> _selectedReleveTypes = ["Zespół", "Związek", "Rząd", "Klasa"];
  final Map<String, Set<String>> _selectedSpecificNames = {};

  // --- MODUŁ ROŚLINY POSZUKIWANEJ  ---
  String? _soughtPlantLatinName; // Łacińska nazwa rośliny, której szukamy
  bool _habitatMatchMode = false; // Czy tryb szukania siedlisk jest włączony

  // --- GETTERY ---
  DateTimeRange? get filterDateRange => _filterDateRange;
  List<String> get selectedFamilies => _selectedFamilies;
  List<String> get selectedPlantNames => _selectedPlantNames;
  Releve? get filterArea => _filterArea;

  String get areaSearchQuery => _areaSearchQuery;
  List<String> get selectedReleveTypes => _selectedReleveTypes;

  String? get soughtPlantLatinName => _soughtPlantLatinName;
  bool get habitatMatchMode => _habitatMatchMode;

  // --- METODY ZARZĄDZANIA FILTRAMI ROŚLIN ---
  void setFilterDateRange(DateTimeRange? range) {
    _filterDateRange = range;
    notifyListeners();
  }

  void toggleFamilyFilter(String family) {
    if (_selectedFamilies.contains(family)) {
      _selectedFamilies.remove(family);
    } else {
      _selectedFamilies.add(family);
    }
    notifyListeners();
  }

  void togglePlantNameFilter(String name) {
    if (_selectedPlantNames.contains(name)) {
      _selectedPlantNames.remove(name);
    } else {
      _selectedPlantNames.add(name);
    }
    notifyListeners();
  }

  void setFilterArea(Releve? area) {
    _filterArea = area;
    notifyListeners();
  }

  // --- METODY ZARZĄDZANIA FILTRAMI OBSZARÓW ---
  void setAreaSearchQuery(String query) {
    _areaSearchQuery = query;
    notifyListeners();
  }

  void clearAreaSearchQuery() {
    _areaSearchQuery = "";
    notifyListeners();
  }

  void toggleReleveTypeFilter(String type) {
    if (_selectedReleveTypes.contains(type)) {
      _selectedReleveTypes.remove(type);
    } else {
      _selectedReleveTypes.add(type);
    }
    notifyListeners();
  }

  void toggleNameSelection(String rank, String name) {
    _selectedSpecificNames.putIfAbsent(rank, () => {});
    if (_selectedSpecificNames[rank]!.contains(name)) {
      _selectedSpecificNames[rank]!.remove(name);
    } else {
      _selectedSpecificNames[rank]!.add(name);
    }
    notifyListeners();
  }

  bool isNameSelected(String rank, String name) {
    return _selectedSpecificNames[rank]?.contains(name) ?? false;
  }

  Set<String>? getSelectedNamesForRank(String rank) => _selectedSpecificNames[rank];

  // --- NOWE: LOGIKA POSZUKIWANIA (PRZYGOTOWANIE) ---

  /// Ustawia roślinę jako "poszukiwaną" i aktywuje tryb analizy siedliska
  void setSoughtPlant(String? latinName) {
    _soughtPlantLatinName = latinName;
    _habitatMatchMode = latinName != null;
    notifyListeners();
  }

  // --- RESET ---
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