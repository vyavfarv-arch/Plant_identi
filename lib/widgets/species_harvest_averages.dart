// lib/widgets/species_harvest_averages.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/reminder_view_model.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Widżet listy uśrednionych terminów fenologicznych zbioru surowca. Wyświetla
 * statystyczne ramy czasowe obliczone z prób terenowych i udostępnia interaktywną
 * ikonę dzwonka wyzwalającą asystenta czasowego i powiadomienie push w telefonie.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../viewmodels/reminder_view_model.dart':
 * - Klasa [ReminderViewModel]: Wywoływana po kliknięciu przycisku w celu
 * zaplanowania systemowego powiadomienia o nadejściu optymalnego czasu zbiorów.
 * ============================================================================
 */
class SpeciesHarvestAverages extends StatelessWidget {
  final String commonName;
  final String? speciesId;
  final List<Map<String, dynamic>> calculatedAverageSeasons;

  const SpeciesHarvestAverages({
    super.key,
    required this.commonName,
    required this.speciesId,
    required this.calculatedAverageSeasons,
  });

  @override
  Widget build(BuildContext context) {
    final remVm = context.read<ReminderViewModel>();
    final df = DateFormat('dd.MM');

    if (calculatedAverageSeasons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(left: 6, top: 4),
        child: Text("Brak zarejestrowanych terminów wegetacji surowców.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Column(
      children: calculatedAverageSeasons.map((item) {
        final String mat = item['material'];
        final DateTime start = item['startDate'];
        final DateTime end = item['endDate'];
        final int sampleCount = item['count'];

        return Card(
          color: Colors.green.shade50,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.calendar_today, color: Colors.green),
            title: Text(mat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Uśredniony fenologicznie czas: ${df.format(start)} - ${df.format(end)} (Próba z $sampleCount okazów)"),
            trailing: IconButton(
              icon: const Icon(Icons.notification_add, color: Colors.orange),
              tooltip: "Aktywuj asystenta poszukiwań i powiadomienie",
              onPressed: () async {
                await remVm.addHarvestReminder(
                  plantName: commonName,
                  material: mat,
                  startDate: start,
                  endDate: end,
                  relatedId: speciesId ?? "",
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: Colors.amber.shade900,
                  content: Text("Asystent czasowy aktywny. Przypomnę o zbiorze surowca ($mat) dnia ${df.format(start)}!"),
                ));
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}