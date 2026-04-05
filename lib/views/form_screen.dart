import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/observation_vm.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  // Lista przykładowych cech (Twoje "bloki fizjonomii")
  final List<String> _dostepneCechy = [
    'Liście ząbkowane', 'Liście gładkie', 'Kwiaty żółte',
    'Kwiaty białe', 'Łodyga owłosiona', 'Owoc mięsisty',
    'Roślina płożąca', 'Wysoka (>1m)'
  ];

  final List<String> _wybraneCechy = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opisz roślinę')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wybierz cechy pasujące do rośliny:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Siatka z "blokami" do wyboru
            Wrap(
              spacing: 10, // Odstęp poziomy
              runSpacing: 10, // Odstęp pionowy
              children: _dostepneCechy.map((cecha) {
                final isSelected = _wybraneCechy.contains(cecha);
                return FilterChip(
                  label: Text(cecha),
                  selected: isSelected,
                  selectedColor: Colors.green.shade200,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _wybraneCechy.add(cecha);
                      } else {
                        _wybraneCechy.remove(cecha);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),

            // Przycisk Zapisz Obserwację
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _wybraneCechy.isEmpty
                    ? null // Przycisk nieaktywny, jeśli nic nie wybrano
                    : () {
                  // Tutaj w przyszłości wywołamy zapis do bazy danych
                  _pokazPodsumowanie();
                },
                child: const Text("ZAPISZ IDENTYFIKACJĘ"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pokazPodsumowanie() {
    // 1. Pobieramy dane z ViewModelu aparatu
    final obsVm = context.read<ObservationViewModel>();

    // 2. Tworzymy nowy obiekt obserwacji (KROK ZAPISU)
    final newObs = PlantObservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unikalne ID
      photoPaths: List.from(obsVm.currentPhotoPaths),
      latitude: obsVm.currentPosition?.latitude ?? 0.0,
      longitude: obsVm.currentPosition?.longitude ?? 0.0,
      timestamp: DateTime.now(),
      characteristics: List.from(_wybraneCechy),
    );

    // 3. Dodajemy do listy wszystkich roślin
    context.read<PlantsViewModel>().addObservation(newObs);

    // 4. Wyświetlamy potwierdzenie
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Zapisano do opisu"),
        content: Text("Roślina z ${_wybraneCechy.length} cechami została dodana do kolejki opisywania."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Zamknij dialog
              Navigator.of(context).pop(); // Wróć do aparatu
              obsVm.reset(); // Wyczyść zdjęcia w aparacie
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}