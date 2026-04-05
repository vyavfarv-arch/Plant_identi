import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/plants_view_model.dart';
import 'detail_description_screen.dart';

class DescriptionGridScreen extends StatelessWidget {
  const DescriptionGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opisz Spotkane Rośliny')),
      body: Consumer<PlantsViewModel>(
        builder: (context, plantsVm, child) {
          final list = plantsVm.incompleteObservations;

          if (list.isEmpty) {
            return const Center(child: Text("Brak roślin do opisania!"));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 zdjęcia w linii
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final obs = list[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailDescriptionScreen(observation: obs))
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(obs.photoPaths[0])),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}