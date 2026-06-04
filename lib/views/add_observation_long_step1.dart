// lib/views/widgets/add_observation_long_step1.dart
import 'package:flutter/material.dart';

class AddObservationLongStep1 extends StatelessWidget {
  final String? selectedType;
  final String? selectedPhenology;
  final String? selectedAbundance;
  final String? selectedVitality;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onPhenologyChanged;
  final ValueChanged<String?> onAbundanceChanged;
  final ValueChanged<String?> onVitalityChanged;

  static const List<String> _biologicalTypes = ["Drzewo", "Krzew", "Zielne", "Grzyb", "Mszaki"];

  static const Map<String, String> _phenologyOptions = {
    "Wegetatywny": "Rozwój pędów/liści",
    "Pączkowanie": "Widoczne pąki kwiatowe",
    "Kwitnienie": "Rozwinięte kwiaty",
    "Owocowanie": "Zawiązywanie owoców",
    "Rozsiewanie": "Wysiew nasion",
    "Spoczynek": "Stan zimowy"
  };

  static const Map<String, String> _abundanceOptions = {
    "5": "75-100% pokrycia",
    "4": "50-75%",
    "3": "25-50%",
    "2": "5-25%",
    "1": "<5%",
    "0": "nielicznie"
  };

  static const Map<String, String> _vitalityOptions = {
    "4": "Bardzo dobra",
    "3": "Dobra",
    "2": "Słaba",
    "1": "Zamierająca"
  };

  const AddObservationLongStep1({
    super.key,
    required this.selectedType,
    required this.selectedPhenology,
    required this.selectedAbundance,
    required this.selectedVitality,
    required this.onTypeChanged,
    required this.onPhenologyChanged,
    required this.onAbundanceChanged,
    required this.onVitalityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Krok 1: Typ biologiczny nieznanego taksonu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
          const SizedBox(height: 12),
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2
              ),
              itemCount: _biologicalTypes.length,
              itemBuilder: (ctx, i) {
                final type = _biologicalTypes[i];
                final isSelected = selectedType == type;
                return GestureDetector(
                  onTap: () => onTypeChanged(type),
                  child: Container(
                      decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400)
                      ),
                      child: Center(
                          child: Text(
                              type,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87
                              )
                          )
                      )
                  ),
                );
              }
          ),
          const Divider(height: 40),
          const Text("Parametry ekologiczno-populacyjne stanowiska", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
          const SizedBox(height: 15),
          _buildDropdown("Etap fenologiczny rozwoju", _phenologyOptions, selectedPhenology, onPhenologyChanged),
          const SizedBox(height: 12),
          _buildDropdown("Ilościowość w skali Brauna-Blanqueta", _abundanceOptions, selectedAbundance, onAbundanceChanged),
          const SizedBox(height: 12),
          _buildDropdown("Żywotność stanowiska leśnego/łąkowego", _vitalityOptions, selectedVitality, onVitalityChanged)
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, Map<String, String> map, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: map.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.key} - ${e.value}", style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged
    );
  }
}