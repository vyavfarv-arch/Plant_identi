// lib/views/form_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../models/plant_observation.dart';
import '../models/description_schema.dart';
import '../services/identification_assistant_service.dart';
import '../services/spatial_service.dart';

class FormScreen extends StatefulWidget {
  final PlantObservation observation;
  const FormScreen({super.key, required this.observation});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final Map<String, List<String>> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    _selectedValues.addAll(widget.observation.characteristics);
  }

  // FIX WARNINGA: Usunięto nieużywaną, zdublowaną strukturę metody _detectAnomalies

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>();
    final schema = SchemaGenerator.getForType(widget.observation.tempBiologicalType ?? "Zielne");

    final activeReleveList = releveVm.allReleves.where((r) =>
        SpatialService.isPointInPolygon(LatLng(widget.observation.latitude, widget.observation.longitude), r.points)
    ).toList();
    final activeArea = activeReleveList.isNotEmpty ? activeReleveList.first : null;

    final temporaryObservation = PlantObservation(
      id: widget.observation.id, photoPaths: widget.observation.photoPaths,
      latitude: widget.observation.latitude, longitude: widget.observation.longitude,
      timestamp: DateTime.now(), characteristics: _selectedValues,
      speciesId: widget.observation.speciesId, localName: widget.observation.localName,
    );

    final selectedSpecies = obsVm.getSpeciesById(widget.observation.speciesId);
    final anomalies = IdentificationAssistantService.checkAnomalies(temporaryObservation, selectedSpecies);
    final suggestions = IdentificationAssistantService.getSuggestions(
      currentTraits: _selectedValues, activeArea: activeArea, speciesDictionary: obsVm.speciesDictionary,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Identyfikacja i Opis Cech')),
      body: SafeArea(
        child: Column(
          children: [
            if (anomalies.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border(bottom: BorderSide(color: Colors.red.shade200)),
                ),
                width: double.infinity, padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text("OSTRZEŻENIE O ANOMALII:\n${anomalies.join('\n')}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900))),
                  ],
                ),
              ),

            if (suggestions.isNotEmpty && widget.observation.speciesId == null)
              ExpansionTile(
                backgroundColor: Colors.teal.shade50,
                leading: const Icon(Icons.psychology_outlined, color: Colors.teal),
                title: Text("Asystent Identyfikacji: Wykryto ${suggestions.length} sugestii", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.teal)),
                children: suggestions.take(3).map((s) => ListTile(
                  dense: true, leading: const Icon(Icons.spa_outlined, color: Colors.teal, size: 18),
                  title: Text(s.species.polishName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Morfologia: ${(s.morphologicalScore*100).toStringAsFixed(0)}% | Siedlisko: ${(s.ecologicalScore*100).toStringAsFixed(0)}%"),
                )).toList(),
              ),

            if (widget.observation.photoPaths.isNotEmpty)
              Container(
                height: 100, color: Colors.black.withOpacity(0.02), padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 12),
                  itemCount: widget.observation.photoPaths.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(widget.observation.photoPaths[i]), width: 80, height: 80, fit: BoxFit.cover)),
                  ),
                ),
              ),
            const Divider(height: 1),

            Expanded(
              child: ListView.builder(
                itemCount: schema.length,
                itemBuilder: (context, index) {
                  final category = schema[index];
                  return ExpansionTile(
                    leading: CircleAvatar(backgroundColor: Colors.green, child: Text(category.number, style: const TextStyle(color: Colors.white))),
                    title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: category.subCategories.entries.map((sub) => _buildSubCategorySection(category, sub.key, sub.value)).toList(),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16), width: double.infinity,
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _zapiszFinalnie, child: const Text("ZAPISZ OBSZAR TERENOWY", style: TextStyle(color: Colors.white))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategorySection(DescriptionCategory category, String subTitle, List<String> options) {
    final List<String> dynamicOptions = List.from(options);
    if (_selectedValues[subTitle] != null) {
      for (var customOpt in _selectedValues[subTitle]!) {
        if (!dynamicOptions.contains(customOpt)) dynamicOptions.add(customOpt);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subTitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ...dynamicOptions.map((opt) {
                final isSelected = _selectedValues[subTitle]?.contains(opt) ?? false;
                final hasImage = category.referenceImages?.containsKey(opt) ?? false;
                final imagePath = hasImage ? category.referenceImages![opt]! : "";
                final description = category.imageDescriptions?[opt] ?? "";

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasImage)
                      GestureDetector(
                        onTap: () => _showImagePreview(context, imagePath, opt, description),
                        child: Container(
                          width: 85, height: 65, margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 2)),
                          child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedValues[subTitle] == null) _selectedValues[subTitle] = [];
                          if (isSelected) _selectedValues[subTitle]!.remove(opt);
                          else _selectedValues[subTitle]!.add(opt);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: isSelected ? Colors.green : Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400)),
                        child: Text(opt, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ],
                );
              }).toList(),
              ActionChip(
                backgroundColor: Colors.amber.shade50, side: BorderSide(color: Colors.amber.shade300),
                avatar: const Icon(Icons.add, size: 16, color: Colors.orange),
                label: const Text("Inna cecha...", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                onPressed: () => _showCustomTraitDialog(subTitle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imagePath, String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, automaticallyImplyLeading: false, actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]),
            ConstrainedBox(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4), child: Image.asset(imagePath, fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Opis cechy:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showCustomTraitDialog(String subTitle) {
    final TextEditingController customCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nowa cecha dla: $subTitle"),
        content: TextField(controller: customCtrl, autofocus: true, decoration: const InputDecoration(hintText: "np. zniekształcone przez galasówki", border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              final text = customCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() { _selectedValues.putIfAbsent(subTitle, () => []).add(text); });
                Navigator.pop(ctx);
              }
            },
            child: const Text("DODAJ"),
          )
        ],
      ),
    );
  }

  void _zapiszFinalnie() async {
    final finalObs = PlantObservation(
      id: widget.observation.id,
      releveId: widget.observation.releveId,
      speciesId: widget.observation.speciesId,
      localName: widget.observation.localName,
      subspecies: widget.observation.subspecies,
      tempBiologicalType: widget.observation.tempBiologicalType,
      photoPaths: widget.observation.photoPaths,
      latitude: widget.observation.latitude,
      longitude: widget.observation.longitude,
      timestamp: widget.observation.timestamp,
      observationDate: widget.observation.observationDate,
      phenologicalStage: widget.observation.phenologicalStage,
      abundance: widget.observation.abundance,
      coverage: widget.observation.coverage,
      vitality: widget.observation.vitality,
      certainty: widget.observation.certainty,
      idDoubts: widget.observation.idDoubts,
      keyMorphologicalTraits: widget.observation.keyMorphologicalTraits,
      confusingSpecies: widget.observation.confusingSpecies,
      characteristicFeature: widget.observation.characteristicFeature,
      customHarvestSeasons: widget.observation.customHarvestSeasons,
      characteristics: Map.from(_selectedValues),
    );

    await context.read<ObservationViewModel>().addObservation(finalObs);
    if (!mounted) return;
    context.read<ObservationViewModel>().reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}