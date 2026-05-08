// lib/widgets/ecological_amplitude_picker.dart
import 'package:flutter/material.dart';

class EcologicalDataController extends ChangeNotifier {
  double phMin = 5.5;
  double phMax = 7.5;
  List<String> areaTypes = [];
  List<String> waterDynamics = [];
  List<String> lightLevels = []; // Dla gatunku: "Otwarte", "Zacienione" itp.
  List<String> soilTypes = [];   // Dla gatunku: "Gliniasta", "Torfowa" itp.
  List<String> exposures = [];   // Tylko dla trybu obszaru

  void updateData({
    double? newPhMin,
    double? newPhMax,
    List<String>? newAreaTypes,
    List<String>? newWaterDynamics,
    List<String>? newLightLevels,
    List<String>? newSoilTypes,
  }) {
    if (newPhMin != null) phMin = newPhMin;
    if (newPhMax != null) phMax = newPhMax;
    if (newAreaTypes != null) areaTypes = List.from(newAreaTypes);
    if (newWaterDynamics != null) waterDynamics = List.from(newWaterDynamics);
    if (newLightLevels != null) lightLevels = List.from(newLightLevels);
    if (newSoilTypes != null) soilTypes = List.from(newSoilTypes);
    notifyListeners();
  }

  void toggleAreaType(String v) { areaTypes.contains(v) ? areaTypes.remove(v) : areaTypes.add(v); notifyListeners(); }
  void toggleWaterDynamics(String v) { waterDynamics.contains(v) ? waterDynamics.remove(v) : waterDynamics.add(v); notifyListeners(); }
  void toggleLightLevel(String v) { lightLevels.contains(v) ? lightLevels.remove(v) : lightLevels.add(v); notifyListeners(); }
  void toggleSoilType(String v) { soilTypes.contains(v) ? soilTypes.remove(v) : soilTypes.add(v); notifyListeners(); }
  void toggleExposure(String v) { exposures.contains(v) ? exposures.remove(v) : exposures.add(v); notifyListeners(); }
  void updatePh(double min, double max) { phMin = min; phMax = max; notifyListeners(); }
}

class EcologicalAmplitudePicker extends StatelessWidget {
  final EcologicalDataController controller;
  final bool isSpeciesMode; // NOWOŚĆ: Tryb pracy

  EcologicalAmplitudePicker({super.key, required this.controller, this.isSpeciesMode = true});

  // Opcje dla GATUNKU
  final List<String> _lightOptions = ["Otwarte", "Częściowo otwarte", "Częściowo zacienione", "Zacienione"];
  final List<String> _soilOptions = ["Gliniasta", "Piaszczysta", "Czarnoziem", "Torfowa", "Kamienista", "Próchniczna", "Wapienna"];

  // Wspólne/Obszarowe
  final List<String> _areaOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze", "Teren miejski", "Skraj lasu"];
  final List<String> _waterOptions = ["Stale wilgotne", "Sezonowo zalewane", "Sezonowo wysychające", "Stale suche"];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isSpeciesMode ? "Preferencje gatunku:" : "Charakterystyka obszaru:",
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            const Divider(),

            // Sekcja Światło (zmienne nazwy w zależności od trybu)
            _buildMultiSelect(isSpeciesMode ? "Wymagania świetlne:" : "Zwarcie koron:",
                _lightOptions, controller.lightLevels, controller.toggleLightLevel),

            // Sekcja Gleba (Tylko dla gatunku)
            if (isSpeciesMode)
              _buildMultiSelect("Typ gleby:", _soilOptions, controller.soilTypes, controller.toggleSoilType),

            _buildMultiSelect("Typy siedlisk:", _areaOptions, controller.areaTypes, controller.toggleAreaType),
            _buildMultiSelect("Gospodarka wodna:", _waterOptions, controller.waterDynamics, controller.toggleWaterDynamics),

            // Sekcja Ekspozycja (Ukryta w trybie gatunku)
            if (!isSpeciesMode)
              _buildMultiSelect("Ekspozycja:", ["N", "S", "E", "W", "Płasko"], controller.exposures, controller.toggleExposure),

            const Divider(),
            Text("Zakres pH: ${controller.phMin.toStringAsFixed(1)} - ${controller.phMax.toStringAsFixed(1)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            RangeSlider(
              values: RangeValues(controller.phMin, controller.phMax), min: 3.0, max: 9.0, divisions: 60,
              activeColor: Colors.teal,
              onChanged: (v) => controller.updatePh(v.start, v.end),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList, Function(String) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = targetList.contains(opt);
            return FilterChip(
              label: Text(opt, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black)),
              selected: isSelected, selectedColor: Colors.teal,
              onSelected: (_) => onToggle(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}