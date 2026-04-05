import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/plant_observation.dart';
import '../viewmodels/plants_view_model.dart';

class DetailDescriptionScreen extends StatefulWidget {
  final PlantObservation observation;
  const DetailDescriptionScreen({super.key, required this.observation});

  @override
  State<DetailDescriptionScreen> createState() => _DetailDescriptionScreenState();
}

class _DetailDescriptionScreenState extends State<DetailDescriptionScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedAbundance;
  DateTime? _selectedDate;

  final List<String> _abundanceOptions = [
    '5 - Bardzo dużo (100/75%)',
    '4 - Dużo (75-50%)',
    '3 - Umiarkowanie (50-25%)',
    '2 - Mało (25-5%)',
    '1 - Niewiele (>5%)',
    'r - Pojedyńcze'
  ];

  @override
  void initState() {
    super.initState();
    // Ładowanie postępu, jeśli już coś wpisano wcześniej
    _nameController.text = widget.observation.plantName ?? "";
    _selectedAbundance = widget.observation.abundance;
    _selectedDate = widget.observation.observationDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Opis rośliny")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pole 1: Ilościowość
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Ilościowość"),
            value: _selectedAbundance,
            items: _abundanceOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: (val) => setState(() => _selectedAbundance = val),
          ),
          const SizedBox(height: 20),

          // Pole 2: Nazwa
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Nazwa rośliny"),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Pole 3: Data
          ListTile(
            title: Text(_selectedDate == null
                ? "Wybierz datę obserwacji"
                : "Data: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Zapisujemy postęp (nawet jeśli niepełny)
              context.read<PlantsViewModel>().updateObservation(
                  widget.observation.id,
                  _nameController.text,
                  _selectedAbundance ?? "",
                  _selectedDate ?? DateTime.now()
              );
              Navigator.pop(context);
            },
            child: const Text("ZAPISZ I WRÓĆ"),
          )
        ],
      ),
    );
  }
}