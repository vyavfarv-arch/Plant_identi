// lib/views/quick_find_form_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../models/sought_plant.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/database_helper.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Terenowy formularz weryfikacji i sukcesu ("Znalazłem!") poszukiwanego gatunku.
 * Wymusza wykonanie dokumentacji fotograficznej za pomocą podglądu aparatu,
 * pobiera statusy fenologii/ilościowości, przepisuje profil Ellenberga do atlasu
 * i automatycznie zapisuje nowy okaz związany z wybranym płatem roślinności.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z katalogu '../models/':
 * - Klasy [Releve], [SoughtPlant], [PlantObservation], [PlantSpecies]: Definicje obiektów bazy i struktur.
 * * Z pliku '../viewmodels/observation_view_model.dart':
 * - Klasa [ObservationViewModel]: Steruje obsługą kamery i realizuje dodanie okazu do Magazynu.
 * * Z pliku '../services/database_helper.dart':
 * - Klasa [DatabaseHelper]: Bezpośrednio wstrzykuje i zapisuje brakujący gatunek do bazy lokalnej.
 * ============================================================================
 */
class QuickFindFormScreen extends StatefulWidget {
  final Releve area;
  final SoughtPlant targetPlant;

  const QuickFindFormScreen({super.key, required this.area, required this.targetPlant});

  @override
  State<QuickFindFormScreen> createState() => _QuickFindFormScreenState();
}

class _QuickFindFormScreenState extends State<QuickFindFormScreen> {
  String? _selectedPhenology;
  String? _selectedAbundance;
  String? _selectedVitality;

  final Map<String, String> _phenologyDescriptions = {
    "Wegetatywny": "Rozwój pędów i liści",
    "Pączkowanie": "Widoczne pąki kwiatowe",
    "Kwitnienie": "Rozwinięte kwiaty",
    "Owocowanie": "Zawiązywanie i dojrzewanie owoców",
    "Rozsiewanie": "Wysiew nasion/zarodników",
    "Spoczynek": "Zamieranie jesienne / stan zimowy"
  };

  final Map<String, String> _abundanceDescriptions = {
    "5": "75-100% pokrycia", "4": "50-75% pokrycia", "3": "25-50%", "2": "5-25%", "1": "<5%", "0": "nielicznie"
  };
  final Map<String, String> _vitalityDescriptions = {
    "4": "Bardzo dobra", "3": "Dobra", "2": "Słaba", "1": "Zamierająca",
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ObservationViewModel>().reset());
    Future.microtask(() => context.read<ObservationViewModel>().init());
  }

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Potwierdź: ${widget.targetPlant.polishName}"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("1. Dokumentacja fotograficzna (Wymagana)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              Container(
                height: 220, width: double.infinity,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
                child: obsVm.currentPhotoPaths.isNotEmpty
                    ? Image.file(File(obsVm.currentPhotoPaths.first), fit: BoxFit.cover)
                    : (obsVm.controller != null && obsVm.controller!.value.isInitialized
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: CameraPreview(obsVm.controller!))
                    : const Center(child: CircularProgressIndicator())),
              ),
              const SizedBox(height: 10),
              if (obsVm.currentPhotoPaths.isEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt), label: const Text("ZRÓB ZDJĘCIE ROŚLINY"),
                    onPressed: () => obsVm.takePhoto(),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh), label: const Text("POWTÓRZ ZDJĘCIE"),
                    onPressed: () => obsVm.removePhoto(0),
                  ),
                ),
              const Divider(height: 30),
              const Text("2. Stan populacji w płacie", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _buildDropdown("Etap fenologiczny", _phenologyDescriptions, (v) => setState(() => _selectedPhenology = v)),
              _buildDropdown("Ilościowość (Braun-Blanquet)", _abundanceDescriptions, (v) => setState(() => _selectedAbundance = v)),
              _buildDropdown("Żywotność okazu", _vitalityDescriptions, (v) => setState(() => _selectedVitality = v)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300),
                  onPressed: (obsVm.currentPhotoPaths.isEmpty || _selectedPhenology == null || _selectedAbundance == null || _selectedVitality == null)
                      ? null
                      : _saveObservation,
                  child: const Text("ZAPISZ I DODAJ DO MAGAZYNU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, Map<String, String> dataMap, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        items: dataMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text("${e.key} - ${e.value}", style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _saveObservation() async {
    final obsVm = context.read<ObservationViewModel>();
    final existingSpecies = obsVm.findSpeciesByLatinName(widget.targetPlant.latinName);
    final String targetSpeciesId = existingSpecies?.speciesID ?? const Uuid().v4();

    if (existingSpecies == null) {
      // FIX: Konstruktor gatunku przekazuje mapy wegetacji Ellenberga z poszukiwanej rośliny
      final newSpecies = PlantSpecies(
        speciesID: targetSpeciesId, latinName: widget.targetPlant.latinName, polishName: widget.targetPlant.polishName,
        family: "Nieokreślona (Wymaga edycji)", biologicalType: "Zielne",
        prefPhMin: widget.targetPlant.prefPhMin, prefPhMax: widget.targetPlant.prefPhMax,
        ellenbergL: widget.targetPlant.ellenbergL, ellenbergF: widget.targetPlant.ellenbergF,
        ellenbergR: widget.targetPlant.ellenbergR, ellenbergN: widget.targetPlant.ellenbergN,
        ellenbergT: widget.targetPlant.ellenbergT, ellenbergK: widget.targetPlant.ellenbergK,
        ellenbergS: widget.targetPlant.ellenbergS,
      );
      await DatabaseHelper().insertSpecies(newSpecies);
    }

    final newObs = PlantObservation(
      id: const Uuid().v4(), releveId: widget.area.id, speciesId: targetSpeciesId,
      localName: widget.targetPlant.polishName, subspecies: "",
      latitude: widget.area.points.first.latitude, longitude: widget.area.points.first.longitude,
      timestamp: DateTime.now(), photoPaths: List.from(obsVm.currentPhotoPaths), characteristics: {},
      phenologicalStage: _selectedPhenology, abundance: _selectedAbundance, vitality: _selectedVitality,
    );

    await obsVm.addObservation(newObs);
    obsVm.reset();

    if (mounted) {
      Navigator.pop(context); // Powrót do mapy
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.teal, content: Text("Sukces! Okaz został zaewidencjonowany w Magazynie.")));
    }
  }
}