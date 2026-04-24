import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../viewmodels/releve_view_model.dart'; // ZMIANA: Nowy ViewModel
import '../services/spatial_service.dart';    // ZMIANA: Nowy serwis do geometrii
import 'releve_details_screen.dart';

class PlantCardView {
  static void show(BuildContext context, PlantObservation obs) {
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
                obs.latinName ?? "Brak nazwy łacińskiej",
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const Divider(),
              _buildPhotoGallery(obs),
              const SizedBox(height: 20),
              _sectionHeader("1. Pozycja systematyczna"),
              _infoItem(Icons.account_tree, "Rodzina", obs.family ?? "-"),
              _infoItem(Icons.label, "Rodzaj", obs.genus ?? "-"),
              _infoItem(Icons.eco, "Gatunek", obs.species ?? "-"),
              _sectionHeader("2. Dane fitosocjologiczne"),
              _infoItem(Icons.layers, "Warstwa", obs.phytosociologicalLayer ?? "-"),
              _infoItem(Icons.analytics, "Ilościowość", obs.abundance ?? "-"),
              _infoItem(Icons.people_alt, "Towarzyskość", obs.areaPurity ?? "-"),
              _infoItem(Icons.favorite, "Żywotność", obs.vitality ?? "-"),
              _sectionHeader("3. Cechy charakterystyczne i pewność"),
              _infoItem(Icons.verified, "Stopień pewności", obs.certainty ?? "-"),
              _infoItem(Icons.psychology, "Wątpliwości", obs.idDoubts ?? "-"),
              _infoItem(Icons.star, "Cecha kluczowa", obs.characteristicFeature ?? "-"),
              _sectionHeader("4. Wykorzystanie i Hodowla"),
              _infoItem(Icons.handyman, "Zastosowanie", obs.plantUsage ?? "-"),
              _infoItem(Icons.home, "Hodowla", obs.cultivation ?? "-"),
              _sectionHeader("5. Lokalizacja w płatach"),
              _buildReleveLinks(context, obs), // Wywołanie poprawionej metody
              const SizedBox(height: 15),
              _sectionHeader("Cechy z terenu"),
              _buildFieldCharacteristics(obs),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- ELEMENTY BUDUJĄCE INTERFEJS ---

  static Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40, height: 5,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static Widget _buildHeader(PlantObservation obs) {
    return Row(
      children: [
        Expanded(
          child: Text(
            obs.displayName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
        if (obs.phytosociologicalStatus != null)
          Chip(label: Text(obs.phytosociologicalStatus!, style: const TextStyle(fontSize: 10))),
      ],
    );
  }

  static Widget _buildPhotoGallery(PlantObservation obs) {
    return SizedBox(
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
  }

  static Widget _buildReleveLinks(BuildContext context, PlantObservation obs) {
    return Builder(builder: (context) {
      // ZMIANA: Pobieramy dane z ReleveViewModel
      final releveVm = context.read<ReleveViewModel>();

      // ZMIANA: Używamy SpatialService do znalezienia obszarów dla rośliny
      final foundInReleves = SpatialService.getAreasForPlant(releveVm.allReleves, obs);

      if (foundInReleves.isEmpty) {
        return const Text("Roślina poza zdefiniowanymi obszarami.");
      }
      return Column(
        children: foundInReleves.map((r) => ListTile(
          dense: true,
          leading: const Icon(Icons.layers, color: Colors.indigo),
          // ZMIANA: r.name -> r.commonName
          title: Text("${r.type}: ${r.commonName}"),
          subtitle: Text("Naukowo: ${r.phytosociologicalName}"),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () {
            Navigator.pop(context); // Zamknij kartę (bottom sheet)
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r)));
          },
        )).toList(),
      );
    });
  }
  static Widget _buildFieldCharacteristics(PlantObservation obs) {
    if (obs.characteristics.isEmpty) return const Text("Brak dodatkowych cech.");

    return Column(
      children: obs.characteristics.entries.map((e) {
        // Łączymy listę wybranych cech w jeden ciąg tekstowy
        String valuesText = e.value.join(", ");
        return _infoItem(Icons.check_circle_outline, e.key, valuesText);
      }).toList(),
    );
  }

  static Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
    );
  }

  static Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 15),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}