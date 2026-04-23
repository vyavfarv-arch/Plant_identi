import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/releve.dart';
import '../viewmodels/releve_view_model.dart';

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
              onTap: () => _removePoint(e.key),
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
                child: const Text("ZAPISZ OBSZAR", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  void _showReleveSurvey(BuildContext context) {
    // ZMIANA: Dwa kontrolery dla dwóch nazw
    final commonNameController = TextEditingController();
    final phytoNameController = TextEditingController();
    String selectedType = "Zespół";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Szczegóły płatu"),
          content: SingleChildScrollView( // Dodano dla bezpieczeństwa przy wielu polach
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: commonNameController,
                    decoration: const InputDecoration(labelText: "Nazwa zwyczajowa (np. Przy rzece)")
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: phytoNameController,
                    decoration: const InputDecoration(labelText: "Nazwa fitosocjologiczna (np. Alnion)")
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ["Zespół", "Związek", "Rząd", "Klasa"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setStateDialog(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: "Typ"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
            ElevatedButton(
              onPressed: () {
                if (commonNameController.text.isNotEmpty) {
                  // ZMIANA: Użycie nowych parametrów w konstruktorze Releve
                  final newReleve = Releve(
                    id: const Uuid().v4(),
                    commonName: commonNameController.text,
                    phytosociologicalName: phytoNameController.text,
                    type: selectedType,
                    points: List.from(_polygonPoints),
                    date: DateTime.now(),
                  );
                  // ZMIANA: Użycie ReleveViewModel
                  context.read<ReleveViewModel>().saveNewReleve(newReleve);
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