// lib/views/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../models/plant_species.dart';
import '../models/plant_observation.dart';
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

  // Zmienne stanu do obsługi zmiany lokalizacji
  bool _isRelocatingMode = false;
  PlantObservation? _targetObservation;
  LatLng? _currentCrosshairPosition;

  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>();

    // Filtrowanie markerów na podstawie wybranych gatunków
    Set<Marker> markers = {};
    if (_showPlants && !_isRelocatingMode) {
      markers = obsVm.allObservations.where((o) {
        if (_selectedSpeciesIds.isEmpty) return true;
        return _selectedSpeciesIds.contains(o.speciesId);
      }).map((obs) {
        return Marker(
          markerId: MarkerId('plant_${obs.id}'),
          position: LatLng(obs.latitude, obs.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () => _showMarkerMenu(context, obs), // Menu akcji dla pinezki
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
        consumeTapEvents: !_isRelocatingMode,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))),
      );
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRelocatingMode ? "Przesuń pędem celownik" : "Mapa Terenowa"),
        automaticallyImplyLeading: !_isRelocatingMode, // Blokada powrotu w trybie edycji
        actions: [
          if (!_isRelocatingMode) ...[
            IconButton(
              icon: Icon(_showPlants ? Icons.visibility : Icons.visibility_off),
              tooltip: "Pokaż/Ukryj rośliny",
              onPressed: () => setState(() => _showPlants = !_showPlants),
            ),
            IconButton(
              icon: Icon(Icons.filter_alt, color: _selectedSpeciesIds.isNotEmpty ? Colors.orange : null),
              onPressed: () => _showFilterDialog(context, obsVm),
            ),
          ]
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // WARSTWA 1: Mapa Google
            GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 10),
              markers: markers,
              polygons: polygons,
              mapType: MapType.hybrid,
              myLocationEnabled: !_isRelocatingMode,
              zoomControlsEnabled: !_isRelocatingMode,
              onCameraMove: (CameraPosition position) {
                if (_isRelocatingMode) {
                  _currentCrosshairPosition = position.target;
                }
              },
            ),

            // WARSTWA 2: Celownik na środku ekranu (POPRAWIONA SKŁADNIA)
            if (_isRelocatingMode)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36), // Przesunięcie optyczne nad podstawę pinezki
                  child: Icon(
                    Icons.add_location_alt_rounded,
                    size: 50,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),

            // WARSTWA 3: Panel dolny akceptacji relokalizacji
            if (_isRelocatingMode && _targetObservation != null)
              Positioned(
                bottom: 20, left: 16, right: 16,
                child: Card(
                  color: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Ustawiasz nową pozycję dla:\n${_targetObservation!.displayName}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isRelocatingMode = false),
                                child: const Text("ANULUJ"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                onPressed: () async {
                                  if (_currentCrosshairPosition != null) {
                                    await obsVm.updateObservationCoordinates(
                                      _targetObservation!.id,
                                      _currentCrosshairPosition!.latitude,
                                      _currentCrosshairPosition!.longitude,
                                    );
                                    setState(() => _isRelocatingMode = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Pomyślnie zaktualizowano pozycję okazu.")),
                                      );
                                    }
                                  }
                                },
                                child: const Text("ZATWIERDŹ"),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Menu kontekstowe po naciśnięciu w pinezkę
  void _showMarkerMenu(BuildContext context, PlantObservation obs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: Text(obs.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Wybierz czynność dla tego okazu"),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.library_books, color: Colors.teal),
              title: const Text("Pokaż kartę opisu rośliny"),
              onTap: () {
                Navigator.pop(ctx);
                PlantCardView.show(context, obs);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wrong_location_rounded, color: Colors.orange),
              title: const Text("Zmień lokalizację (Korekta GPS)"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _targetObservation = obs;
                  _isRelocatingMode = true;
                  _currentCrosshairPosition = LatLng(obs.latitude, obs.longitude);
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ObservationViewModel obsVm) {
    String dialogSearchQuery = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final Map<String, List<PlantSpecies>> filteredFamilies = {};

          for (var s in obsVm.speciesDictionary) {
            final fam = s.family.isEmpty ? "Inne / Nieokreślone" : s.family;

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
                          setState(() {});
                        },
                        child: const Text("RESET ZAZNACZENIA", style: TextStyle(color: Colors.red, fontSize: 12)),
                      )
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: filteredFamilies.isEmpty
                        ? const Center(child: Text("Nie znaleziono dopasowań."))
                        : ListView(
                      shrinkWrap: true,
                      children: filteredFamilies.entries.map((entry) {
                        return ExpansionTile(
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
                                setState(() {});
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