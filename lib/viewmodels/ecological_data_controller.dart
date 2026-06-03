// lib/viewmodels/ecological_data_controller.dart
import 'package:flutter/material.dart';

class EcologicalDataController extends ChangeNotifier {
  double phMin = 5.5;
  double phMax = 7.5;

  final Map<int, int> ellenbergL = {};
  final Map<int, int> ellenbergF = {};
  final Map<int, int> ellenbergR = {};
  final Map<int, int> ellenbergN = {};
  final Map<int, int> ellenbergT = {};
  final Map<int, int> ellenbergK = {};
  final Map<int, int> ellenbergS = {};

  void updateFromSpeciesData({
    double? newPhMin, double? newPhMax,
    required Map<int, int> lL, required Map<int, int> lF,
    required Map<int, int> lR, required Map<int, int> lN,
    required Map<int, int> lT, required Map<int, int> lK,
    required Map<int, int> lS,
  }) {
    if (newPhMin != null) phMin = newPhMin;
    if (newPhMax != null) phMax = newPhMax;
    ellenbergL..clear()..addAll(lL);
    ellenbergF..clear()..addAll(lF);
    ellenbergR..clear()..addAll(lR);
    ellenbergN..clear()..addAll(lN);
    ellenbergT..clear()..addAll(lT);
    ellenbergK..clear()..addAll(lK);
    ellenbergS..clear()..addAll(lS);
    notifyListeners();
  }

  void cycleEllenbergState(String axis, int value) {
    Map<int, int> targetMap;
    switch (axis) {
      case 'L': targetMap = ellenbergL; break;
      case 'F': targetMap = ellenbergF; break;
      case 'R': targetMap = ellenbergR; break;
      case 'N': targetMap = ellenbergN; break;
      case 'T': targetMap = ellenbergT; break;
      case 'K': targetMap = ellenbergK; break;
      case 'S': targetMap = ellenbergS; break;
      default: return;
    }
    int currentState = targetMap[value] ?? 0;
    int nextState = (currentState + 1) % 3;
    if (nextState == 0) {
      targetMap.remove(value);
    } else {
      targetMap[value] = nextState;
    }
    notifyListeners();
  }

  void updatePh(double min, double max) { phMin = min; phMax = max; notifyListeners(); }
}