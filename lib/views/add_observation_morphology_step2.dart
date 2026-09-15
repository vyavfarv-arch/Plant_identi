// lib/views/add_observation_morphology_step2.dart
import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/description_schema.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Widżet reprezentujący Krok 2 w trybie szczegółowej ewidencji. Generuje
 * dynamiczne drzewo kategorii cech morfologicznych dopasowane do wybranego
 * typu biologicznego oraz filtru fenologicznego taksonu.
 *
 * Sposób prezentacji:
 * - główne DescriptionCategory są sortowane po polu number,
 * - każda subCategory jest prezentowana jako siatka 4 elementów w rzędzie,
 * - krótkie kliknięcie nazwy cechy zaznacza/odznacza cechę,
 * - przytrzymanie obrazu lub nazwy przez 1,5 s otwiera okno informacyjne.
 * ============================================================================
 */
class AddObservationMorphologyStep2 extends StatelessWidget {
  final String? selectedType;
  final String? selectedPhenology;
  final Map<String, List<String>> morphologyValues;
  final Function(String, String, bool) onTraitToggled;

  const AddObservationMorphologyStep2({
    super.key,
    required this.selectedType,
    this.selectedPhenology,
    required this.morphologyValues,
    required this.onTraitToggled,
  });

  @override
  Widget build(BuildContext context) {
    final schema = List<DescriptionCategory>.from(
      SchemaGenerator.getForType(
        selectedType ?? "Zielne",
        phenologicalStage: selectedPhenology,
      ),
    )
      ..sort((a, b) {
        final aNumber = int.tryParse(a.number);
        final bNumber = int.tryParse(b.number);

        if (aNumber != null && bNumber != null) {
          return aNumber.compareTo(bNumber);
        }
        return a.number.compareTo(b.number);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Zaznacz widoczne cechy morfologiczne",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: schema.length,
            itemBuilder: (context, index) {
              final category = schema[index];

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                ),
                title: Text(
                  category.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: category.subCategories.entries.map((sub) {
                  final options = List<String>.from(sub.value);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.key,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: options.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 118,
                          ),
                          itemBuilder: (context, optionIndex) {
                            final opt = options[optionIndex];
                            final isSelected =
                                morphologyValues[sub.key]?.contains(opt) ?? false;
                            final imagePath = category.referenceImages?[opt];
                            final description =
                                category.imageDescriptions?[opt] ?? "";

                            return _TraitGridItem(
                              title: opt,
                              imagePath: imagePath,
                              isSelected: isSelected,
                              onTap: () => onTraitToggled(
                                sub.key,
                                opt,
                                !isSelected,
                              ),
                              onHold: () => _showTraitPreview(
                                context,
                                imagePath: imagePath,
                                title: opt,
                                description: description,
                              ),
                            );
                          },
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

  void _showTraitPreview(
    BuildContext context, {
    required String? imagePath,
    required String title,
    required String description,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            if (imagePath != null && imagePath.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      "Nie udało się załadować assetu w podglądzie: "
                      "$imagePath. Błąd: $error",
                    );
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Opis cechy diagnostycznej:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isNotEmpty
                        ? description
                        : "Brak dodatkowego opisu dla tej cechy.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Pojedyncza komórka siatki.
///
/// Przytrzymanie przez dokładnie 1,5 sekundy jest obsługiwane własnym Timerem,
/// zamiast standardowego onLongPress (który uruchamia się znacznie wcześniej).
class _TraitGridItem extends StatefulWidget {
  final String title;
  final String? imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHold;

  const _TraitGridItem({
    required this.title,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
    required this.onHold,
  });

  @override
  State<_TraitGridItem> createState() => _TraitGridItemState();
}

class _TraitGridItemState extends State<_TraitGridItem> {
  static const Duration _holdDuration = Duration(milliseconds: 1000);

  Timer? _holdTimer;
  bool _holdTriggered = false;

  void _startHoldTimer() {
    _holdTriggered = false;
    _holdTimer?.cancel();

    _holdTimer = Timer(_holdDuration, () {
      _holdTriggered = true;
      widget.onHold();
    });
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _handleTapUp() {
    _cancelHoldTimer();

    // Jeśli uruchomił się hold, puszczenie palca nie może dodatkowo zaznaczyć cechy.
    if (!_holdTriggered) {
      widget.onTap();
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null && widget.imagePath!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasImage)
          Expanded(
            child: _HoldArea(
              onPointerDown: _startHoldTimer,
              onPointerUp: () {
                // Kliknięcie obrazu samo w sobie niczego nie zaznacza.
                // Obraz służy do podglądu informacji po 1,5 s przytrzymania.
                _cancelHoldTimer();
              },
              onPointerCancel: _cancelHoldTimer,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSelected
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    widget.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint(
                        "Nie udało się załadować assetu: ${widget.imagePath}. "
                        "Opcja: ${widget.title}. Błąd: $error",
                      );
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        else
          const Spacer(),
        const SizedBox(height: 5),
        _HoldArea(
          onPointerDown: _startHoldTimer,
          onPointerUp: _handleTapUp,
          onPointerCancel: _cancelHoldTimer,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected ? Colors.green : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected
                    ? Colors.green
                    : Colors.grey.shade400,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : Colors.black87,
                fontSize: 10.0,
                fontWeight:
                    widget.isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Własny timer startuje już w onTapDown. GestureDetector nadal poprawnie
/// anuluje kliknięcie, jeżeli gest zmieni się np. w przewijanie listy.
class _HoldArea extends StatelessWidget {
  final Widget child;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUp;
  final VoidCallback onPointerCancel;

  const _HoldArea({
    required this.child,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onPointerDown(),
      onTapUp: (_) => onPointerUp(),
      onTapCancel: onPointerCancel,
      child: child,
    );
  }
}
