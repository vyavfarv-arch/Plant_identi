// lib/views/species_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plant_species.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';
import '../models/harvest_season.dart';
import '../models/description_schema.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/spatial_service.dart';
import '../services/ecological_matching_service.dart';
import '../widgets/ellenberg_matrix_card.dart';
import '../widgets/species_harvest_averages.dart';
import 'plant_card_view.dart';
import 'releve_details_screen.dart';
import 'detail_description_screen.dart';
import 'all_species_map.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Zaawansowana karta botaniczna gatunku flory. Zaktualizowana o system
 * detekcji i oznaczania płatów wykazujących anomalie preferencji wskaźnikowych
 * na bazie końcowego wyniku numerycznego (score) z silnika ekologicznego.
 * Dostosowana do inteligentnej filtracji organów we wzorcu morfologicznym.
 * ============================================================================
 */
class SpeciesDetailsScreen extends StatelessWidget {
  final String commonName;
  final PlantSpecies? species;

  const SpeciesDetailsScreen({
    super.key,
    required this.commonName,
    required this.species,
  });

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>();

    final List<PlantObservation> currentObservations = obsVm.completeObservations.where((o) {
      final spec = obsVm.getSpeciesById(o.speciesId);
      final String name = (spec?.polishName.isNotEmpty == true ? spec!.polishName : o.displayName).trim();
      return name.toLowerCase() == commonName.toLowerCase();
    }).toList();

