// lib/views/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../models/plant_species.dart'; // Import modelu gatunku
import 'plant_card_view.dart';
import 'releve_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showPlants = true;
  // Przechowujemy zbiór ID wybranych gatunków do wyświetlenia
  final Set<String> _selectedSpeciesIds = {};

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>();

    // Filtrowanie markerów na podstawie wybranych gatunków
    Set<Marker> markers = {};
    if (_showPlants) {
      markers = obsVm.allObservations.where((o) {
        // Jeśli nic nie wybrano, pokazujemy wszystkie (domyślnie)
        // Jeśli wybrano konkretne ID, pokazujemy tylko te
        if (_selectedSpeciesIds.isEmpty) return true;
        return _selectedSpeciesIds.contains(o.speciesId);
      }).map((obs) {
        return Marker(
          markerId: MarkerId('plant_${obs.id}'),
          position: LatLng(obs.latitude, obs.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => PlantCardView.show(context, obs),
        );
      }).toSet();
    }

    Set<Polygon> polygons = releveVm.allReleves.where((r) => r.points.isNotEmpty).map((r) {
      return Polygon(
        polygonId: PolygonId(r.id),
        points: r.points,
        fillColor: Colors.indigo.withOpacity(0.4),
        strokeColor: Colors.indigo,
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa Terenowa"),
        actions: [
          // Przełącznik widoczności warstwy roślin
          IconButton(
            icon: Icon(_showPlants ? Icons.visibility : Icons.visibility_off),
            tooltip: "Pokaż/Ukryj rośliny",
            onPressed: () => setState(() => _showPlants = !_showPlants),
          ),
          // NOWY PRZYCISK FILTRA
          IconButton(
            icon: Icon(Icons.filter_alt, color: _selectedSpeciesIds.isNotEmpty ? Colors.orange : null),
            onPressed: () => _showFilterDialog(context, obsVm),
          ),
        ],
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 10),
          markers: markers,
          polygons: polygons,
          mapType: MapType.hybrid,
          myLocationEnabled: true,
        ),
      ),
    );
  }

  // Budowanie okna dialogowego z hierarchią Rodzina -> Gatunki
  void _showFilterDialog(BuildContext context, ObservationViewModel obsVm) {
    // Zmienna przechowująca zapytanie wyszukiwania wewnątrz dialogu
    String dialogSearchQuery = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 1. Grupowanie i filtrowanie danych
          final Map<String, List<PlantSpecies>> filteredFamilies = {};

          for (var s in obsVm.speciesDictionary) {
            final fam = s.family.isEmpty ? "Inne / Nieokreślone" : s.family;

            // Logika sprawdzania, czy gatunek lub rodzina pasuje do wyszukiwania
            final matchesSearch = dialogSearchQuery.isEmpty ||
                fam.toLowerCase().contains(dialogSearchQuery.toLowerCase()) ||
                s.polishName.toLowerCase().contains(dialogSearchQuery.toLowerCase()) ||
                s.latinName.toLowerCase().contains(dialogSearchQuery.toLowerCase());

            if (matchesSearch) {
              filteredFamilies.putIfAbsent(fam, () => []).add(s);
            }
          }

          return AlertDialog(
            title: const Text("Filtruj rośliny"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NOWE: Pole wyszukiwania gatunku/rodziny
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Szukaj nazwy lub rodziny...",
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setDialogState(() => dialogSearchQuery = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() => _selectedSpeciesIds.clear());
                          setState(() {}); // Odśwież mapę
                        },
                        child: const Text("RESET ZAZNACZENIA", style: TextStyle(color: Colors.red, fontSize: 12)),
                      )
                    ],
                  ),
                  const Divider(),
                  // Lista przefiltrowanych rodzin
                  Expanded(
                    child: filteredFamilies.isEmpty
                        ? const Center(child: Text("Nie znaleziono dopasowań."))
                        : ListView(
                      shrinkWrap: true,
                      children: filteredFamilies.entries.map((entry) {
                        return ExpansionTile(
                          // Automatyczne rozwijanie, gdy szukamy konkretnej rośliny
                          initiallyExpanded: dialogSearchQuery.isNotEmpty,
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Gatunki: ${entry.value.length}", style: const TextStyle(fontSize: 11)),
                          children: entry.value.map((species) {
                            final isSelected = _selectedSpeciesIds.contains(species.speciesID);
                            return CheckboxListTile(
                              title: Text(species.polishName, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(species.latinName, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    _selectedSpeciesIds.add(species.speciesID);
                                  } else {
                                    _selectedSpeciesIds.remove(species.speciesID);
                                  }
                                });
                                setState(() {}); // Odśwież mapę w tle
                              },
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ")),
            ],
          );
        },
      ),
    );
  }
}