import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/releve.dart';
import '../viewmodels/plants_view_model.dart';

class ReleveListMapScreen extends StatelessWidget {
  const ReleveListMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlantsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Zapisane obszary")),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(target: LatLng(52.23, 21.01), zoom: 12),
        mapType: MapType.hybrid,
        polygons: vm.allReleves.map((releve) => Polygon(
          polygonId: PolygonId(releve.id),
          points: releve.points,
          fillColor: Colors.blue.withOpacity(0.4),
          strokeColor: Colors.blue,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _showEditDeleteDialog(context, releve, vm),
        )).toSet(),
      ),
    );
  }

  void _showEditDeleteDialog(BuildContext context, Releve releve, PlantsViewModel vm) {
    final nameController = TextEditingController(text: releve.name);
    String currentType = releve.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Edytuj: ${releve.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nazwa")),
              DropdownButtonFormField<String>(
                value: currentType,
                items: ["Zespół", "Związek", "Rząd", "Klasa"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setStateDialog(() => currentType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                vm.deleteReleve(releve.id);
                Navigator.pop(ctx);
              },
              child: const Text("USUŃ", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                vm.updateReleve(releve.id, nameController.text, currentType);
                Navigator.pop(ctx);
              },
              child: const Text("ZAPISZ ZMIANY"),
            ),
          ],
        ),
      ),
    );
  }
}