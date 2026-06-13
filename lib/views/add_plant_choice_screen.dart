// lib/views/add_plant_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import 'camera_screen.dart';
import 'add_observation_screen.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Menu wyboru rodzaju ewidencji okazu terenowego. Udostępnia wyszukiwarkę
 * do szybkiego wpisu znanej rośliny lub duży przycisk dla rośliny nieznanej.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../viewmodels/observation_view_model.dart':
 * - Klasa [ObservationViewModel]: Służy do odczytu słownika gatunków (atlasu)
 * oraz filtrowania podpowiedzi wpisywanych przez użytkownika.
 * * Widoki:
 * - [AddObservationScreen]: Przekierowanie do szybkiej ścieżki (znana roślina).
 * - [CameraScreen]: Przekierowanie do seryjnych zdjęć detali (nieznana roślina).
 * ============================================================================
 */
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
    final filteredSpecies = obsVm.speciesDictionary.where((s) {
      return s.polishName.toLowerCase().contains(_searchQuery.toLowerCase()) || s.latinName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Rodzaj ewidencji okazu"), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: filteredSpecies.isEmpty
                  ? const Center(child: Text("Brak takiego gatunku w atlasie.\nUżyj zielonego przycisku na dole, aby dodać nowy okaz.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center))
                  : ListView.builder(
                itemCount: filteredSpecies.length,
                itemBuilder: (ctx, i) {
                  final species = filteredSpecies[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: const Icon(Icons.eco_outlined, color: Colors.teal),
                    title: Text(species.polishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(species.latinName, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      // KROK SZYBKI: 2-krokowy PageView (Zdjęcie -> Stan populacji)
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddObservationScreen(preselectedSpecies: species, forcedQuickMode: true)));
                    },
                  );
                },
              ),
            ),
            // DUŻY, PROMINENTNY ZIELONY PRZYCISK DLA WERSJI DŁUGIEJ (NIEZNANA ROŚLINA)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.grey.shade50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.photo_camera),
                label: const Text("Nieznana roślina", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () {
                  Navigator.pop(context);
                  // PRZEKIEROWANIE DO APARATU (Zbiór wielu zdjęć detali)
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}