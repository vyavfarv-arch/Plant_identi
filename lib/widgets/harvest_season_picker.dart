// lib/widgets/harvest_season_picker.dart
import 'package:flutter/material.dart';
import '../models/harvest_season.dart';

class HarvestSeasonPicker extends StatefulWidget {
  final String title;
  final List<HarvestSeason> initialSeasons;
  final ValueChanged<List<HarvestSeason>> onChanged;

  const HarvestSeasonPicker({super.key, this.title = "Kalendarz Zbiorów Surowców:", required this.initialSeasons, required this.onChanged});

  @override
  State<HarvestSeasonPicker> createState() => _HarvestSeasonPickerState();
}

class _HarvestSeasonPickerState extends State<HarvestSeasonPicker> {
  late List<HarvestSeason> _seasons;

  final List<String> _availableMaterials = ["Kwiaty", "Liście", "Korzeń", "Kora", "Owoce", "Nasiona", "Ziele", "Pączki", "Kłącze", "Pędy"];
  final List<String> _monthNames = ["Sty", "Lut", "Mar", "Kwi", "Maj", "Cze", "Lip", "Sie", "Wrz", "Paź", "Lis", "Gru"];

  @override
  void initState() {
    super.initState();
    _seasons = List.from(widget.initialSeasons);
  }

  void _showAddDialog() {
    String? selectedMaterial;
    List<int> selectedMonths = [];
    bool enableReminder = false; // Stan checkboxa

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Dodaj surowiec"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Część rośliny", border: OutlineInputBorder(), isDense: true),
                      items: _availableMaterials.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setDialogState(() => selectedMaterial = v),
                    ),
                    const SizedBox(height: 16),
                    const Text("Miesiące zbioru:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 4, runSpacing: 4,
                      children: List.generate(12, (index) {
                        final m = index + 1;
                        final isSelected = selectedMonths.contains(m);
                        return FilterChip(
                          label: Text(_monthNames[index], style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
                          selected: isSelected, selectedColor: Colors.orange,
                          onSelected: (val) => setDialogState(() => val ? selectedMonths.add(m) : selectedMonths.remove(m)),
                        );
                      }),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Ustaw przypomnienia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text("Aplikacja przypomni Ci o nadchodzącym sezonie.", style: TextStyle(fontSize: 11)),
                      value: enableReminder,
                      activeColor: Colors.green,
                      onChanged: (val) => setDialogState(() => enableReminder = val),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    if (selectedMaterial != null && selectedMonths.isNotEmpty) {
                      setState(() => _seasons.add(HarvestSeason(material: selectedMaterial!, months: selectedMonths, reminderEnabled: enableReminder)));
                      widget.onChanged(_seasons);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Zapisz"),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green))),
            TextButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add), label: const Text("Dodaj"))
          ],
        ),
        if (_seasons.isEmpty) const Text("Brak zdefiniowanych surowców.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ..._seasons.asMap().entries.map((entry) {
          final idx = entry.key;
          final season = entry.value;
          final monthsText = season.months.map((m) => _monthNames[m-1]).join(", ");
          return Card(
            elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              dense: true,
              leading: Icon(season.reminderEnabled ? Icons.notifications_active : Icons.spa, color: season.reminderEnabled ? Colors.orange : Colors.green),
              title: Text(season.material, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(monthsText, style: const TextStyle(color: Colors.black87)),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { setState(() => _seasons.removeAt(idx)); widget.onChanged(_seasons); }),
            ),
          );
        }).toList()
      ],
    );
  }
}