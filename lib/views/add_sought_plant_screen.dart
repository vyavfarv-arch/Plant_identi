// lib/views/add_sought_plant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sought_plant.dart';
import '../models/harvest_season.dart';
import '../services/database_helper.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../widgets/ecological_amplitude_picker.dart';
import '../widgets/harvest_season_picker.dart'; // Widget z poprzedniego kroku!

class AddSoughtPlantScreen extends StatefulWidget {
  const AddSoughtPlantScreen({super.key});

  @override
  State<AddSoughtPlantScreen> createState() => _AddSoughtPlantScreenState();
}

class _AddSoughtPlantScreenState extends State<AddSoughtPlantScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();

  final EcologicalDataController _ecoController = EcologicalDataController();
  List<HarvestSeason> _selectedSeasons = []; // Surowce i miesiące

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Nowe Poszukiwanie")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Identyfikacja", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            Autocomplete<String>(
              optionsBuilder: (val) => val.text.isEmpty ? const Iterable<String>.empty() : obsVm.allLatinNames.where((s) => s.toLowerCase().contains(val.text.toLowerCase())),
              onSelected: (selection) {
                _latinController.text = selection;
                final species = obsVm.findSpeciesByLatinName(selection);
                if (species != null) {
                  setState(() {
                    _nameController.text = species.polishName;
                    _selectedSeasons = List.from(species.harvestSeasons); // Wczytanie domyślnych kalendarzy!
                  });
                  _ecoController.updateData(
                    newPhMin: species.prefPhMin, newPhMax: species.prefPhMax, newAreaTypes: species.prefAreaTypes,
                    newExposures: species.prefExposures, newCanopyCovers: species.prefCanopyCovers,
                    newWaterDynamics: species.prefWaterDynamics, newSoilDepths: species.prefSoilDepths,
                  );
                }
              },
              fieldViewBuilder: (ctx, ctrl, node, onSub) {
                if (_latinController.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _latinController.text;
                return TextField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: "Nazwa łacińska (podpowiedzi z Magazynu)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)), onChanged: (v) => _latinController.text = v);
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nazwa polska", border: OutlineInputBorder())),

            const Divider(height: 40),

            // WIDGET KALENDARZY (Z poprz. kroku)
            HarvestSeasonPicker(
              initialSeasons: _selectedSeasons,
              onChanged: (seasons) => setState(() => _selectedSeasons = List.from(seasons)),
            ),

            const Divider(height: 40),
            const Text("Amplituda Ekologiczna (Zaznacz dopuszczalne)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),

            // WIDGET EKOLOGICZNY (Stworzony w tym kroku)
            EcologicalAmplitudePicker(controller: _ecoController),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: _saveAndSetReminder,
                icon: const Icon(Icons.alarm_add),
                label: const Text("ZAPISZ POSZUKIWANIE (I PRZYPOMNIENIA)"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _saveAndSetReminder() async {
    if (_nameController.text.isEmpty) return;

    final sought = SoughtPlant(
      id: const Uuid().v4(),
      polishName: _nameController.text,
      latinName: _latinController.text,
      harvestSeasons: _selectedSeasons, // Zapisywanie zaawansowanego kalendarza

      prefPhMin: _ecoController.phMin,
      prefPhMax: _ecoController.phMax,
      prefAreaTypes: _ecoController.areaTypes,
      prefExposures: _ecoController.exposures,
      prefCanopyCovers: _ecoController.canopyCovers,
      prefWaterDynamics: _ecoController.waterDynamics,
      prefSoilDepths: _ecoController.soilDepths,
    );

    await DatabaseHelper().insertSoughtPlant(sought);

    if (_selectedSeasons.isNotEmpty) {
      debugPrint("LOG: Zaplanowano powiadomienia dla ${_nameController.text}. Surowce: ${_selectedSeasons.map((e) => e.material).join(', ')}");
    }

    if (mounted) {
      context.read<SearchFilterViewModel>().loadSoughtPlants();
      Navigator.pop(context);
    }
  }
}