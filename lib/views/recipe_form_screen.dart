// lib/views/recipe_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../viewmodels/recipe_view_model.dart';

class _IngredientControllers {
  final TextEditingController name;
  final TextEditingController part;
  final TextEditingController amount;
  _IngredientControllers(String n, String p, String a) : name = TextEditingController(text: n), part = TextEditingController(text: p), amount = TextEditingController(text: a);
}

class _StepData {
  String type;
  late TextEditingController contentCtrl;
  late TextEditingController durationCtrl;
  String unit = 'Minuty';

  _StepData({required this.type, String content = '', int duration = 0}) {
    contentCtrl = TextEditingController(text: content);

    if (duration > 0 && duration % 1440 == 0) {
      durationCtrl = TextEditingController(text: (duration ~/ 1440).toString());
      unit = 'Dni';
    } else if (duration > 0 && duration % 60 == 0) {
      durationCtrl = TextEditingController(text: (duration ~/ 60).toString());
      unit = 'Godziny';
    } else {
      durationCtrl = TextEditingController(text: duration > 0 ? duration.toString() : '');
      unit = 'Minuty';
    }
  }

  int get durationAsMinutes {
    final val = int.tryParse(durationCtrl.text) ?? 0;
    if (unit == 'Dni') return val * 1440;
    if (unit == 'Godziny') return val * 60;
    return val;
  }
}

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipeToEdit;
  const RecipeFormScreen({super.key, this.recipeToEdit});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _newLabelCtrl = TextEditingController();
  String _selectedType = 'Napar';
  final List<String> _types = ['Napar', 'Odwar', 'Macerat', 'Nalewka', 'Maść', 'Syrop', 'Inne'];

  final List<_IngredientControllers> _ingredients = [];
  final List<_StepData> _steps = [];
  final List<String> _currentLabels = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      final r = widget.recipeToEdit!;
      _titleCtrl.text = r.title;
      _selectedType = r.type;
      _noteCtrl.text = r.note;
      _currentLabels.addAll(r.labels);
      for (var ing in r.ingredients) { _ingredients.add(_IngredientControllers(ing.speciesName, ing.plantPart, ing.amount)); }
      for (var s in r.steps) { _steps.add(_StepData(type: s.type, content: s.content, duration: s.durationMinutes)); }
    } else {
      _ingredients.add(_IngredientControllers('', '', ''));
      _steps.add(_StepData(type: 'text'));
    }
  }

  void _save() {
    if (_titleCtrl.text.isEmpty) return;

    final recipeId = widget.recipeToEdit?.id ?? const Uuid().v4();

    List<RecipeStep> finalSteps = _steps.where((s) => s.contentCtrl.text.isNotEmpty).map((s) {
      return RecipeStep(
          type: s.type,
          content: s.contentCtrl.text,
          durationMinutes: s.durationAsMinutes
      );
    }).toList();

    final recipe = Recipe(
      id: recipeId,
      title: _titleCtrl.text,
      type: _selectedType,
      note: _noteCtrl.text.trim(),
      createdAt: widget.recipeToEdit?.createdAt ?? DateTime.now(),
      ingredients: _ingredients.where((c) => c.name.text.isNotEmpty).map((c) => RecipeIngredient(speciesName: c.name.text, plantPart: c.part.text, amount: c.amount.text)).toList(),
      steps: finalSteps,
      labels: _currentLabels,
    );

    context.read<RecipeViewModel>().addOrUpdateRecipe(recipe);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final recipeVm = context.watch<RecipeViewModel>();
    // Pobierz unikalne, już istniejące etykiety ze wszystkich przepisów
    final allExistingLabels = recipeVm.recipes.expand((r) => r.labels).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Kreator Przepisu")),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Tytuł przepisu", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(value: _selectedType, items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedType = v!), decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 15),

          TextField(controller: _noteCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Notatka / Opis przepisu", border: OutlineInputBorder(), alignLabelWithHint: true)),
          const SizedBox(height: 20),

          // SEKCJA LABELI (ETYKIET)
          const Text("Etykiety (Labele) przepisu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
          const SizedBox(height: 8),
          if (_currentLabels.isNotEmpty)
            Wrap(
              spacing: 8,
              children: _currentLabels.map((l) => Chip(
                label: Text(l),
                onDeleted: () => setState(() => _currentLabels.remove(l)),
                backgroundColor: Colors.teal.shade50,
              )).toList(),
            )
          else
            const Text("Brak przypisanych etykiet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newLabelCtrl,
                  decoration: const InputDecoration(hintText: "Wpisz nowy label...", isDense: true, border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () {
                  final text = _newLabelCtrl.text.trim();
                  if (text.isNotEmpty && !_currentLabels.contains(text)) {
                    setState(() {
                      _currentLabels.add(text);
                      _newLabelCtrl.clear();
                    });
                  }
                },
                child: const Text("DODAJ"),
              ),
            ],
          ),

          if (allExistingLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text("Wybierz z już istniejących etykiet:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: allExistingLabels.where((l) => !_currentLabels.contains(l)).map((l) => ActionChip(
                label: Text(l, style: const TextStyle(fontSize: 12)),
                onPressed: () => setState(() => _currentLabels.add(l)),
              )).toList(),
            )
          ],

          const Divider(height: 40),
          Row(margin: const EdgeInsets.spaceBetween, children: [
            const Text("Składniki:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(onPressed: () => setState(() => _ingredients.add(_IngredientControllers('', '', ''))), icon: const Icon(Icons.add), label: const Text("Składnik"))
          ]),
          ..._ingredients.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: e.value.name, decoration: const InputDecoration(hintText: "Gatunek", isDense: true))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextField(controller: e.value.part, decoration: const InputDecoration(hintText: "Surowiec", isDense: true))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextField(controller: e.value.amount, decoration: const InputDecoration(hintText: "Ilość", isDense: true))),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _ingredients.removeAt(e.key))),
              ],
            ),
          )),

          const Divider(height: 40),
          const Text("Sposób przygotowania:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          ..._steps.asMap().entries.map((e) {
            final idx = e.key;
            final step = e.value;

            if (step.type == 'text') {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 10),
                    child: TextField(controller: step.contentCtrl, maxLines: 4, decoration: InputDecoration(hintText: "Krok ${idx+1} (Opis)...", border: const OutlineInputBorder())),
                  ),
                  Positioned(right: 0, top: 0, child: IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () => setState(() => _steps.removeAt(idx))))
                ],
              );
            } else {
              return Card(
                color: Colors.indigo.shade50,
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: TextField(controller: step.contentCtrl, decoration: const InputDecoration(hintText: "Nazwa akcji", isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: TextField(controller: step.durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Czas", isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: DropdownButton<String>(
                        value: step.unit,
                        isExpanded: true,
                        items: ['Minuty', 'Godziny', 'Dni'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => step.unit = v!),
                      )),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _steps.removeAt(idx))),
                    ],
                  ),
                ),
              );
            }
          }),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(onPressed: () => setState(() => _steps.add(_StepData(type: 'text'))), icon: const Icon(Icons.notes), label: const Text("Dodaj Tekst")),
              OutlinedButton.icon(onPressed: () => setState(() => _steps.add(_StepData(type: 'timer'))), icon: const Icon(Icons.timer), label: const Text("Dodaj Czas")),
            ],
          ),

          const SizedBox(height: 30),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: _save, child: const Text("ZAPISZ")),
          const SizedBox(height: 50),
        ],
      ),),
    );
  }
}