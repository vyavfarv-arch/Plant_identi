import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../models/plant_observation.dart';
import '../models/description_schema.dart';

class FormScreen extends StatefulWidget {
  final PlantObservation observation;
  const FormScreen({super.key, required this.observation});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final Map<String, List<String>> _selectedValues = {};

  @override
  Widget build(BuildContext context) {
    final schema = SchemaGenerator.getForType(
        widget.observation.biologicalType ?? "Zielne");

    return Scaffold(
      appBar: AppBar(title: Text('Opis: ${widget.observation.biologicalType}')),
      body: Column(
        children: [
          // Podgląd zrobionych zdjęć pobierany z ObservationViewModel
          Consumer<ObservationViewModel>(
            builder: (context, obsVm, child) {
              if (obsVm.currentPhotoPaths.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 120,
                color: Colors.black.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: obsVm.currentPhotoPaths.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(obsVm.currentPhotoPaths[i]),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: schema.length,
              itemBuilder: (context, index) {
                final category = schema[index];
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(category.number,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(category.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: category.subCategories.entries.map((sub) {
                    return _buildSubCategorySection(category, sub.key, sub.value);
                  }).toList(),
                );
              },
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSubCategorySection(DescriptionCategory category, String subTitle, List<String> options) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subTitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((opt) {
              final isSelected = _selectedValues[subTitle]?.contains(opt) ?? false;
              final hasImage = category.referenceImages?.containsKey(opt) ?? false;
              final imagePath = hasImage ? category.referenceImages![opt]! : "";

              return GestureDetector(
                onLongPress: () {
                  if (hasImage) {
                    _showImagePreview(context, imagePath, opt);
                  }
                },
                onTap: () {
                  setState(() {
                    if (_selectedValues[subTitle] == null) {
                      _selectedValues[subTitle] = [];
                    }
                    if (isSelected) {
                      _selectedValues[subTitle]!.remove(opt);
                    } else {
                      _selectedValues[subTitle]!.add(opt);
                    }
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasImage)
                      Container(
                        width: 80, height: 60,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: isSelected ? Colors.green : Colors.transparent,
                              width: 3
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey.shade400
                        ),
                      ),
                      child: Text(opt,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 12
                          )
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imagePath, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(fontSize: 16)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
              ],
            ),
            Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(40.0),
                child: Text("Brak pliku w folderze assets/ref/", textAlign: TextAlign.center),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Zdjęcie poglądowe", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: _zapiszFinalnie,
        child: const Text("ZAPISZ OBSERWACJĘ TERENOWĄ",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _zapiszFinalnie() async { // KLUCZOWE: Dodano async
    final now = DateTime.now();

    final finalObs = PlantObservation(
      id: widget.observation.id,
      photoPaths: widget.observation.photoPaths,
      latitude: widget.observation.latitude,
      longitude: widget.observation.longitude,
      timestamp: widget.observation.timestamp,
      characteristics: Map.from(_selectedValues),
      biologicalType: widget.observation.biologicalType,
      family: widget.observation.family,
      abundance: widget.observation.abundance,
      coverage: widget.observation.coverage,
      vitality: widget.observation.vitality,
      areaPurity: widget.observation.areaPurity,
      observationDate: now,
    );

    // Zapisujemy TYLKO RAZ z await
    await context.read<ObservationViewModel>().addObservation(finalObs);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Zapisano!"),
        content: const Text("Roślina została dodana do listy oczekujących na opis."),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ObservationViewModel>().reset();
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}