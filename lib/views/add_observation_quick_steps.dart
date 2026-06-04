// lib/views/widgets/add_observation_quick_steps.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../viewmodels/observation_view_model.dart';

class AddObservationQuickPhotoStep extends StatelessWidget {
  final ObservationViewModel vm;

  const AddObservationQuickPhotoStep({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Krok 1: Dokumentacja fotograficzna okazu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const SizedBox(height: 15),
              Container(
                  height: 240, width: double.infinity,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                  child: vm.currentPhotoPaths.isNotEmpty
                      ? Image.file(File(vm.currentPhotoPaths.first), fit: BoxFit.cover)
                      : (vm.controller != null && vm.controller!.value.isInitialized
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CameraPreview(vm.controller!))
                      : const Center(child: CircularProgressIndicator()))
              ),
              const SizedBox(height: 15),
              if (vm.currentPhotoPaths.isEmpty)
                SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.camera_alt), label: const Text("ZRÓB ZDJĘCIE"), onPressed: () => vm.takePhoto()))
              else
                SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.refresh), label: const Text("POWTÓRZ ZDJĘCIE"), onPressed: () => vm.removePhoto(0)))
            ]
        )
    );
  }
}

class AddObservationQuickPopulationStep extends StatelessWidget {
  final String? selectedPhenology;
  final String? selectedAbundance;
  final String? selectedVitality;
  final ValueChanged<String?> onPhenologyChanged;
  final ValueChanged<String?> onAbundanceChanged;
  final ValueChanged<String?> onVitalityChanged;

  final Map<String, String> _phenologyOptions = {
    "Wegetatywny": "Rozwój pędów/liści",
    "Pączkowanie": "Widoczne pąki kwiatowe",
    "Kwitnienie": "Rozwinięte kwiaty",
    "Owocowanie": "Zawiązywanie owoców",
    "Rozsiewanie": "Wysiew nasion",
    "Spoczynek": "Stan zimowy"
  };

  final Map<String, String> _abundanceOptions = {
    "5": "75-100% pokrycia",
    "4": "50-75%",
    "3": "25-50%",
    "2": "5-25%",
    "1": "<5%",
    "0": "nielicznie"
  };

  final Map<String, String> _vitalityOptions = {
    "4": "Bardzo dobra",
    "3": "Dobra",
    "2": "Słaba",
    "1": "Zamierająca"
  };

  const AddObservationQuickPopulationStep({
    super.key,
    required this.selectedPhenology,
    required this.selectedAbundance,
    required this.selectedVitality,
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
              const Text("Krok 2: Stan stanowiska i populacji", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              const SizedBox(height: 20),
              _buildDropdown("Etap fenologiczny rozwoju", _phenologyOptions, selectedPhenology, onPhenologyChanged),
              const SizedBox(height: 12),
              _buildDropdown("Ilościowość w skali Brauna-Blanqueta", _abundanceOptions, selectedAbundance, onAbundanceChanged),
              const SizedBox(height: 12),
              _buildDropdown("Żywotność stanowiska", _vitalityOptions, selectedVitality, onVitalityChanged)
            ]
        )
    );
  }

  Widget _buildDropdown(String label, Map<String, String> map, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
        value: value, isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: map.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.key} - ${e.value}", style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged
    );
  }
}