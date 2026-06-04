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
import '../widgets/ellenberg_matrix_card.dart';
import '../widgets/species_harvest_averages.dart';
import 'plant_card_view.dart';
import 'releve_details_screen.dart';
import 'detail_description_screen.dart';

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

    // --- NOWY ALGORYTM BOTANICZNEGO WZORCA GATUNKU (PRÓG FREKWENCJI 80%) ---
    final Map<String, List<PlantObservation>> obsByStage = {};
    final List<Map<String, String>> allPhotosWithStage = [];
    final Map<String, List<HarvestSeason>> seasonsByMaterial = {};
    final String biologicalType = species?.biologicalType ?? "Zielne";
    final schema = SchemaGenerator.getForType(biologicalType);

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

    // Wyliczanie statystycznego wektora cech diagnostycznych ze stałością >= 80%
    final Map<String, Map<String, Set<String>>> patternTraitsByStage = {};

    obsByStage.forEach((stage, obsList) {
      final int totalObsInStage = obsList.length;
      final Map<String, Map<String, int>> traitCounts = {}; // kategoria -> (cecha -> licznik)

      for (var obs in obsList) {
        obs.characteristics.forEach((category, traits) {
          traitCounts.putIfAbsent(category, () => {});
          for (var trait in traits) {
            traitCounts[category]![trait] = (traitCounts[category]![trait] ?? 0) + 1;
          }
        });
      }

      final Map<String, Set<String>> filteredCategoryMap = {};
      traitCounts.forEach((category, traitMap) {
        final Set<String> matchingTraits = {};
        traitMap.forEach((trait, count) {
          // KRYTERIUM STAŁOŚCI: Cecha wchodzi do opisu tylko jeśli ma min. 80% wystąpień na tym etapie
          if ((count / totalObsInStage) >= 0.8) {
            matchingTraits.add(trait);
          }
        });
        if (matchingTraits.isNotEmpty) filteredCategoryMap[category] = matchingTraits;
      });

      patternTraitsByStage[stage] = filteredCategoryMap;
    });

    // Średnie terminy zbioru surowców
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
                  scrollDirection: Axis.horizontal, itemCount: allPhotosWithStage.length,
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

            _sectionHeader("WZORZEC MORFOLOGICZNY GATUNKU (STAŁOŚĆ CECH ≥80% W ETAPACH)"),
            _buildPhenologicalTraitsWidget(patternTraitsByStage, schema),
            const Divider(height: 30),

            if (species != null) ...[
              _sectionHeader("AMPLITUDA EKOLOGICZNA (WSKAŹNIKI ELLENBERGA)"),
              EllenbergMatrixCard(species: species!),
              const Divider(height: 30),
            ],

            _sectionHeader("ŚREDNIE TERMINY ZBIORU SUROWCÓW (Z TERENU)"),
            SpeciesHarvestAverages(commonName: commonName, speciesId: species?.speciesID, calculatedAverageSeasons: calculatedAverageSeasons),
            const Divider(height: 40),

            _sectionHeader("OBSZARY WYSTĘPOWANIA"),
            if (uniqueAreas.isEmpty) const Text("Brak powiązanych płatów.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)) else ...uniqueAreas.map((area) => Card(color: Colors.indigo.shade50, margin: const EdgeInsets.symmetric(vertical: 4), child: ListTile(leading: const Icon(Icons.layers, color: Colors.indigo), title: Text(area.commonName, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Typ jednostki: ${area.type}"), trailing: const Icon(Icons.chevron_right, size: 20), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: area)))))),
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

  static Widget _buildPhenologicalTraitsWidget(Map<String, Map<String, Set<String>>> traitsByStage, List<DescriptionCategory> schema) {
    if (traitsByStage.isEmpty) return const Text("Brak powtarzalnych cech diagnostycznych dla tego gatunku.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    return Column(
      children: traitsByStage.entries.map((stageEntry) {
        final String stageName = stageEntry.key;
        final Map<String, Set<String>> categoryMap = stageEntry.value;
        List<Widget> traitRows = [];

        for (var cat in schema) {
          List<String> combinedValues = [];
          for (var subTitle in cat.subCategories.keys) {
            if (categoryMap.containsKey(subTitle)) combinedValues.addAll(categoryMap[subTitle]!);
          }
          if (combinedValues.isNotEmpty) {
            traitRows.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_outlined, color: Colors.teal, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 13), children: [TextSpan(text: "${cat.title}: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: combinedValues.join(", "))]))),
                ],
              ),
            ));
          }
        }

        return Card(
          elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: Colors.teal.withOpacity(0.02),
          child: ExpansionTile(
            initiallyExpanded: stageName == "Kwitnienie" || traitsByStage.length == 1,
            leading: const Icon(Icons.star_border, size: 20, color: Colors.teal),
            title: Text(stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
            subtitle: Text("Cechy spełniające kryterium 80%: ${categoryMap.length}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            children: [Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 12), child: traitRows.isEmpty ? const Text("Brak cech o wysokiej powtarzalności dla tego etapu fenologicznego.", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)) : Column(children: traitRows))],
          ),
        );
      }).toList(),
    );
  }

  static Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.1)));
}