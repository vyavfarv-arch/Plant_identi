// lib/widgets/ecological_amplitude_picker.dart
import 'package:flutter/material.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Interaktywny komponent i kontroler stanu wyboru liczb wskaźnikowych Ellenberga.
 * Implementuje trzystanową siatkę wyboru kafelków (1 kliknięcie = Tolerancja,
 * 2 kliknięcia = Optimum, 3 kliknięcia = brak powiązania) dla wszystkich 7 osi
 * diagnostycznych oraz suwak zakresu (RangeSlider) preferowanego pH gleby.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich importów innych plików z /lib. Stanowi samodzielny,
 * uniwersalny widżet formularzowy wstrzykiwany do ekranów edycji i poszukiwań.
 * ============================================================================
 */
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

class EcologicalAmplitudePicker extends StatelessWidget {
  final EcologicalDataController controller;
  const EcologicalAmplitudePicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Siatka Amplitudy Ekologicznej Ellenberga:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
            const SizedBox(height: 4),
            const Text("1 klik = Tolerancja (Jasny) | 2 kliki = Optimum (Ciemny + ★)", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            const Divider(),
            _buildEllenbergRow("L - Światło (1-9)", "L", controller.ellenbergL, 1, 9),
            _buildEllenbergRow("F - Wilgotność (1-12)", "F", controller.ellenbergF, 1, 12),
            _buildEllenbergRow("R - Odczyn pH (1-9)", "R", controller.ellenbergR, 1, 9),
            _buildEllenbergRow("N - Żyzność Azot (1-9)", "N", controller.ellenbergN, 1, 9),
            _buildEllenbergRow("T - Temperatura (1-9)", "T", controller.ellenbergT, 1, 9),
            _buildEllenbergRow("K - Kontynentalizm (1-9)", "K", controller.ellenbergK, 1, 9),
            _buildEllenbergRow("S - Zasolenie (0-9)", "S", controller.ellenbergS, 0, 9),
            const Divider(),
            Text("Preferowany Odczyn pH Gleby: ${controller.phMin.toStringAsFixed(1)} - ${controller.phMax.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            RangeSlider(
              values: RangeValues(controller.phMin, controller.phMax), min: 3.0, max: 9.0, divisions: 60, activeColor: Colors.teal,
              onChanged: (v) => controller.updatePh(v.start, v.end),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEllenbergRow(String title, String axis, Map<int, int> currentMap, int min, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(max - min + 1, (index) {
              final val = min + index;
              final state = currentMap[val] ?? 0;

              Color bg = Colors.grey.shade200;
              Color border = Colors.grey.shade400;
              Color text = Colors.black87;

              if (state == 1) {
                bg = Colors.teal.shade100;
                border = Colors.teal.shade300;
                text = Colors.teal.shade900;
              } else if (state == 2) {
                bg = Colors.teal.shade700;
                border = Colors.teal.shade900;
                text = Colors.white;
              }

              return InkWell(
                onTap: () => controller.cycleEllenbergState(axis, val),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 1.5), borderRadius: BorderRadius.circular(6)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text("$val", style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}