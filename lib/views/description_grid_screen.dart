import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import 'detail_description_screen.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Interfejs w postaci siatki zdjęć (Grid) reprezentujący okazy niekompletne.
 * Grupuje znalezione rośliny terenowe, które oczekują na identyfikację botaniczną,
 * opis taksonomii oraz cech siedliskowych przez użytkownika.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../viewmodels/observation_view_model.dart':
 * - Klasa [ObservationViewModel]: Służy do odczytu odfiltrowanej listy okazów niekompletnych.
 * * Z katalogu widoków:
 * - Ekran [DetailDescriptionScreen]: Wywoływany po dotknięciu kafelka siatki w celu opisu okazu.
 * ============================================================================
 */
class DescriptionGridScreen extends StatelessWidget {
  const DescriptionGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opisz Spotkane Rośliny')),
      body: SafeArea(child: Consumer<ObservationViewModel>(
        builder: (context, plantsVm, child) {
          final list = plantsVm.incompleteObservations;

          if (list.isEmpty) {
            return const Center(child: Text("Brak roślin do opisania!"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 zdjęcia w linii
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final obs = list[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs))
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade100, // Tło dla roślin bez zdjęcia
                    image: obs.photoPaths.isNotEmpty
                        ? DecorationImage(
                      image: FileImage(File(obs.photoPaths[0])),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  // Wyświetl ikonę, jeśli brak zdjęć
                  child: obs.photoPaths.isEmpty
                      ? const Icon(Icons.eco, color: Colors.green, size: 40)
                      : null,
                ),
              );
            },
          );
        },
      ),),
    );
  }
}