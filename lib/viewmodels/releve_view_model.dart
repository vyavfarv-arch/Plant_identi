import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../services/storage_service.dart';

class ReleveViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Releve> _releves = [];

  // Filtrowanie
  String _areaSearchQuery = "";
  final List<String> _selectedReleveTypes = ["Zespół", "Związek", "Rząd", "Klasa"];
  final Map<String, Set<String>> _selectedSpecificNames = {};

  List<Releve> get allReleves => _releves;
  String get areaSearchQuery => _areaSearchQuery;
  List<String> get selectedReleveTypes => _selectedReleveTypes;

  // --- ŁADOWANIE I ZAPIS ---

  Future<void> loadFromDisk() async {
    _releves = await _storage.loadReleves();
    notifyListeners();
  }

  void saveNewReleve(Releve releve) {
    _releves.add(releve);
    _storage.saveReleves(_releves);
    notifyListeners();
  }

  void deleteReleve(String id) {
    _releves.removeWhere((r) => r.id == id);
    _storage.saveReleves(_releves);
    notifyListeners();
  }

  void updateReleve(String id, String newCommonName, String newPhytoName, String newType) {
    final index = _releves.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _releves[index];
      _releves[index] = Releve(
        id: old.id,
        commonName: newCommonName,
        phytosociologicalName: newPhytoName,
        type: newType,
        points: old.points,
        date: old.date,
        parentId: old.parentId,
        habitat: old.habitat,
      );
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }

  // --- HIERARCHIA I SIEDLISKO ---

  bool isValidParent(String childType, String parentType) {
    if (childType == "Rząd") return parentType == "Klasa";
    if (childType == "Związek") return parentType == "Rząd";
    if (childType == "Zespół") return parentType == "Związek";
    return false;
  }

  void assignParent(String childId, String? parentId) {
    final index = _releves.indexWhere((r) => r.id == childId);
    if (index != -1) {
      _releves[index].parentId = parentId;
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }

  List<Releve> getChildren(String parentId) =>
      _releves.where((r) => r.parentId == parentId).toList();

  Releve? getParentArea(String? parentId) {
    if (parentId == null) return null;
    return _releves.cast<Releve?>().firstWhere((r) => r?.id == parentId, orElse: () => null);
  }

  List<Releve> getPotentialParents(Releve child) =>
      _releves.where((r) => isValidParent(child.type, r.type)).toList();

  void updateReleveHabitat(String releveId, HabitatInfo info) {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      _releves[index].habitat = info;
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }

  // --- LOGIKA FILTROWANIA (MAPA I LISTA) ---

  void setAreaSearchQuery(String query) {
    _areaSearchQuery = query;
    notifyListeners();
  }

  void clearAreaSearchQuery() {
    _areaSearchQuery = "";
    notifyListeners();
  }

  void toggleReleveTypeFilter(String type) {
    _selectedReleveTypes.contains(type) ? _selectedReleveTypes.remove(type) : _selectedReleveTypes.add(type);
    notifyListeners();
  }

  List<Releve> get filteredReleves {
    return _releves.where((r) {
      final matchesType = _selectedReleveTypes.contains(r.type);
      final matchesSearch = _areaSearchQuery.isEmpty ||
          r.commonName.toLowerCase().contains(_areaSearchQuery.toLowerCase()) ||
          r.phytosociologicalName.toLowerCase().contains(_areaSearchQuery.toLowerCase());

      final specificNames = _selectedSpecificNames[r.type] ?? {};
      final matchesSpecific = specificNames.isEmpty || specificNames.contains(r.commonName);

      return matchesType && matchesSearch && matchesSpecific;
    }).toList();
  }

  List<String> getUniqueNamesForRank(String rank) =>
      _releves.where((r) => r.type == rank).map((r) => r.commonName).toSet().toList();

  bool isNameSelected(String rank, String name) => _selectedSpecificNames[rank]?.contains(name) ?? false;

  void toggleNameSelection(String rank, String name) {
    _selectedSpecificNames.putIfAbsent(rank, () => {});
    _selectedSpecificNames[rank]!.contains(name)
        ? _selectedSpecificNames[rank]!.remove(name)
        : _selectedSpecificNames[rank]!.add(name);
    notifyListeners();
  }
}