// lib/views/plant_card_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/spatial_service.dart';
import 'releve_details_screen.dart';

class PlantCardView {
  static void show(BuildContext context, PlantObservation obs) {
    // 1. ZMIANA: Pobieramy ViewModel i odszukujemy Słownikowy model Gatunku!
    final obsVm = context.read<ObservationViewModel>();
    final species = obsVm.getSpeciesById(obs.speciesId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              _buildHandle(),
              const SizedBox(height: 20),
              _buildHeader(obs),
              Text(
                species?.latinName ?? "Brak nazwy łacińskiej",
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const Divider(),
              _buildPhotoGallery(obs),
              const SizedBox(height: 20),

              _sectionHeader("1. Pozycja systematyczna"),
              _infoItem(Icons.account_tree, "Rodzina", species?.family ?? "-"),
              _infoItem(Icons.subtitles, "Podgatunek/Odmiana", obs.subspecies ?? "-"),

              _sectionHeader("2. Ocena surowca i siedliska"),
              _infoItem(Icons.category, "Typ surowca", species?.biologicalType ?? "-"),
              _infoItem(Icons.cleaning_services, "Czystość obszaru", obs.areaPurity ?? "-"),
              _infoItem(Icons.analytics, "Ilościowość", obs.abundance ?? "-"),
              _infoItem(Icons.favorite, "Żywotność", obs.vitality ?? "-"),

              _sectionHeader("3. Preferencje środowiskowe (ML Data)"),
              _infoItem(Icons.science, "Zakres pH", "${species?.prefPhMin?.toStringAsFixed(1) ?? '?'} - ${species?.prefPhMax?.toStringAsFixed(1) ?? '?'}"),
              _infoItem(
                  Icons.landscape,
                  "Podłoże",
                  (species != null && species.prefSubstrate.isNotEmpty) ? species.prefSubstrate.join(", ") : "-"
              ),
              _infoItem(Icons.water_drop, "Wilgotność", _translateMoisture(species?.prefMoisture)),
              _infoItem(Icons.wb_sunny, "Nasłonecznienie", _translateSun(species?.prefSunlight)),

              _sectionHeader("4. Cechy i Wykorzystanie"),
              _infoItem(Icons.verified, "Stopień pewności", obs.certainty ?? "-"),
              _infoItem(Icons.handyman, "Zastosowanie", species?.plantUsage ?? "-"),
              _infoItem(Icons.home, "Hodowla", species?.cultivation ?? "-"),

              _sectionHeader("5. Lokalizacja w płatach"),
              _buildReleveLinks(context, obs),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHandle() => Center(
    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
  );

  static Widget _buildHeader(PlantObservation obs) => Text(
    obs.displayName,
    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
  );

  static Widget _buildPhotoGallery(PlantObservation obs) => SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: obs.photoPaths.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(obs.photoPaths[i]), width: 240, fit: BoxFit.cover),
        ),
      ),
    ),
  );

  static Widget _buildReleveLinks(BuildContext context, PlantObservation obs) {
    return Builder(builder: (context) {
      final releveVm = context.read<ReleveViewModel>();
      final foundInReleves = SpatialService.getAreasForPlant(releveVm.allReleves, obs);

      if (foundInReleves.isEmpty) return const Text("Roślina poza zdefiniowanymi obszarami.");
      return Column(
        children: foundInReleves.map((r) => ListTile(
          dense: true,
          leading: const Icon(Icons.layers, color: Colors.indigo),
          title: Text("${r.type}: ${r.commonName}"),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r)));
          },
        )).toList(),
      );
    });
  }

  static Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
  );

  static Widget _infoItem(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 15),
        Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 15), children: [
          TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ]))),
      ],
    ),
  );

  static String _translateMoisture(double? v) {
    if (v == null) return "-";
    return ["Sucho", "Świeżo", "Wilgotno", "Mokro"][v.round()];
  }

  static String _translateSun(double? v) {
    if (v == null) return "-";
    return ["Pełne słońce", "Przewaga słońca", "Półcień", "Przewaga cienia", "Cień"][v.round()];
  }
}