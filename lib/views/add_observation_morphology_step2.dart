// lib/views/widgets/add_observation_morphology_step2.dart
import 'package:flutter/material.dart';
import '../../models/description_schema.dart';

class AddObservationMorphologyStep2 extends StatelessWidget {
  final String? selectedType;
  final Map<String, List<String>> morphologyValues;
  final Function(String, String, bool) onTraitToggled;

  const AddObservationMorphologyStep2({
    super.key,
    required this.selectedType,
    required this.morphologyValues,
    required this.onTraitToggled,
  });

  @override
  Widget build(BuildContext context) {
    final schema = SchemaGenerator.getForType(selectedType ?? "Zielne");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("Zaznacz widoczne cechy morfologiczne", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: schema.length,
            itemBuilder: (context, index) {
              final category = schema[index];
              return ExpansionTile(
                leading: CircleAvatar(backgroundColor: Colors.green, child: Text(category.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                title: Text(category.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: category.subCategories.entries.map((sub) {
                  final List<String> dynamicOptions = List.from(sub.value);
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub.key, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: dynamicOptions.map((opt) {
                            final isSelected = morphologyValues[sub.key]?.contains(opt) ?? false;
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
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 2)
                                      ),
                                      child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey))
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () => onTraitToggled(sub.key, opt, !isSelected),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: isSelected ? Colors.green : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400)
                                    ),
                                    child: Text(opt, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showImagePreview(BuildContext context, String imagePath, String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Opis cechy diagnostycznej:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
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
}