import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/plants_view_model.dart';

enum MapViewMode { plants, syntaxa }
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor? grassIcon;
  MapViewMode _mode = MapViewMode.plants;
  String _selectedRank = "Zespół";
  @override
  void initState() {
    super.initState();
    _loadAndResizeIcon();
  }

  // Funkcja skalująca obrazek do mniejszego rozmiaru
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void _loadAndResizeIcon() async {
    try {
      // Zmniejszamy szerokość ikony do 110 pikseli
      final Uint8List markerIconBytes = await _getBytesFromAsset('assets/grass.png', 110);
      setState(() {
        grassIcon = BitmapDescriptor.fromBytes(markerIconBytes);
      });
    } catch (e) {
      setState(() {
        grassIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();
    final plantsToDisplay = vm.mapFilteredObservations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Roślin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            onPressed: () => _showFilterDialog(context, vm),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
            target: LatLng(52.237, 21.017),
            zoom: 6
        ),
        myLocationEnabled: true,
        markers: plantsToDisplay.map((obs) => Marker(
          markerId: MarkerId(obs.id),
          position: LatLng(obs.latitude, obs.longitude),
          icon: grassIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
              title: obs.displayName, // Zmieniono z plantName
              snippet: "Ilość: ${obs.abundance}"
          ),
        )).toSet(),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, PlantsViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder( // Używamy StatefulBuilder wewnątrz dialogu
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("Filtry mapy"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Tryb widoku:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          ChoiceChip(
                              label: const Text("Rośliny"),
                              selected: _mode == MapViewMode.plants,
                              onSelected: (s) { if(s) setState(() => _mode = MapViewMode.plants); setDialogState(() {}); }
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                              label: const Text("Syntaksony"),
                              selected: _mode == MapViewMode.syntaxa,
                              onSelected: (s) { if(s) setState(() => _mode = MapViewMode.syntaxa); setDialogState(() {}); }
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_mode == MapViewMode.syntaxa) ...[
                        const Text("Ranga:"),
                        DropdownButton<String>(
                          value: _selectedRank,
                          items: ["Zespół", "Związek", "Rząd", "Klasa"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (v) { setState(() => _selectedRank = v!); setDialogState(() {}); },
                        ),
                      ] else ...[
                        // Lista roślin (vm.uniquePlantNames)
                        ...vm.uniquePlantNames.map((name) => CheckboxListTile(
                          title: Text(name),
                          value: vm.selectedPlantNames.contains(name),
                          onChanged: (val) { vm.toggleNameFilter(name); setDialogState(() {}); },
                        )).toList(),
                      ]
                    ],
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ"))],
              );
            }
        );
      },
    );
  }
}