// lib/views/add_sought_plant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sought_plant.dart';
import '../models/plant_species.dart';
import '../services/database_helper.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../viewmodels/observation_view_model.dart';

class AddSoughtPlantScreen extends StatefulWidget {
  const AddSoughtPlantScreen({super.key});

  @override
  State<AddSoughtPlantScreen> createState() => _AddSoughtPlantScreenState();
}

class _AddSoughtPlantScreenState extends State<AddSoughtPlantScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latinController = TextEditingController();

  String? _selectedMaterial;
  final List<int> _reminderMonths = [];

  final List<String> _materials = ["Kwiaty", "Liście", "Korzeń", "Kora", "Owoce", "Nasiona", "Ziele", "Pączki"];
  final List<String> _monthNames = ["Sty", "Lut", "Mar", "Kwi", "Maj", "Cze", "Lip", "Sie", "Wrz", "Paź", "Lis", "Gru"];

  // ... (poprzednie pola prefPhMin itp zostają) ...

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Nowe Poszukiwanie i Zbiór")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Czego szukasz?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // Autouzupełnianie z Magazynu, aby pobrać domyślne miesiące
            Autocomplete<String>(
              optionsBuilder: (textValue) => obsVm.allLatinNames.where((s) => s.toLowerCase().contains(textValue.text.toLowerCase())),
              onSelected: (selection) {
                _latinController.text = selection;
                _autoFillFromSpecies(selection, obsVm);
              },
              fieldViewBuilder: (ctx, ctrl, node, onSub) => TextField(
                controller: ctrl..text = _latinController.text,
                focusNode: node,
                decoration: const InputDecoration(labelText: "Nazwa łacińska (podpowiedzi z Magazynu)", border: OutlineInputBorder()),
                onChanged: (v) => _latinController.text = v,
              ),
            ),
            const SizedBox(height: 10),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nazwa polska", border: OutlineInputBorder())),

            const SizedBox(height: 25),
            const Text("Surowiec do zbioru:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Wrap(
              spacing: 8,
              children: _materials.map((m) => ChoiceChip(
                label: Text(m),
                selected: _selectedMaterial == m,
                onSelected: (s) => setState(() => _selectedMaterial = s ? m : null),
              )).toList(),
            ),

            const SizedBox(height: 20),
            const Text("Miesiące zbioru (Kiedy wysłać przypomnienie?):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2.5, mainAxisSpacing: 5, crossAxisSpacing: 5),
              itemCount: 12,
              itemBuilder: (ctx, i) {
                final monthIdx = i + 1;
                final isSelected = _reminderMonths.contains(monthIdx);
                return FilterChip(
                  label: Text(_monthNames[i], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
                  selected: isSelected,
                  selectedColor: Colors.orange,
                  onSelected: (s) => setState(() => s ? _reminderMonths.add(monthIdx) : _reminderMonths.remove(monthIdx)),
                );
              },
            ),

            const Divider(height: 40),
            const Text("Parametry siedliska (ML)", style: TextStyle(fontWeight: FontWeight.bold)),
            // ... (Tutaj Twoje poprzednie filtry prefAreaTypes itp) ...

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: _saveAndSetReminder,
                icon: const Icon(Icons.alarm_add),
                label: const Text("ZAPISZ I USTAW PRZYPOMNIENIA"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _autoFillFromSpecies(String latinName, ObservationViewModel vm) {
    final species = vm.findSpeciesByLatinName(latinName);
    if (species != null) {
      setState(() {
        _nameController.text = species.polishName;
        // Jeśli gatunek ma już zdefiniowane sezony zbioru, możemy je tu wstępnie zaznaczyć
        // ale użytkownik może chcieć szukać konkretnego surowca
      });
    }
  }

  void _saveAndSetReminder() async {
    if (_nameController.text.isEmpty) return;

    final sought = SoughtPlant(
      id: const Uuid().v4(),
      polishName: _nameController.text,
      latinName: _latinController.text,
      targetMaterial: _selectedMaterial,
      reminderMonths: _reminderMonths,
      // ... pozostałe pola pref ...
    );

    await DatabaseHelper().insertSoughtPlant(sought);

    // LOGIKA PRZYPOMNIEŃ:
    // Tu wywołujemy systemowy Reminder/Notification Service
    _scheduleNotifications(sought);

    if (mounted) {
      context.read<SearchFilterViewModel>().loadSoughtPlants();
      Navigator.pop(context);
    }
  }

  void _scheduleNotifications(SoughtPlant plant) {
    if (plant.reminderMonths.isEmpty) return;

    // Przykładowa wiadomość: "Sezon na zbiór: [Surowiec] rośliny [Nazwa] właśnie się zaczął!"
    print("LOG: Zaplanowano powiadomienia dla ${plant.polishName} na miesiące: ${plant.reminderMonths}");
    // W rzeczywistej aplikacji użylibyśmy flutter_local_notifications
  }
}