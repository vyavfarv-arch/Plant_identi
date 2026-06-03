// lib/widgets/ellenberg_matrix_card.dart
import 'package:flutter/material.dart';
import '../models/plant_species.dart';

class EllenbergMatrixCard extends StatelessWidget {
  final PlantSpecies species;
  const EllenbergMatrixCard({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow("L - Wymagania świetlne (1-9)", species.ellenbergL, 1, 9),
        _buildRow("F - Wilgotność siedliska (1-12)", species.ellenbergF, 1, 12),
        _buildRow("R - Odczyn podłoża / pH (1-9)", species.ellenbergR, 1, 9),
        _buildRow("N - Zasobność w Azot (1-9)", species.ellenbergN, 1, 9),
        _buildRow("T - Temperatura mikrostanowiska (1-9)", species.ellenbergT, 1, 9),
        _buildRow("K - Kontynentalizm ekosystemu (1-9)", species.ellenbergK, 1, 9),
        _buildRow("S - Tolerancja na zasolenie (0-9)", species.ellenbergS, 0, 9),
        if (species.prefPhMin != null && species.prefPhMax != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4),
            child: Text(
              "Widełki pH gleby z klucza: ${species.prefPhMin!.toStringAsFixed(1)} - ${species.prefPhMax!.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
      ],
    );
  }

  Widget _buildRow(String title, Map<int, int> currentMap, int min, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4, runSpacing: 4,
            children: List.generate(max - min + 1, (index) {
              final val = min + index;
              final state = currentMap[val] ?? 0;
              Color bg = Colors.grey.shade100;
              Color border = Colors.grey.shade300;
              Color text = Colors.black38;
              Widget? icon;

              if (state == 1) {
                bg = Colors.teal.shade50; border = Colors.teal.shade200; text = Colors.teal.shade900;
              } else if (state == 2) {
                bg = Colors.teal.shade600; border = Colors.teal.shade800; text = Colors.white;
                icon = const Icon(Icons.star, size: 8, color: Colors.amber);
              }

              return Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 1.2), borderRadius: BorderRadius.circular(4)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text("$val", style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
                    if (icon != null) Positioned(top: 1, right: 1, child: icon),
                  ],
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}