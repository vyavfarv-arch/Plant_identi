// lib/views/add_plant_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import 'camera_screen.dart';
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

    // Filtrowanie bazy atlasu gatunków na podstawie wpisanej frazy
    final filteredSpecies = obsVm.speciesDictionary.where((s) {
      return s.polishName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.latinName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Typ ewidencji okazu"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEKCJA A: Nowy gatunek (Pełna ścieżka terenowa)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.green.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.shade200)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade600, child: const Icon(Icons.photo_camera, color: Colors.white)),
                  title: const Text("Zupełnie NOWY gatunek rośliny", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Uruchamia aparat, koordynaty GPS i pełną specyfikację cech morfologicznych."),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text("SZYBKI ZAPIS (Wybierz znany już gatunek z atlasu):", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ),
            // Pasek wyszukiwania w atlasie
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Szukaj w zbadanych gatunkach (np. konwalia)...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            // Lista znanych gatunków do wyboru
            Expanded(
              child: filteredSpecies.isEmpty
                  ? const Center(child: Text("Brak pasujących gatunków w bazie.\nUżyj opcji powyżej, aby dodać nowy.", textAlign: CenterTextAlign.center, style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: filteredSpecies.length,
                itemBuilder: (ctx, i) {
                  final species = filteredSpecies[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: const Icon(Icons.eco_outlined, color: Colors.teal),
                    title: Text(species.polishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(species.latinName, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                    trailing: const Icon(Icons.flash_on, color: Colors.orange, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      // Otwieramy QuickAdd przekazując wybrany gatunek jako parametr startowy
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => QuickAddObservationScreen(preselectedSpecies: species),
                      ));
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