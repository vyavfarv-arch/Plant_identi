// lib/views/browse_plants_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant_observation.dart';
import '../models/plant_species.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import 'species_details_screen.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Ekran katalogu i atlasu zebranych gatunków flory. Grupuje kompletne obserwacje
 * według unikalnej nazwy zwyczajowej, zabezpiecza przed dublowaniem wpisów,
 * aplikuje filtry katalogu (rodzina, czas znalezienia, tagi) i przekierowuje użytkownika
 * do karty szczegółowej taksonu.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z katalogu '../models/':
 * - Klasy [PlantObservation], [PlantSpecies]: Encje danych do filtrowania i mapowania list.
 * * Z katalogu '../viewmodels/':
 * - Klasa [ObservationViewModel]: Dostarcza kompletną listę zaobserwowanych okazów oraz słownik.
 * - Klasa [SearchFilterViewModel]: Służy do odczytu i modyfikacji filtrów dat, rodzin oraz tagów.
 * * Z katalogu widoków:
 * - Ekran [SpeciesDetailsScreen]: Wywoływany w celu wyświetlenia głębokiej karty botanicznej gatunku.
 * ============================================================================
 */
class BrowsePlantsScreen extends StatelessWidget {
  const BrowsePlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

    // MAPOWANIE I GRUPOWANIE: Zabezpieczenie przed dublowaniem rekordów
    final Map<String, List<PlantObservation>> groupedByCommonName = {};
    final Map<String, PlantSpecies?> representativeSpecies = {};

    for (var obs in obsVm.completeObservations) {
      final species = obsVm.getSpeciesById(obs.speciesId);
      final String name = (species?.polishName.isNotEmpty == true ? species!.polishName : obs.displayName).trim();
      final key = name.isEmpty ? "Nieznana roślina" : name;

      // APLIKOWANIE FILTRÓW GLOBALNYCH
      if (filterVm.selectedFamilies.isNotEmpty) {
        if (species == null || !filterVm.selectedFamilies.contains(species.family)) continue;
      }
      if (filterVm.filterDateRange != null) {
        final date = obs.observationDate ?? obs.timestamp;
        if (date.isBefore(filterVm.filterDateRange!.start) ||
            date.isAfter(
              filterVm.filterDateRange!.end.add(const Duration(days: 1)),
            )) {
          continue;
        }
      }

      if (filterVm.selectedTags.isNotEmpty) {
        if (species == null) continue;

        final speciesTagsLower =
            species.tags.map((tag) => tag.toLowerCase()).toSet();

        // W obrębie filtra tagów obowiązuje OR:
        // gatunek przechodzi, jeżeli ma przynajmniej jeden zaznaczony tag.
        final hasSelectedTag = filterVm.selectedTags.any(
          (tag) => speciesTagsLower.contains(tag.toLowerCase()),
        );

        if (!hasSelectedTag) continue;
      }

      groupedByCommonName.putIfAbsent(key, () => []).add(obs);
      if (species != null && !representativeSpecies.containsKey(key)) {
        representativeSpecies[key] = species;
      }
    }

    final sortedKeys = groupedByCommonName.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog'),
        actions: [
          IconButton(
            tooltip: "Filtry",
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _hasActiveCatalogFilters(filterVm)
                  ? Colors.orange
                  : null,
            ),
            onPressed: () => _showCatalogFilters(
              context,
              obsVm,
              filterVm,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: sortedKeys.isEmpty
            ? const Center(child: Text("Brak gatunków spełniających kryteria filtrów."))
            : ListView.builder(
          itemCount: sortedKeys.length,
          itemBuilder: (ctx, index) {
            final String nameKey = sortedKeys[index];
            final List<PlantObservation> speciesObservations = groupedByCommonName[nameKey]!;
            final PlantSpecies? speciesInfo = representativeSpecies[nameKey];

            final firstObsWithPhoto = speciesObservations.firstWhere((o) => o.photoPaths.isNotEmpty, orElse: () => speciesObservations.first);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: firstObsWithPhoto.photoPaths.isNotEmpty ? FileImage(File(firstObsWithPhoto.photoPaths.first)) : null,
                  child: firstObsWithPhoto.photoPaths.isEmpty ? const Icon(Icons.eco, color: Colors.teal) : null,
                ),
                title: Text(nameKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "${speciesInfo?.latinName ?? 'Brak nazwy łacińskiej'} (${speciesObservations.length} ${speciesObservations.length == 1 ? 'okaz' : 'okazów'})",
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                // FIX: Usunięto niedozwolony parametr 'observations' zgodnie z nowym konstruktorem
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpeciesDetailsScreen(
                      commonName: nameKey,
                      species: speciesInfo,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _hasActiveCatalogFilters(SearchFilterViewModel filterVm) {
    return filterVm.selectedFamilies.isNotEmpty ||
        filterVm.filterDateRange != null ||
        filterVm.selectedTags.isNotEmpty;
  }

  Future<void> _showCatalogFilters(
    BuildContext context,
    ObservationViewModel obsVm,
    SearchFilterViewModel filterVm,
  ) async {
    final families = [...obsVm.uniqueFamilies]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final tags = obsVm.uniqueTags;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final dateRange = filterVm.filterDateRange;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Filtry katalogu",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              filterVm.resetAllFilters();
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.filter_alt_off),
                            label: const Text("Wyczyść"),
                          ),
                        ],
                      ),
                      const Divider(),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.teal,
                        ),
                        title: const Text(
                          "Czas znalezienia gatunków",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          dateRange == null
                              ? "Dowolny termin"
                              : "${_formatDate(dateRange.start)} – ${_formatDate(dateRange.end)}",
                        ),
                        trailing: dateRange == null
                            ? const Icon(Icons.chevron_right)
                            : IconButton(
                                tooltip: "Usuń zakres dat",
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  filterVm.setFilterDateRange(null);
                                  setSheetState(() {});
                                },
                              ),
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange: filterVm.filterDateRange,
                          );

                          if (picked != null) {
                            filterVm.setFilterDateRange(picked);
                            setSheetState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        "Rodziny",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (families.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Brak rodzin do filtrowania.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            itemCount: families.length,
                            itemBuilder: (context, index) {
                              final family = families[index];
                              return CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(family),
                                value: filterVm.selectedFamilies
                                    .contains(family),
                                onChanged: (_) {
                                  filterVm.toggleFamilyFilter(family);
                                  setSheetState(() {});
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 8),
                      const Text(
                        "Tagi",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: tags.isEmpty
                            ? const Center(
                                child: Text(
                                  "Nie dodano jeszcze żadnych tagów do gatunków.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.map((tag) {
                                    final selected =
                                        filterVm.selectedTags.contains(tag);

                                    return FilterChip(
                                      label: Text(tag),
                                      selected: selected,
                                      avatar: const Icon(
                                        Icons.label_outline,
                                        size: 18,
                                      ),
                                      onSelected: (_) {
                                        filterVm.toggleTagFilter(tag);
                                        setSheetState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text("ZASTOSUJ"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "$day.$month.${date.year}";
  }
}
