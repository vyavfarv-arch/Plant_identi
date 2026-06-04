// lib/views/add_plant_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import 'camera_screen.dart';
import 'classification_screen.dart';
import 'quick_add_observation_screen.dart';

class AddPlantChoiceScreen extends StatefulWidget {
  const AddPlantChoiceScreen({super.key});

  @override
  State<AddPlantChoiceScreen> createState() => _AddPlantChoiceScreenState();
}

class _AddPlantChoiceScreenState extends State<AddPlantChoiceScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filteredSpecies = obsVm.speciesDictionary.where((s) => s.polishName.toLowerCase().contains(_searchQuery.toLowerCase()) || s.latinName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Typ ewidencji okazu"), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.green.shade50, elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade200)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade600, child: const Icon(Icons.photo_camera, color: Colors.white)),
                  title: const Text("WERSJA DŁUGA (Pełna Morfologia)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Uruchamia aparat, GPS oraz pełną taksonomię cech anatomicznych."),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen())); },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, bottom: 12),
              child: Card(
                color: Colors.orange.shade50, elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.orange.shade600, child: const Icon(Icons.bolt, color: Colors.white)),
                  title: const Text("WERSJA SZYBKA (Wpis ekspresowy)", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Szybki zapis populacji w terenie bez wymogu opisu cech."),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickAddObservationScreen())); },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: TextField(decoration: const InputDecoration(hintText: "Szukaj w zbadanych gatunkach...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder(), isDense: true), onChanged: (v) => setState(() => _searchQuery = v)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredSpecies.length,
                itemBuilder: (ctx, i) {
                  final species = filteredSpecies[i];
                  return ListTile(
                    leading: const Icon(Icons.eco_outlined, color: Colors.teal),
                    title: Text(species.polishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(species.latinName, style: const TextStyle(fontStyle: FontStyle.italic)),
                    trailing: const Icon(Icons.flash_on, color: Colors.orange, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => QuickAddObservationScreen(preselectedSpecies: species)));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}