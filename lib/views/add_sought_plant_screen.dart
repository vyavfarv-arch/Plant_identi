// lib/views/add_sought_plant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sought_plant.dart';
import '../services/database_helper.dart';
import '../viewmodels/search_filter_view_model.dart';

class AddSoughtPlantScreen extends StatefulWidget {
  const AddSoughtPlantScreen({super.key});

  @override
  State<AddSoughtPlantScreen> createState() => _AddSoughtPlantScreenState();
}

class _AddSoughtPlantScreenState extends State<AddSoughtPlantScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();

  double _prefPhMin = 5.5;
  double _prefPhMax = 7.5;

  final List<String> _prefAreaTypes = [];
  final List<String> _prefExposures = [];
  final List<String> _prefCanopyCovers = [];
  final List<String> _prefWaterDynamics = [];
  final List<String> _prefSoilDepths = [];

  final List<String> _areaTypeOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Teren miejski", "Skraj lasu"];
  final List<String> _exposureOptions = ["N", "S", "E", "W", "Płasko"];
  final List<String> _canopyOptions = ["Otwarte (0-25%)", "Półotwarte (25-60%)", "Zacienione (60-85%)", "Gęste (>85%)"];
  final List<String> _waterOptions = ["Stale wilgotne", "Sezonowo zalewane", "Sezonowo wysychające", "Stale suche"];
  final List<String> _soilOptions = ["Płytka skalista", "Średnia", "Głęboka próchnowa"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowy Cel Poszukiwań ML")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dane podstawowe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nazwa polska", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _latinController, decoration: const InputDecoration(labelText: "Nazwa łacińska", border: OutlineInputBorder())),

            const SizedBox(height: 30),
            const Text("Amplituda Ekologiczna (Zaznacz wszystkie dopuszczalne)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
            const Divider(),

            _buildMultiSelect("Typy obszaru:", _areaTypeOptions, _prefAreaTypes),
            _buildMultiSelect("Ekspozycja stoku:", _exposureOptions, _prefExposures),
            _buildMultiSelect("Zwarcie koron:", _canopyOptions, _prefCanopyCovers),
            _buildMultiSelect("Dynamika wody:", _waterOptions, _prefWaterDynamics),
            _buildMultiSelect("Głębokość gleby:", _soilOptions, _prefSoilDepths),

            const Divider(),
            Text("Preferowane pH: ${_prefPhMin.toStringAsFixed(1)} - ${_prefPhMax.toStringAsFixed(1)}"),
            RangeSlider(
              values: RangeValues(_prefPhMin, _prefPhMax), min: 3.0, max: 9.0, divisions: 60,
              onChanged: (v) => setState(() { _prefPhMin = v.start; _prefPhMax = v.end; }),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                onPressed: _saveSoughtPlant,
                child: const Text("DODAJ DO LISTY POSZUKIWAŃ"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelect(String title, List<String> options, List<String> targetList) {
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
              onSelected: (s) => setState(() => s ? targetList.add(opt) : targetList.remove(opt)),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveSoughtPlant() async {
    if (_nameController.text.isEmpty) return;

    final soughtPlant = SoughtPlant(
      id: const Uuid().v4(),
      polishName: _nameController.text,
      latinName: _latinController.text,
      prefPhMin: _prefPhMin,
      prefPhMax: _prefPhMax,
      prefAreaTypes: _prefAreaTypes,
      prefExposures: _prefExposures,
      prefCanopyCovers: _prefCanopyCovers,
      prefWaterDynamics: _prefWaterDynamics,
      prefSoilDepths: _prefSoilDepths,
    );

    await DatabaseHelper().insertSoughtPlant(soughtPlant);

    if (mounted) {
      context.read<SearchFilterViewModel>().loadSoughtPlants();
      Navigator.pop(context);
    }
  }
}