// lib/viewmodels/releve_view_model.dart
import 'package:flutter/material.dart';
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../services/storage_service.dart';

class ReleveViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService();
  List<Releve> _releves = [];

  List<Releve> get allReleves => _releves;

  // Logika hierarchii (przeniesiona z plants_view_model)
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

  // Obsługa HabitatInfo (Gleba/Siedlisko)
  void updateReleveHabitat(String releveId, HabitatInfo info) {
    final index = _releves.indexWhere((r) => r.id == releveId);
    if (index != -1) {
      _releves[index].habitat = info;
      _storage.saveReleves(_releves);
      notifyListeners();
    }
  }

// Pozostałe metody: saveNewReleve, deleteReleve, loadFromDisk...
}