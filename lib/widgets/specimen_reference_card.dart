// lib/views/widgets/specimen_reference_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/plant_observation.dart';

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
          _buildPhotos(),
          _buildBadges(),
          _buildTraitsList(),
        ],
      ),
    );
  }

  Widget _buildPhotos() {
    if (observation.photoPaths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: observation.photoPaths.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(observation.photoPaths[i]), width: 80, height: 80, fit: BoxFit.cover),
          ),
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
        spacing: 6,
        children: observation.characteristics.entries.expand((e) =>
            e.value.map((v) => Chip(
              label: Text("${e.key}: $v", style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.white,
            ))
        ).toList(),
      ),
    );
  }
}