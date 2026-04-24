// lib/viewmodels/releve_view_model.dart
import 'package:flutter/material.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../services/database_helper.dart';

class ReleveViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Releve> _releves = [];

  List<Releve> get allReleves => _releves;

  // --- OPERACJE BAZODANOWE (CRUD) ---

  Future<void> loadFromDisk() async {
    _releves = await _db.getReleves();
    notifyListeners();
  }

  Future<void> saveNewReleve(Releve releve) async {
    await _db.insertReleve(releve);
    await loadFromDisk();
  }

  Future<void> deleteReleve(String id) async {
    await _db.deleteReleve(id);
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

  Future<void> updateReleveHabitat(String releveId, HabitatInfo info) async {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      _releves[index].habitat = info;
      await _db.insertReleve(_releves[index]);
      notifyListeners();
    }
  }

  Future<void> assignParent(String childId, String? parentId) async {
    final index = _releves.indexWhere((r) => r.id == childId);
    if (index != -1) {
      _releves[index].parentId = parentId;
      await _db.insertReleve(_releves[index]);
      notifyListeners();
    }
  }

  // --- LOGIKA HIERARCHII ---

  List<Releve> getChildren(String parentId) {
    return _releves.where((r) => r.parentId == parentId).toList();
  }

  bool isValidParent(String childType, String potentialParentType) {
    const hierarchy = ["Klasa", "Rząd", "Związek", "Zespół"];
    int childIdx = hierarchy.indexOf(childType);
    int parentIdx = hierarchy.indexOf(potentialParentType);
    if (childIdx == -1 || parentIdx == -1) return false;
    return parentIdx < childIdx;
  }
  /// Zwraca obiekt obszaru nadrzędnego na podstawie jego ID
  Releve? getParentArea(String? parentId) {
    if (parentId == null) return null;
    try {
      return _releves.firstWhere((r) => r.id == parentId);
    } catch (e) {
      return null;
    }
  }

  /// Zwraca listę obszarów, które mogą zostać ustawione jako rodzic dla danego dziecka
  List<Releve> getPotentialParents(Releve child) {
    return _releves.where((r) {
      // Potencjalny rodzic nie może być tym samym obszarem
      // i musi znajdować się wyżej w hierarchii
      return r.id != child.id && isValidParent(child.type, r.type);
    }).toList();
  }
}