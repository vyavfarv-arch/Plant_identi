// lib/widgets/ecological_amplitude_picker.dart
import 'package:flutter/material.dart';

// KONTROLER: Trzyma stan filtrów ekologicznych, odciążając w ten sposób główne ekrany.
class EcologicalDataController extends ChangeNotifier {
  double phMin = 5.5;
  double phMax = 7.5;
  List<String> areaTypes = [];
  List<String> exposures = [];
  List<String> canopyCovers = [];
  List<String> waterDynamics = [];
  List<String> soilDepths = [];

  // Szybka aktualizacja całości (używana przez Autouzupełnianie)
  void updateData({
    double? newPhMin, double? newPhMax,
    List<String>? newAreaTypes, List<String>? newExposures,
    List<String>? newCanopyCovers, List<String>? newWaterDynamics,
    List<String>? newSoilDepths,
  }) {
    if (newPhMin != null) phMin = newPhMin;
    if (newPhMax != null) phMax = newPhMax;
    if (newAreaTypes != null) areaTypes = List.from(newAreaTypes);
    if (newExposures != null) exposures = List.from(newExposures);
    if (newCanopyCovers != null) canopyCovers = List.from(newCanopyCovers);
    if (newWaterDynamics != null) waterDynamics = List.from(newWaterDynamics);
    if (newSoilDepths != null) soilDepths = List.from(newSoilDepths);
    notifyListeners();
  }

  // Funkcje przełączające stan pojedynczych filtrów
  void toggleAreaType(String v) { areaTypes.contains(v) ? areaTypes.remove(v) : areaTypes.add(v); notifyListeners(); }
  void toggleExposure(String v) { exposures.contains(v) ? exposures.remove(v) : exposures.add(v); notifyListeners(); }
  void toggleCanopyCover(String v) { canopyCovers.contains(v) ? canopyCovers.remove(v) : canopyCovers.add(v); notifyListeners(); }
  void toggleWaterDynamics(String v) { waterDynamics.contains(v) ? waterDynamics.remove(v) : waterDynamics.add(v); notifyListeners(); }
  void toggleSoilDepth(String v) { soilDepths.contains(v) ? soilDepths.remove(v) : soilDepths.add(v); notifyListeners(); }
  void updatePh(double min, double max) { phMin = min; phMax = max; notifyListeners(); }
}

// WIDGET: Samodzielny komponent UI, który można wkleić na dowolny ekran
class EcologicalAmplitudePicker extends StatelessWidget {
  final EcologicalDataController controller;

  EcologicalAmplitudePicker({super.key, required this.controller});

  final List<String> _areaTypeOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Teren miejski", "Skraj lasu"];
  final List<String> _exposureOptions = ["N", "S", "E", "W", "Płasko"];
  final List<String> _canopyOptions = ["Otwarte (0-25%)", "Półotwarte (25-60%)", "Zacienione (60-85%)", "Gęste (>85%)"];
  final List<String> _waterOptions = ["Stale wilgotne", "Sezonowo zalewane", "Sezonowo wysychające", "Stale suche"];
  final List<String> _soilOptions = ["Płytka skalista", "Średnia", "Głęboka próchnowa"];

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder nasłuchuje zmian w Kontrolerze i odrysowuje tylko ten mały fragment ekranu!
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Zaznacz wszystkie warunki, w których ten gatunek występuje:", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
            const Divider(),
            _buildMultiSelect("Typy obszaru:", _areaTypeOptions, controller.areaTypes, controller.toggleAreaType),
            _buildMultiSelect("Ekspozycja stoku:", _exposureOptions, controller.exposures, controller.toggleExposure),
            _buildMultiSelect("Zwarcie koron:", _canopyOptions, controller.canopyCovers, controller.toggleCanopyCover),
            _buildMultiSelect("Dynamika wody:", _waterOptions, controller.waterDynamics, controller.toggleWaterDynamics),
            _buildMultiSelect("Głębokość gleby:", _soilOptions, controller.soilDepths, controller.toggleSoilDepth),
            const Divider(),
            Text("Preferowane pH: ${controller.phMin.toStringAsFixed(1)} - ${controller.phMax.toStringAsFixed(1)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            RangeSlider(
              values: RangeValues(controller.phMin, controller.phMax), min: 3.0, max: 9.0, divisions: 60,
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