import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/search_filter_view_model.dart';
import '../services/location_service.dart'; // Import serwisu lokalizacji

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor? grassIcon;
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadAndResizeIcon();
  }

  Future<void> _centerOnUser() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    }
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
    final obsVm = context.watch<ObservationViewModel>();
    final filterVm = context.watch<SearchFilterViewModel>();

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
        onMapCreated: (controller) {
          _mapController = controller;
          _centerOnUser(); // Centrowanie przy starcie
        },
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

  void _showFilterDialog(BuildContext context, ObservationViewModel obsVm, SearchFilterViewModel filterVm) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Wybierz rośliny do wyświetlenia"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: obsVm.uniquePlantNames.map((name) => CheckboxListTile(
                title: Text(name),
                value: filterVm.selectedPlantNames.contains(name),
                onChanged: (val) {
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