// lib/views/species_card_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_species.dart';
import '../models/plant_observation.dart';
import '../models/description_schema.dart';

class SpeciesCardView {
  static void show(BuildContext context, PlantSpecies species, List<PlantObservation> speciesObservations) {
    final schema = SchemaGenerator.getForType(species.biologicalType);

    // LOGIKA KUMULACJI: Łączymy cechy ze wszystkich zarejestrowanych historycznie okazów
    final Map<String, Set<String>> accumulatedTraits = {};
    final List<String> allPhotoPaths = [];

    for (var obs in speciesObservations) {
      if (obs.photoPaths.isNotEmpty) {
        allPhotoPaths.addAll(obs.photoPaths);
      }
      obs.characteristics.forEach((category, traits) {
        accumulatedTraits.putIfAbsent(category, () => {}).addAll(traits);
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 15),
              Text(species.polishName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
              Text(species.latinName, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
              Text("Rodzina: ${species.family.isEmpty ? 'Brak' : species.family}", style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
              const Divider(height: 24),

              // Zbiorcza galeria zdjęć z różnych wypraw i okazów
              if (allPhotoPaths.isNotEmpty) ...[
                const Text("Skumulowany bank zdjęć gatunku:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, itemCount: allPhotoPaths.length,
                    itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(allPhotoPaths[i]), width: 140, fit: BoxFit.cover))),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              _sectionHeader("SKUMULOWANA SPECYFIKACJA MORFOLOGICZNA"),
              _buildAccumulatedTraitsWidget(accumulatedTraits, schema),

              _sectionHeader("AMPLITUDA EKOLOGICZNA"),
              _infoItem(Icons.science, "Preferowany zakres pH", "${species.prefPhMin?.toStringAsFixed(1) ?? '?'} - ${species.prefPhMax?.toStringAsFixed(1) ?? '?'}"),
              _infoItem(Icons.landscape, "Typy siedlisk", species.prefAreaTypes.isEmpty ? "-" : species.prefAreaTypes.join(", ")),
              _infoItem(Icons.water_drop, "Gospodarka wodna", species.prefWaterDynamics.isEmpty ? "-" : species.prefWaterDynamics.join(", ")),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildAccumulatedTraitsWidget(Map<String, Set<String>> traits, List<DescriptionCategory> schema) {
    List<Widget> rows = [];
    for (var cat in schema) {
      List<String> combinedValues = [];
      for (var subTitle in cat.subCategories.keys) {
        if (traits.containsKey(subTitle)) {
          combinedValues.addAll(traits[subTitle]!);
        }
      }

      if (combinedValues.isNotEmpty) {
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.brightness_high_outlined, color: Colors.teal, size: 18),
              const SizedBox(width: 12),
              Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 14), children: [TextSpan(text: "${cat.title}: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: combinedValues.join(", "))]))),
            ],
          ),
        ));
      }
    }

    if (rows.isEmpty) return const Text("Brak zarejestrowanych cech morfologicznych we wszystkich okazach.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    return Column(children: rows);
  }

  static Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.1)));
  static Widget _infoItem(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Icon(icon, color: Colors.teal.shade300, size: 18), const SizedBox(width: 12), RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 14), children: [TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: value)]))]));
}