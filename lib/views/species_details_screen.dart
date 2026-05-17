// lib/views/species_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plant_species.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';
import '../models/description_schema.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/spatial_service.dart';
import 'plant_card_view.dart';
import 'releve_details_screen.dart';
import 'detail_description_screen.dart';

class SpeciesDetailsScreen extends StatelessWidget {
  final String commonName;
  final List<PlantObservation> observations;
  final PlantSpecies? species;

  const SpeciesDetailsScreen({
    super.key,
    required this.commonName,
    required this.observations,
    required this.species,
  });

  @override
  Widget build(BuildContext context) {
    final releveVm = context.read<ReleveViewModel>();
    final obsVm = context.read<ObservationViewModel>();

    final Map<String, Set<String>> accumulatedTraits = {};
    final List<String> allPhotoPaths = [];
    final String biologicalType = species?.biologicalType ?? "Zielne";
    final schema = SchemaGenerator.getForType(biologicalType);

    for (var obs in observations) {
      if (obs.photoPaths.isNotEmpty) {
        allPhotoPaths.addAll(obs.photoPaths);
      }
      obs.characteristics.forEach((category, traits) {
        accumulatedTraits.putIfAbsent(category, () => {}).addAll(traits);
      });
    }

    final Set<String> observedAreaIds = {};
    final List<Releve> uniqueAreas = [];

    for (var obs in observations) {
      if (obs.releveId != null) {
        observedAreaIds.add(obs.releveId!);
      }
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

            if (allPhotoPaths.isNotEmpty) ...[
              _sectionHeader("BANK ZDJĘĆ GATUNKOWYCH (${allPhotoPaths.length})"),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allPhotoPaths.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(allPhotoPaths[i]), width: 160, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],

            _sectionHeader("SKUMULOWANA SPECYFIKACJA MORFOLOGICZNA"),
            _buildAccumulatedTraitsWidget(accumulatedTraits, schema),
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
            ...observations.map((obs) => Card(
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

  Widget _buildAccumulatedTraitsWidget(Map<String, Set<String>> traits, List<DescriptionCategory> schema) {
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
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(text: "${cat.title}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: combinedValues.join(", ")),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
      }
    }

    if (rows.isEmpty) {
      return const Text("Brak wprowadzonych cech morfologicznych we wszystkich zebranych okazach.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }
    return Column(children: rows);
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 12),
    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal, letterSpacing: 1.1)),
  );
}