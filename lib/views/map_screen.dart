// lib/views/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import 'plant_card_view.dart';
import 'releve_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final obsVm = context.watch<ObservationViewModel>();
    final releveVm = context.watch<ReleveViewModel>();

    Set<Marker> markers = {};

    // 1. Markery Roślin (Zielone)
    markers.addAll(obsVm.allObservations.map((obs) {
      return Marker(
        markerId: MarkerId('plant_${obs.id}'),
        position: LatLng(obs.latitude, obs.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: obs.displayName, snippet: 'Kliknij, aby zobaczyć kartę'),
        onTap: () => PlantCardView.show(context, obs),
      );
    }));

    // 2. Markery-Etykiety dla Obszarów (Niebieskie/Fioletowe szpilki w centrum obszaru)
    markers.addAll(releveVm.allReleves.where((r) => r.points.isNotEmpty).map((r) {
      final isArea = r.type == "Obszar";
      return Marker(
        markerId: MarkerId('area_lbl_${r.id}'),
        position: r.points.first, // Stawiamy etykietę na pierwszym punkcie
        icon: BitmapDescriptor.defaultMarkerWithHue(isArea ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: "${r.type}: ${r.commonName}", snippet: "Otwórz szczegóły"),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))),
      );
    }));

    // 3. Budowanie zarysów (Polygonów) ze ZWIĘKSZONĄ intensywnością i grubością
    Set<Polygon> polygons = releveVm.allReleves.where((r) => r.points.isNotEmpty).map((r) {
      final isArea = r.type == "Obszar";
      return Polygon(
        polygonId: PolygonId(r.id),
        points: r.points,
        // Zmiana z opacity 0.2 na 0.45 dla mocniejszego efektu wizualnego
        fillColor: isArea ? Colors.indigo.withOpacity(0.45) : Colors.purple.withOpacity(0.45),
        strokeColor: isArea ? Colors.indigoAccent : Colors.purpleAccent,
        strokeWidth: 3, // Grubsze linie graniczne
        consumeTapEvents: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))),
      );
    }).toSet();

    LatLng initialPos = const LatLng(52.2297, 21.0122);
    if (obsVm.allObservations.isNotEmpty) {
      initialPos = LatLng(obsVm.allObservations.first.latitude, obsVm.allObservations.first.longitude);
    } else if (releveVm.allReleves.isNotEmpty && releveVm.allReleves.first.points.isNotEmpty) {
      initialPos = releveVm.allReleves.first.points.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mapa Terenowa")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialPos, zoom: 12),
        markers: markers,
        polygons: polygons,
        mapType: MapType.hybrid,
        myLocationEnabled: true,
      ),
    );
  }
}