    if (currentObservations.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Map<String, List<PlantObservation>> obsByStage = {};
    final List<Map<String, String>> allPhotosWithStage = [];
    final Map<String, List<HarvestSeason>> seasonsByMaterial = {};
    final String biologicalType = species?.biologicalType ?? "Zielne";

    for (var obs in currentObservations) {
      final String stage = obs.phenologicalStage ?? "Nieokreślony etap";
      for (var path in obs.photoPaths) {
        allPhotosWithStage.add({'path': path, 'stage': stage});
      }
      obsByStage.putIfAbsent(stage, () => []).add(obs);

      final harvestData = obs.customHarvestSeasons.isNotEmpty ? obs.customHarvestSeasons : (species?.harvestSeasons ?? []);
      for (var s in harvestData) {
        if (s.startDate != null && s.endDate != null) seasonsByMaterial.putIfAbsent(s.material, () => []).add(s);
      }
    }

    // WZORZEC MORFOLOGICZNY GATUNKU:
    // stałość cechy liczona jest osobno dla każdej subCategory.
    //
    // Mianownik = wyłącznie obserwacje, w których dana subCategory
    // została faktycznie opisana (istnieje i zawiera co najmniej jedną cechę).
    //
    // Przykład:
    // - 10 obserwacji gatunku,
    // - "Typ łodygi" opisano tylko w 5,
    // - "zielna" wystąpiła w 4 z tych 5,
    // => 4 / 5 = 80%, więc cecha trafia do wzorca.
    final Map<String, Map<String, int>> globalTraitCounts = {};
    final Map<String, int> describedObservationCounts = {};

    for (var obs in currentObservations) {
      obs.characteristics.forEach((subCategory, traits) {
        // Pusta lista nie oznacza faktycznie opisanej podkategorii.
        if (traits.isEmpty) {
          return;
        }

        describedObservationCounts[subCategory] =
            (describedObservationCounts[subCategory] ?? 0) + 1;

        globalTraitCounts.putIfAbsent(subCategory, () => {});

        // Set zapobiega przypadkowemu podwójnemu naliczeniu tej samej cechy
        // w obrębie jednego okazu.
        for (final trait in traits.toSet()) {
          globalTraitCounts[subCategory]![trait] =
              (globalTraitCounts[subCategory]![trait] ?? 0) + 1;
        }
      });
    }

    final Map<String, Set<String>> patternTraits = {};

    globalTraitCounts.forEach((subCategory, traitMap) {
      final int describedCount =
          describedObservationCounts[subCategory] ?? 0;

      if (describedCount == 0) {
        return;
      }

      final Set<String> matchingTraits = {};

      traitMap.forEach((trait, count) {
        final double occurrenceRate = count / describedCount;

        if (occurrenceRate >= 0.8) {
          matchingTraits.add(trait);
        }
      });

      if (matchingTraits.isNotEmpty) {
        patternTraits[subCategory] = matchingTraits;
      }
    });

    final List<Map<String, dynamic>> calculatedAverageSeasons = [];
    seasonsByMaterial.forEach((material, list) {
      int totalStartMs = 0; int totalEndMs = 0; int count = list.length;
      for (var s in list) {
        totalStartMs += DateTime(2026, s.startDate!.month, s.startDate!.day).millisecondsSinceEpoch;
        totalEndMs += DateTime(2026, s.endDate!.month, s.endDate!.day).millisecondsSinceEpoch;
      }
      calculatedAverageSeasons.add({'material': material, 'startDate': DateTime.fromMillisecondsSinceEpoch(totalStartMs ~/ count), 'endDate': DateTime.fromMillisecondsSinceEpoch(totalEndMs ~/ count), 'count': count});
    });

    final Set<String> observedAreaIds = {};
    final List<Releve> uniqueAreas = [];
    for (var obs in currentObservations) {
      if (obs.releveId != null) observedAreaIds.add(obs.releveId!);
      for (var a in SpatialService.getAreasForPlant(releveVm.allReleves, obs)) { observedAreaIds.add(a.id); }
    }
    for (var areaId in observedAreaIds) {
      try { uniqueAreas.add(releveVm.allReleves.firstWhere((r) => r.id == areaId)); } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: Text(commonName), backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(species?.latinName ?? "Brak nazwy łacińskiej", style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey, fontWeight: FontWeight.bold)),
            if (species != null && species!.family.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("Rodzina: ${species!.family}", style: const TextStyle(fontSize: 14, color: Colors.blueGrey))),
            const Divider(height: 30),

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
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item['path']!), width: 150, height: 140, fit: BoxFit.cover)),
                          Positioned(bottom: 6, left: 6, right: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(item['stage']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            _sectionHeader("WZORZEC MORFOLOGICZNY GATUNKU"),
            _buildMorphologicalPatternWidget(patternTraits, biologicalType),
            const Divider(height: 30),

            if (species != null) ...[
              _buildEllenbergExpansion(species!),
              const Divider(height: 30),
            ],

            _sectionHeader("ŚREDNIE TERMINY ZBIORU SUROWCÓW "),
            SpeciesHarvestAverages(
              commonName: commonName,
              speciesId: species?.speciesID,
              calculatedAverageSeasons: calculatedAverageSeasons,
            ),
            const Divider(height: 30),

            if (species != null &&
                ((species!.plantUsage?.trim().isNotEmpty ?? false) ||
                    (species!.cultivation?.trim().isNotEmpty ?? false))) ...[
              _buildUsageAndCultivationExpansion(species!),
              const Divider(height: 30),
            ],

            _sectionHeader("OBSZARY WYSTĘPOWANIA"),
            if (uniqueAreas.isEmpty)
              const Text(
                "Brak powiązanych płatów.",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    "POKAŻ WSZYSTKIE NA MAPIE (${uniqueAreas.length})",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal,
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllSpeciesMapScreen(
                        speciesName: commonName,
                        areas: uniqueAreas,
                        observations: currentObservations,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...uniqueAreas.map((area) {
                final isAreaMismatch =
                    EcologicalMatchingService.isSevereMismatch(area, species);

                return Card(
                  color: isAreaMismatch
                      ? Colors.amber.shade50
                      : Colors.indigo.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.layers,
                          color: isAreaMismatch
                              ? Colors.orange.shade800
                              : Colors.indigo,
                        ),
                        if (isAreaMismatch)
                          const Positioned(
                            right: -6,
                            top: -6,
                            child: Icon(
                              Icons.warning_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            area.commonName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAreaMismatch)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "[ANOMALIA]",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      isAreaMismatch
                          ? "Wskaźniki Ellenberga tego gatunku kłócą się z tym siedliskiem!"
                          : "Typ jednostki: ${area.type}",
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReleveDetailsScreen(releve: area),
                      ),
                    ),
                  ),
                );
              }),
            ],
            const Divider(height: 40),

            _sectionHeader("HISTORIA SPOTKANYCH OKAZÓW"),
            ...currentObservations.map((obs) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.history_toggle_off, color: Colors.teal),
                title: Text("Okaz z dnia: ${DateFormat('yyyy-MM-dd').format(obs.observationDate ?? obs.timestamp)}"),
                subtitle: Text("Witalność: ${obs.vitality ?? '-'} | Ilościowość BB: ${obs.abundance ?? '-'}"),
                trailing: Wrap(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.teal), onPressed: () => PlantCardView.show(context, obs)),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs)));
                        else if (val == 'delete') obsVm.deleteObservation(obs.id);
                      },
                      itemBuilder: (ctx) => [const PopupMenuItem(value: 'edit', child: Text('Edytuj szczegóły okazu')), const PopupMenuItem(value: 'delete', child: Text('Usuń rekord okazu', style: TextStyle(color: Colors.red)))],
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageAndCultivationExpansion(PlantSpecies species) {
    final String usage = species.plantUsage?.trim() ?? "";
    final String cultivation = species.cultivation?.trim() ?? "";

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: Colors.teal.withOpacity(0.02),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(
          Icons.menu_book_outlined,
          color: Colors.teal,
        ),
        title: const Text(
          "WYKORZYSTANIE I UPRAWA",
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (usage.isNotEmpty)
            _speciesTextSection(
              icon: Icons.auto_stories_outlined,
              title: "Zastosowanie",
              text: usage,
            ),
          if (usage.isNotEmpty && cultivation.isNotEmpty)
            const Divider(height: 24),
          if (cultivation.isNotEmpty)
            _speciesTextSection(
              icon: Icons.agriculture_outlined,
              title: "Uprawa",
              text: cultivation,
            ),
        ],
      ),
    );
  }

  Widget _speciesTextSection({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.teal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.1),
      ),
    );
  }

  /// Wyświetla wzorzec morfologiczny gatunku bez podziału na fenologię.
  /// Dane są uporządkowane według kolejności DescriptionCategory.number,
  /// a następnie według kolejności subCategories z description_schema.dart.
  static Widget _buildMorphologicalPatternWidget(
    Map<String, Set<String>> patternTraits,
    String biologicalType,
  ) {
    if (patternTraits.isEmpty) {
      return const Text(
        "Brak cech występujących w co najmniej 80% obserwacji tego gatunku.",
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    final schema = List<DescriptionCategory>.from(
      SchemaGenerator.getForType(biologicalType),
    )
      ..sort((a, b) {
        final aNumber = int.tryParse(a.number);
        final bNumber = int.tryParse(b.number);

        if (aNumber != null && bNumber != null) {
          return aNumber.compareTo(bNumber);
        }

        return a.number.compareTo(b.number);
      });

    final List<Widget> categoryWidgets = [];

    for (final category in schema) {
      final List<Widget> subCategoryRows = [];

      for (final subEntry in category.subCategories.entries) {
        final subCategoryName = subEntry.key;
        final matchingTraits = patternTraits[subCategoryName];

        if (matchingTraits == null || matchingTraits.isEmpty) {
          continue;
        }

        // Zachowujemy kolejność wartości z description_schema.dart.
        final orderedTraits = subEntry.value
            .where((trait) => matchingTraits.contains(trait))
            .toList();

        // Zabezpieczenie na wypadek starszych danych, których nie ma już w schemacie.
        for (final trait in matchingTraits) {
          if (!orderedTraits.contains(trait)) {
            orderedTraits.add(trait);
          }
        }

        subCategoryRows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  color: Colors.teal,
                  size: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: "$subCategoryName: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: orderedTraits.join(", "),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (subCategoryRows.isEmpty) {
        continue;
      }

      categoryWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 1,
            color: Colors.teal.withOpacity(0.02),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.teal,
              ),
              title: Text(
                category.title,
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              children: subCategoryRows,
            ),
          ),
        ),
      );
    }

    if (categoryWidgets.isEmpty) {
      return const Text(
        "Brak cech występujących w co najmniej 80% obserwacji tego gatunku.",
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: categoryWidgets,
    );
  }

  /// Cała amplituda ekologiczna jest jedną rozwijaną sekcją.
  static Widget _buildEllenbergExpansion(PlantSpecies species) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: Colors.teal.withOpacity(0.02),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(
          Icons.eco_outlined,
          color: Colors.teal,
        ),
        title: const Text(
          "AMPLITUDA EKOLOGICZNA (WSKAŹNIKI ELLENBERGA)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
            letterSpacing: 1.0,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          EllenbergMatrixCard(species: species),
        ],
      ),
    );
  }
}
