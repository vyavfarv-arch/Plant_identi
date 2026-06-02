// lib/widgets/ecological_amplitude_picker.dart
import 'package:flutter/material.dart';

class EcologicalDataController extends ChangeNotifier {
  double phMin = 5.5;
  double phMax = 7.5;

  // Inicjalizacja trzystanowych map indeksów Ellenberga
  final Map<int, int> ellenbergL = {}; // 1 - 9
  final Map<int, int> ellenbergF = {}; // 1 - 12
  final Map<int, int> ellenbergR = {}; // 1 - 9
  final Map<int, int> ellenbergN = {}; // 1 - 9
  final Map<int, int> ellenbergT = {}; // 1 - 9
  final Map<int, int> ellenbergK = {}; // 1 - 9
  final Map<int, int> ellenbergS = {}; // 0 - 9

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

  // LOGIKA ZAKODOWANA: Trzystanowy cykl kliknięć kwadratów (0 -> 1 -> 2 -> 0)
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
    int nextState = (currentState + 1) % 3; // Cykl trzech stanów

    if (nextState == 0) {
      targetMap.remove(value); // Czyszczenie nieaktywnego indeksu
    } else {
      targetMap[value] = nextState;
    }
    notifyListeners();
  }

  void updatePh(double min, double max) { phMin = min; phMax = max; notifyListeners(); }
}