// lib/widgets/specimen_reference_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_observation.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Wizualna karta kontekstu okazu zebranego w terenie. Renderuje sekcję
 * rozwijaną (ExpansionTile) zawierającą horyzontalną miniaturową galerię zdjęć
 * z obsługą swobodnego zoomu (InteractiveViewer), odznaki parametrów populacji
 * oraz pigułki (Chips) oznaczonych cech morfologicznych.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/plant_observation.dart':
 * - Klasa [PlantObservation]: Obiekt źródłowy, z którego wyciągane są ścieżki
 * plików zdjęciowych, wskaźniki witalności, obfitości i dynamiczne mapy cech.
 * ============================================================================
 */
class SpecimenReferenceCard extends StatelessWidget {
  final PlantObservation observation;

  const SpecimenReferenceCard({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey.shade50,
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.remove_red_eye, color: Colors.blueGrey),
        title: Text(
          "KONTEKST OKAZU: ${observation.localName ?? 'Brak nazwy'}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14),
        ),
        subtitle: const Text("Dane zebrane w terenie", style: TextStyle(fontSize: 11)),
        children: [
          _buildPhotos(context), // Przekazujemy context do obsługi okien modalnych dialogu
          _buildBadges(),
          _buildTraitsList(),
        ],
      ),
    );
  }

  Widget _buildPhotos(BuildContext context) {
    if (observation.photoPaths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: observation.photoPaths.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            // POPRAWKA: Kliknięcie wywołuje powiększenie InteractiveViewer
            onTap: () => _showEnlargedImage(context, observation.photoPaths[i]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(observation.photoPaths[i]),
                width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0, // Swobodny 4-krotny zoom morfologiczny detali
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54, radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _badge("Witalność", observation.vitality, Colors.orange),
          _badge("Obfitość", observation.abundance, Colors.blue),
          _badge("Pokrycie", observation.coverage, Colors.purple),
        ],
      ),
    );
  }

  Widget _badge(String label, String? value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      Text(value ?? "-", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    ],
  );

  Widget _buildTraitsList() {
    if (observation.characteristics.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 6, runSpacing: 4,
        children: observation.characteristics.entries.expand((e) =>
            e.value.map((v) => Chip(
              label: Text("${e.key}: $v", style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact, backgroundColor: Colors.white,
            ))
        ).toList(),
      ),
    );
  }
}