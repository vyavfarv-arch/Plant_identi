import 'package:flutter/material.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../services/database_helper.dart'; // ZMIANA: Nowy serwis

class ReleveViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper(); // ZMIANA
  List<Releve> _releves = [];

  // Filtry pozostają w pamięci RAM
  String _areaSearchQuery = "";
  final List<String> _selectedReleveTypes = ["Zespół", "Związek", "Rząd", "Klasa"];
  final Map<String, Set<String>> _selectedSpecificNames = {};

  List<Releve> get allReleves => _releves;
  String get areaSearchQuery => _areaSearchQuery;
  List<String> get selectedReleveTypes => _selectedReleveTypes;

  // --- ŁADOWANIE I ZAPIS SQLITE ---

  Future<void> loadFromDisk() async {
    _releves = await _db.getReleves(); // Pobranie z bazy
    notifyListeners();
  }

  Future<void> saveNewReleve(Releve releve) async {
    await _db.insertReleve(releve); // Zapis do bazy
    await loadFromDisk();
  }

  Future<void> deleteReleve(String id) async {
    await _db.deleteReleve(id); // Usunięcie z bazy
    await loadFromDisk();
  }

  Future<void> updateReleve(String id, String newCommonName, String newPhytoName, String newType) async {
    final index = _releves.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _releves[index];
      final updated = Releve(
        id: old.id,
        commonName: newCommonName,
        phytosociologicalName: newPhytoName,
        type: newType,
        points: old.points,
        date: old.date,
        parentId: old.parentId,
        habitat: old.habitat,
      );
      await _db.insertReleve(updated);
      await loadFromDisk();
    }
  }

  // --- HIERARCHIA I SIEDLISKO ---

  bool isValidParent(String childType, String parentType) {
    if (childType == "Rząd") return parentType == "Klasa";
    if (childType == "Związek") return parentType == "Rząd";
    if (childType == "Zespół") return parentType == "Związek";
    return false;
  }

  Future<void> assignParent(String childId, String? parentId) async {
    final index = _releves.indexWhere((r) => r.id == childId);
    if (index != -1) {
      _releves[index].parentId = parentId;
      await _db.insertReleve(_releves[index]);
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

  Future<void> updateReleveHabitat(String releveId, HabitatInfo info) async {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      _releves[index].habitat = info;
      await _db.insertReleve(_releves[index]);
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