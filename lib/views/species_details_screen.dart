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
import '../viewmodels/reminder_view_model.dart'; // DODANY IMPORT
import '../services/spatial_service.dart';
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
    final remVm = context.read<ReminderViewModel>(); // Słuchacz managera powiadomień

    // 1. Dynamiczne pobranie ewidencji okazów dla tego gatunku
    final List<PlantObservation> currentObservations = obsVm.completeObservations.where((o) {
      final spec = obsVm.getSpeciesById(o.speciesId);
      final String name = (spec?.polishName.isNotEmpty == true ? spec!.polishName : o.displayName).trim();
      final key = name.isEmpty ? "Nieznana roślina" : name;
      return key == commonName;
    }).toList();

    if (currentObservations.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. LOGIKA MATRYCY FENOLOGICZNEJ I BANKU ZDJĘĆ
    final Map<String, Map<String, Set<String>>> accumulatedTraitsByStage = {};
    final List<Map<String, String>> allPhotosWithStage = [];
    final String biologicalType = species?.biologicalType ?? "Zielne";
    final schema = SchemaGenerator.getForType(biologicalType);

    // Słownik gromadzenia dat surowców do obliczenia średniej
    final Map<String, List<HarvestSeason>> seasonsByMaterial = {};

    for (var obs in currentObservations) {
      final String stage = obs.phenologicalStage ?? "Nieokreślony etap";
      for (var path in obs.photoPaths) {
        allPhotosWithStage.add({'path': path, 'stage': stage});
      }
      accumulatedTraitsByStage.putIfAbsent(stage, () => {});
      final Map<String, Set<String>> stageMap = accumulatedTraitsByStage[stage]!;
      obs.characteristics.forEach((category, traits) {
        stageMap.putIfAbsent(category, () => {}).addAll(traits);
      });

      // Zbieranie kalendarzy zbiorów z poszczególnych wypraw terenowych okazu
      final harvestData = obs.customHarvestSeasons.isNotEmpty
          ? obs.customHarvestSeasons
          : (species?.harvestSeasons ?? []);

      for (var s in harvestData) {
        if (s.startDate != null && s.endDate != null) {
          seasonsByMaterial.putIfAbsent(s.material, () => []).add(s);
        }
      }
    }

    // 3. ALGORYTM BOTANICZNEGO UŚREDNIANIA DAT (Normalizacja do roku cyklu: 2026)
    final List<Map<String, dynamic>> calculatedAverageSeasons = [];
    final int targetCycleYear = 2026;

    seasonsByMaterial.forEach((material, list) {
      int totalStartMs = 0;
      int totalEndMs = 0;
      int count = list.length;

      for (var s in list) {
        // Normalizujemy do wspólnego roku, by uśredniać czysty dzień i miesiąc wegetacji
        final normalizedStart = DateTime(targetCycleYear, s.startDate!.month, s.startDate!.day);
        final normalizedEnd = DateTime(targetCycleYear, s.endDate!.month, s.endDate!.day);

        totalStartMs += normalizedStart.millisecondsSinceEpoch;
        totalEndMs += normalizedEnd.millisecondsSinceEpoch;
      }

      final avgStart = DateTime.fromMillisecondsSinceEpoch(totalStartMs ~/ count);
      final avgEnd = DateTime.fromMillisecondsSinceEpoch(totalEndMs ~/ count);

      calculatedAverageSeasons.add({
        'material': material,
        'startDate': avgStart,
        'endDate': avgEnd,
        'count': count,
      });
    });

    // 4. Mapowanie unikalnych obszarów
    final Set<String> observedAreaIds = {};
    final List<Releve> uniqueAreas = [];
    for (var obs in currentObservations) {
      if (obs.releveId != null) observedAreaIds.add(obs.releveId!);
      final spatialAreas = SpatialService.getAreasForPlant(releveVm.allReleves, obs);
      for (var a in spatialAreas) {
        observedAreaIds.add(a.id);
      }
    }
    for (var areaId in observedAreaIds) {
      try {
        final area = releveVm.allReleves.firstWhere((r) => r.id == areaId);
        uniqueAreas.add(area);
      } catch (_) {}
    }

    final df = DateFormat('dd.MM');

    return Scaffold(
      appBar: AppBar(
        title: Text(commonName),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(species?.latinName ?? "Brak nazwy łacińskiej", style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey, fontWeight: FontWeight.bold)),
            if (species != null && species!.family.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("Rodzina: ${species!.family}", style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
              ),
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
                          Positioned(
                            bottom: 6, left: 6, right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                              child: Text(item['stage']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
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
            const Divider(height: 30),

            // NOWA SEKCJA: FENOLOGICZNA ŚREDNIA ZBIORÓW Z PRZYCISKIEM PRZYPOMNIEŃ
            _sectionHeader("ŚREDNIE TERMINY ZBIORU SUROWCÓW (Z TERENU)"),
            if (calculatedAverageSeasons.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 4),
                child: Text("Brak zarejestrowanych terminów wegetacji surowców.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            else
              ...calculatedAverageSeasons.map((item) {
                final String mat = item['material'];
                final DateTime start = item['startDate'];
                final DateTime end = item['endDate'];
                final int sampleCount = item['count'];

                return Card(
                  color: Colors.green.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.calendar_today, color: Colors.green),
                    title: Text(mat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("Uśredniony fenologicznie czas: ${df.format(start)} - ${df.format(end)} (Próba z $sampleCount okazów)"),
                    // REWOLUCJA: Bezpośredni zapytanie powiadomienia z poziomu karty specyfikacji
                    trailing: IconButton(
                      icon: const Icon(Icons.notification_add, color: Colors.orange),
                      tooltip: "Aktywuj asystenta poszukiwań i powiadomienie",
                      onPressed: () async {
                        await remVm.addHarvestReminder(
                            plantName: commonName,
                            material: mat,
                            startDate: start,
                            endDate: end,
                            relatedId: species?.speciesID ?? currentObservations.first.id
                        );
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: Colors.amber.shade900,
                          content: Text("Asystent czasowy aktywny. Przypomnę o zbiorze surowca ($mat) dnia ${df.format(start)}!"),
                        ));
                      },
                    ),
                  ),
                );
              }),
            const Divider(height: 40),

            _sectionHeader("OBSZARY (PŁATY) WYSTĘPOWANIA"),
            if (uniqueAreas.isEmpty)
              const Text("Ten gatunek nie został powiązany z żadnym płatem fitosocjologicznym.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
            else
              ...uniqueAreas.map((area) => Card(
                color: Colors.indigo.shade50,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.layers, color: Colors.indigo),
                  title: Text(area.commonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Typ jednostki: ${area.type}"),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: area))),
                ),
              )),
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
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.teal),
                      tooltip: "Podgląd karty okazu",
                      onPressed: () => PlantCardView.show(context, obs),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs)));
                        } else if (val == 'delete') {
                          obsVm.deleteObservation(obs.id);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edytuj szczegóły okazu')),
                        const PopupMenuItem(value: 'delete', child: Text('Usuń rekord okazu', style: TextStyle(color: Colors.red))),
                      ],
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
}