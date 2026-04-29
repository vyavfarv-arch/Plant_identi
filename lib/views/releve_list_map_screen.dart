// lib/views/releve_list_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/releve_view_model.dart';
import '../models/releve.dart';
import 'releve_details_screen.dart';

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
      appBar: AppBar(title: const Text("Zarządzanie Obszarami")),
      body: Column(
        children: [
          // NOWE FILTRY: Obszar / Podobszar
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
                      label: Text(type, style: TextStyle(fontWeight: _selectedType == type ? FontWeight.bold : FontWeight.normal)),
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
                ? const Center(child: Text("Brak obszarów dla tego filtru.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: filteredReleves.length,
              itemBuilder: (context, index) {
                final r = filteredReleves[index];

                // Szukamy Podobszarów dla tego Obszaru
                List<Releve> subareas = [];
                if (r.type == "Obszar") {
                  subareas = allReleves.where((sub) => sub.parentId == r.id).toList();
                }

                // Szukamy nadrzędnego Obszaru dla tego Podobszaru
                Releve? parentArea;
                if (r.type == "Podobszar" && r.parentId != null) {
                  try {
                    parentArea = allReleves.firstWhere((p) => p.id == r.parentId);
                  } catch (_) {}
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: r.type == "Obszar" ? Colors.indigo.shade100 : Colors.blue.shade100,
                      child: Icon(
                        r.type == "Obszar" ? Icons.map : Icons.layers,
                        color: r.type == "Obszar" ? Colors.indigo : Colors.blue,
                      ),
                    ),
                    title: Text(r.commonName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Ranga: ${r.type}", style: const TextStyle(color: Colors.black87)),

                        // Wyświetlanie Podobszarów pod Obszarem
                        if (r.type == "Obszar" && subareas.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              "Podobszary: ${subareas.map((s) => s.commonName).join(' • ')}",
                              style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),

                        // Wyświetlanie Nadrzędnego Obszaru nad Podobszarem
                        if (r.type == "Podobszar" && parentArea != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              "Należy do: ${parentArea.commonName}",
                              style: const TextStyle(color: Colors.indigo, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    isThreeLine: (r.type == "Obszar" && subareas.isNotEmpty) || (r.type == "Podobszar" && parentArea != null),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReleveDetailsScreen(releve: r)),
                      );
                    },
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