import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../viewmodels/plants_view_model.dart';

class ReleveMapScreen extends StatefulWidget {
  const ReleveMapScreen({super.key});

  @override
  State<ReleveMapScreen> createState() => _ReleveMapScreenState();
}

class _ReleveMapScreenState extends State<ReleveMapScreen> {
  final List<LatLng> _polygonPoints = [];

  void _addPoint(LatLng point) {
    setState(() => _polygonPoints.add(point));
  }

  void _removePoint(int index) {
    setState(() => _polygonPoints.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wyznacz płat (wielokąt)")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 15),
            mapType: MapType.satellite,
            myLocationEnabled: true,
            onTap: _addPoint,
            markers: _polygonPoints.asMap().entries.map((e) => Marker(
              markerId: MarkerId("p${e.key}"),
              position: e.value,
              onTap: () => _removePoint(e.key), // Kliknięcie w róg usuwa go
            )).toSet(),
            polygons: _polygonPoints.length >= 3 ? {
              Polygon(
                polygonId: const PolygonId("current_area"),
                points: _polygonPoints,
                fillColor: Colors.green.withOpacity(0.3),
                strokeColor: Colors.green,
                strokeWidth: 3,
              )
            } : {},
          ),
          if (_polygonPoints.length >= 3)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
                onPressed: () => _showReleveSurvey(context),
                child: const Text("DODAJ ZDJĘCIE", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  void _showReleveSurvey(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = "Zespół";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Szczegóły płatu"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nazwa zdjęcia")),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ["Zespół", "Związek", "Rząd", "Klasa"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setStateDialog(() => selectedType = v!),
                decoration: const InputDecoration(labelText: "Typ"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newReleve = Releve(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    type: selectedType,
                    points: List.from(_polygonPoints),
                    date: DateTime.now(),
                  );
                  context.read<PlantsViewModel>().saveNewReleve(newReleve);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                }
              },
              child: const Text("ZAPISZ"),
            ),
          ],
        ),
      ),
    );
  }
}