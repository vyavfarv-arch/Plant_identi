// lib/viewmodels/releve_view_model.dart
import 'package:flutter/material.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../services/database_helper.dart';

class ReleveViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Releve> _releves = [];

  // --- STANY ASYNCHRONICZNE WYMAGANE PRZEZ CODE REVIEW ---
  bool _isLoading = false;
  String? _errorMessage;

  List<Releve> get allReleves => _releves;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<void> loadFromDisk() async {
    _setLoading(true);
    _setError(null);
    try {
      _releves = await _db.getReleves();
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  Future<void> saveNewReleve(Releve releve) async {
    _setLoading(true);
    try {
      await _db.insertReleve(releve);
      await loadFromDisk();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> deleteReleve(String id) async {
    _setLoading(true);
    try {
      await _db.deleteReleve(id);
      await loadFromDisk();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> updateReleve(String id, String newCommonName, String newPhytoName, String newType) async {
    final index = _releves.indexWhere((r) => r.id == id);
    if (index != -1) {
      // POPRAWKA: Stosujemy copyWith zamiast ręcznego przebudowywania wszystkich parametrów
      final updated = _releves[index].copyWith(
        commonName: newCommonName,
        phytosociologicalName: newPhytoName,
        type: newType,
      );
      await _db.insertReleve(updated);
      await loadFromDisk();
    }
  }

  Future<void> updateReleveHabitat(String releveId, HabitatInfo info) async {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      // POPRAWKA BŁĘDU SETTERA: Tworzymy kopię obiektu z nowym siedliskiem
      _releves[index] = _releves[index].copyWith(habitat: info);
      await _db.insertReleve(_releves[index]);
      notifyListeners();
    }
  }

  Future<void> assignParent(String childId, String? parentId) async {
    final index = _releves.indexWhere((r) => r.id == childId);
    if (index != -1) {
      // POPRAWKA BŁĘDU SETTERA: Kopiowanie z nadpisaniem parentId
      _releves[index] = _releves[index].copyWith(parentId: parentId);
      await _db.insertReleve(_releves[index]);
      notifyListeners();
    }
  }

  Future<void> updateRelevePredictions(String releveId, Map<String, double> predictions) async {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      // POPRAWKA BŁĘDU SETTERA: Kopiowanie z nadpisaniem predykcji
      _releves[index] = _releves[index].copyWith(mlPredictions: predictions);
      await _db.insertReleve(_releves[index]);
      notifyListeners();
    }
  }

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

  Releve? getParentArea(String? parentId) {
    if (parentId == null) return null;
    try {
      return _releves.firstWhere((r) => r.id == parentId);
    } catch (e) {
      return null;
    }
  }

  List<Releve> getPotentialParents(Releve child) {
    return _releves.where((r) {
      return r.id != child.id && isValidParent(child.type, r.type);
    }).toList();
  }
}