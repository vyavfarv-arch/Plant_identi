// lib/views/plant_card_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/plant_observation.dart';
import '../models/harvest_season.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/observation_view_model.dart';
import '../services/spatial_service.dart';
import 'releve_details_screen.dart';

class PlantCardView {
  static void show(BuildContext context, PlantObservation obs) {
    final obsVm = context.read<ObservationViewModel>();
    final species = obsVm.getSpeciesById(obs.speciesId);

    // Pobieramy kalendarz: najpierw indywidualny okazu, jeśli pusty - z gatunku
    final harvestData = obs.customHarvestSeasons.isNotEmpty
        ? obs.customHarvestSeasons
        : (species?.harvestSeasons ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              Text(species?.latinName ?? "Brak nazwy łacińskiej", style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
              const Divider(),
              _buildPhotoGallery(obs),
              const SizedBox(height: 20),

              _sectionHeader("1. Pozycja systematyczna"),
              _infoItem(Icons.account_tree, "Rodzina", species?.family ?? "-"),
              _infoItem(Icons.subtitles, "Podgatunek/Odmiana", obs.subspecies ?? "-"),

              _sectionHeader("2. Ocena surowca i kondycja"),
              _infoItem(Icons.category, "Typ surowca", species?.biologicalType ?? "-"),
              _infoItem(Icons.filter_vintage, "Etap fenologiczny", obs.phenologicalStage ?? "-"),
              _infoItem(Icons.analytics, "Ilościowość", obs.abundance ?? "-"),

              // NOWA SEKCJA: KALENDARZ ZBIORÓW
              _sectionHeader("3. Terminy zbioru surowców"),
              if (harvestData.isEmpty)
                const Padding(padding: EdgeInsets.only(left: 35), child: Text("Brak zdefiniowanych terminów.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
              else
                ...harvestData.map((h) => _harvestItem(h)),

              _sectionHeader("4. Amplituda ekologiczna (ML)"),
              _infoItem(Icons.science, "Zakres pH", "${species?.prefPhMin?.toStringAsFixed(1) ?? '?'} - ${species?.prefPhMax?.toStringAsFixed(1) ?? '?'}"),
              _infoItem(Icons.landscape, "Typy obszaru", _joinList(species?.prefAreaTypes)),

              _sectionHeader("5. Lokalizacja w płatach"),
              _buildReleveLinks(context, obs),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _harvestItem(HarvestSeason h) {
    final df = DateFormat('dd.MM');
    final dateRange = (h.startDate != null && h.endDate != null)
        ? "${df.format(h.startDate!)} - ${df.format(h.endDate!)}"
        : "Cały rok";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: h.reminderEnabled ? Colors.orange : Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(h.material, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(dateRange, style: const TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }

  static String _joinList(List<String>? list) => (list == null || list.isEmpty) ? "-" : list.join(", ");
  static Widget _buildHandle() => Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))));
  static Widget _buildHeader(PlantObservation obs) => Text(obs.displayName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green));
  static Widget _buildPhotoGallery(PlantObservation obs) => SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: obs.photoPaths.length, itemBuilder: (ctx, i) => Padding(padding: const EdgeInsets.only(right: 12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(obs.photoPaths[i]), width: 200, fit: BoxFit.cover)))));
  static Widget _sectionHeader(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)));
  static Widget _infoItem(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Colors.green, size: 20), const SizedBox(width: 15), Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 14), children: [TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: value)])))]));

  static Widget _buildReleveLinks(BuildContext context, PlantObservation obs) {
    return Builder(builder: (context) {
      final releveVm = context.read<ReleveViewModel>();
      final foundInReleves = SpatialService.getAreasForPlant(releveVm.allReleves, obs);
      if (foundInReleves.isEmpty) return const Text("Poza obszarami.");
      return Column(children: foundInReleves.map((r) => ListTile(dense: true, leading: const Icon(Icons.layers, color: Colors.indigo), title: Text(r.commonName), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))))).toList());
    });
  }
}