// lib/widgets/harvest_season_picker.dart
import 'package:flutter/material.dart';
import '../models/harvest_season.dart';
import 'package:intl/intl.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Widżet zarządzania kalendarzem zbioru surowców roślinnych. Udostępnia listę
 * zdefiniowanych okresów oraz okno modalne (DateRangePicker) do precyzyjnego
 * definiowania przedziałów czasowych zbioru dla konkretnych części roślin (np. kwiaty, kłącza).
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/harvest_season.dart':
 * - Klasa [HarvestSeason]: Służy do mapowania, modyfikacji i eksportu obiektów
 * przedziałów czasowych wegetacji surowców flory.
 * ============================================================================
 */
class HarvestSeasonPicker extends StatefulWidget {
  final String title;
  final List<HarvestSeason> initialSeasons;
  final ValueChanged<List<HarvestSeason>> onChanged;

  const HarvestSeasonPicker({
    super.key,
    this.title = "Kalendarz Zbiorów Surowców:",
    required this.initialSeasons,
    required this.onChanged
  });

  @override
  State<HarvestSeasonPicker> createState() => _HarvestSeasonPickerState();
}

class _HarvestSeasonPickerState extends State<HarvestSeasonPicker> {
  late List<HarvestSeason> _seasons;
  final List<String> _availableMaterials = ["Kwiaty", "Liście", "Korzeń", "Kora", "Owoce", "Nasiona", "Ziele", "Pączki", "Kłącze", "Pędy"];

  @override
  void initState() {
    super.initState();
    _seasons = List.from(widget.initialSeasons);
  }

  void _showAddDialog() {
    String? selectedMaterial;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            final dateText = (startDate != null && endDate != null)
                ? "${DateFormat('dd.MM.yyyy').format(startDate!)}  -  ${DateFormat('dd.MM.yyyy').format(endDate!)}"
                : "Wybierz zakres dat";

            return AlertDialog(
              title: const Text("Zdefiniuj okres zbiorów"),
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
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.calendar_month, color: Colors.green),
                      label: Text(dateText, style: const TextStyle(color: Colors.black87)),
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          helpText: "Wybierz okres zbiorów",
                          saveText: "ZATWIERDŹ",
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked.start;
                            endDate = picked.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    if (selectedMaterial != null && startDate != null && endDate != null) {
                      setState(() {
                        _seasons.add(HarvestSeason(
                            material: selectedMaterial!,
                            startDate: startDate,
                            endDate: endDate,
                            reminderEnabled: false // WYŁĄCZONE DLA POJEDYNCZEGO OKAZU
                        ));
                      });
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

          final dateText = (season.startDate != null && season.endDate != null)
              ? "${DateFormat('dd.MM').format(season.startDate!)} - ${DateFormat('dd.MM').format(season.endDate!)}"
              : "Brak daty";

          return Card(
            elevation: 1, margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.shopping_bag_outlined, color: Colors.green),
              title: Text(season.material, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(dateText),
              trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () { setState(() => _seasons.removeAt(idx)); widget.onChanged(_seasons); }
              ),
            ),
          );
        }).toList()
      ],
    );
  }
}