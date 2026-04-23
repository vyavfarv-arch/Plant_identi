import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';


enum MapViewMode { plants, syntaxa }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor? grassIcon;
  // ignore: unused_field
  MapViewMode _mode = MapViewMode.plants;
  // ignore: unused_field
  String _selectedRank = "Zespół";

  @override
  void initState() {
    super.initState();
    _loadAndResizeIcon();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  void _loadAndResizeIcon() async {
    try {
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
    // ZMIANA: Pobieranie danych z ObservationViewModel i filtrów z SearchFilterViewModel
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

    // LOGIKA FILTROWANIA: Wyświetlamy rośliny pasujące do wybranych nazw
    // Jeśli żadna nazwa nie jest wybrana, lista jest pusta (zgodnie z poprzednią logiką)
    final plantsToDisplay = obsVm.completeObservations.where((obs) {
      if (filterVm.selectedPlantNames.isEmpty) return false;
      return filterVm.selectedPlantNames.contains(obs.displayName);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Roślin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_alt),
            onPressed: () => _showFilterDialog(context, obsVm, filterVm),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(52.237, 21.017), zoom: 6),
        myLocationEnabled: true,
        mapType: MapType.satellite,
        markers: plantsToDisplay.map((obs) => Marker(
          markerId: MarkerId(obs.id),
          position: LatLng(obs.latitude, obs.longitude),
          icon: grassIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
              title: obs.displayName,
              snippet: "Ilość: ${obs.abundance}"
          ),
        )).toSet(),
      ),
    );
  }

  // ZMIANA: Przekazanie obsVm i filterVm do dialogu
  void _showFilterDialog(BuildContext context, ObservationViewModel obsVm, SearchFilterViewModel filterVm) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Wybierz rośliny do wyświetlenia"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Używamy unikalnych nazw z bazy obserwacji
              children: obsVm.uniquePlantNames.map((name) => CheckboxListTile(
                title: Text(name),
                // Sprawdzamy stan w SearchFilterViewModel
                value: filterVm.selectedPlantNames.contains(name),
                onChanged: (val) {
                  // Przełączamy filtr w SearchFilterViewModel
                  filterVm.togglePlantNameFilter(name);
                  setDialogState(() {});
                },
              )).toList(),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ"))],
        ),
      ),
    );
  }
}