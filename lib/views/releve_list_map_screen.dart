// lib/views/releve_list_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../models/releve.dart';
import 'releve_details_screen.dart';
import 'releve_map_screen.dart'; // IMPORT MAPY

class ReleveListMapScreen extends StatefulWidget {
  const ReleveListMapScreen({super.key});

  @override
  State<ReleveListMapScreen> createState() => _ReleveListMapScreenState();
}

class _ReleveListMapScreenState extends State<ReleveListMapScreen> {
  String _selectedType = "Wszystkie";
  final List<String> _filterOptions = ["Wszystkie", "Obszar", "Podobszar"];

  @override
  Widget build(BuildContext context) {
    final releveVm = context.watch<ReleveViewModel>();
    final allReleves = releveVm.allReleves;

    final filteredReleves = allReleves.where((r) {
      if (_selectedType == "Wszystkie") return true;
      return r.type == _selectedType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zarządzanie Obszarami"),
        actions: [
          // PRZYCISK PRZEGLĄDANIA MAPY WSZYSTKICH OBSZARÓW
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: "Podgląd mapy",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReleveMapScreen())),
          ),
        ],
      ),
      // PRZYCISK DODAWANIA NOWEGO OBSZARU
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReleveMapScreen())),
        icon: const Icon(Icons.add_location_alt),
        label: const Text("NOWY OBSZAR"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.indigo.shade50,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((type) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      selectedColor: Colors.indigo.shade200,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: filteredReleves.isEmpty
                ? const Center(child: Text("Brak obszarów. Kliknij przycisk poniżej, aby dodać."))
                : ListView.builder(
              itemCount: filteredReleves.length,
              padding: const EdgeInsets.only(bottom: 80), // Miejsce na FAB
              itemBuilder: (context, index) {
                final r = filteredReleves[index];
                List<Releve> subareas = [];
                if (r.type == "Obszar") {
                  subareas = allReleves.where((sub) => sub.parentId == r.id).toList();
                }
                Releve? parentArea;
                if (r.type == "Podobszar" && r.parentId != null) {
                  try { parentArea = allReleves.firstWhere((p) => p.id == r.parentId); } catch (_) {}
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: r.type == "Obszar" ? Colors.indigo.shade100 : Colors.blue.shade100,
                      child: Icon(r.type == "Obszar" ? Icons.map : Icons.layers, color: r.type == "Obszar" ? Colors.indigo : Colors.blue),
                    ),
                    title: Text(r.commonName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Typ: ${r.type}"),
                        if (r.type == "Obszar" && subareas.isNotEmpty)
                          Text("Podobszary: ${subareas.length}", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                        if (r.type == "Podobszar" && parentArea != null)
                          Text("Należy do: ${parentArea.commonName}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}