// lib/views/species_card_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_species.dart';
import '../models/plant_observation.dart';
import '../models/description_schema.dart';

class PhotoWithStage {
  final String path;
  final String stage;
  PhotoWithStage({required this.path, required this.stage});
}

class SpeciesCardView {
  static void show(BuildContext context, PlantSpecies species, List<PlantObservation> speciesObservations) {
    final String biologicalType = species.biologicalType;
    final schema = SchemaGenerator.getForType(biologicalType);

    // BARDZO WAŻNA ZMIANA: Dwupoziomowa mapa grupowania [Etap -> [Kategoria -> Cechy]]
    final Map<String, Map<String, Set<String>>> accumulatedTraitsByStage = {};
    final List<PhotoWithStage> allPhotosWithStage = [];

    for (var obs in speciesObservations) {
      final String stage = obs.phenologicalStage ?? "Nieokreślony etap";

      // Gromadzenie zdjęć z przypisanym etapem do wizualnego kontekstu
      for (var path in obs.photoPaths) {
        allPhotosWithStage.add(PhotoWithStage(path: path, stage: stage));
      }

      // Inicjalizacja poziomu etapu fenologicznego
      accumulatedTraitsByStage.putIfAbsent(stage, () => {});
      final Map<String, Set<String>> stageMap = accumulatedTraitsByStage[stage]!;

      // Grupowanie cech morfologicznych wewnątrz tego etapu
      obs.characteristics.forEach((category, traits) {
        stageMap.putIfAbsent(category, () => {}).addAll(traits);
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

              // SKUMULOWANY BANK ZDJĘĆ Z BADGE'AMI ETAPU FENOLOGICZNEGO
              if (allPhotosWithStage.isNotEmpty) ...[
                _sectionHeader("BANK ZDJĘĆ GATUNKU W ROZWOJU"),
                const SizedBox(height: 6),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allPhotosWithStage.length,
                    itemBuilder: (ctx, i) {
                      final item = allPhotosWithStage[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(item.path), width: 150, height: 140, fit: BoxFit.cover)
                            ),
                            Positioned(
                              bottom: 6, left: 6, right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  item.stage,
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _sectionHeader("SPECYFIKACJA MORFOLOGICZNA (ETAPY FENOLOGICZNE)"),
              _buildPhenologicalTraitsWidget(accumulatedTraitsByStage, schema),
              const SizedBox(height: 20),

              _sectionHeader("AMPLITUDA EKOLOGICZNA GATUNKU"),
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

  /// Buduje interfejs podzielony na sekcje rozwijane dla każdego etapu fenologicznego
  static Widget _buildPhenologicalTraitsWidget(Map<String, Map<String, Set<String>>> traitsByStage, List<DescriptionCategory> schema) {
    if (traitsByStage.isEmpty) {
      return const Text("Brak zarejestrowanych cech morfologicznych we wszystkich okazach.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }

    return Column(
      children: traitsByStage.entries.map((stageEntry) {
        final String stageName = stageEntry.key;
        final Map<String, Set<String>> categoryMap = stageEntry.value;

        List<Widget> traitRows = [];

        for (var cat in schema) {
          List<String> combinedValues = [];
          for (var subTitle in cat.subCategories.keys) {
            if (categoryMap.containsKey(subTitle)) {
              combinedValues.addAll(categoryMap[subTitle]!);
            }
          }

          if (combinedValues.isNotEmpty) {
            traitRows.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.brightness_high_outlined, color: Colors.teal, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                      child: RichText(
                          text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                              children: [
                                TextSpan(text: "${cat.title}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: combinedValues.join(", "))
                              ]
                          )
                      )
                  ),
                ],
              ),
            ));
          }
        }

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.teal.withOpacity(0.02),
          child: ExpansionTile(
            initiallyExpanded: stageName == "Kwitnienie" || traitsByStage.length == 1,
            leading: const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.teal),
            title: Text(stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
            subtitle: Text("Liczba zaobserwowanych cech: ${categoryMap.length}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: traitRows.isEmpty
                    ? const Text("Brak szczegółów morfologicznych dla tego etapu.", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey))
                    : Column(children: traitRows),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  static Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.1)));
  static Widget _infoItem(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Icon(icon, color: Colors.teal.shade300, size: 18), const SizedBox(width: 12), RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 14), children: [TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: value)]))]));
}