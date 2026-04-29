// lib/views/recipe_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../viewmodels/recipe_view_model.dart';
import '../viewmodels/reminder_view_model.dart';

// Helper dla formularza składników
class _IngredientControllers {
  final TextEditingController name;
  final TextEditingController part;
  final TextEditingController amount;
  _IngredientControllers(String n, String p, String a) : name = TextEditingController(text: n), part = TextEditingController(text: p), amount = TextEditingController(text: a);
}

// Helper dla bloków czasowych
class _TimerControllers {
  final TextEditingController name;
  final TextEditingController duration;
  String unit; // 'Minuty', 'Godziny', 'Dni'
  _TimerControllers(String n, int durMin)
      : name = TextEditingController(text: n), duration = TextEditingController(text: durMin > 0 ? durMin.toString() : ''), unit = 'Minuty' {
    // Prosta heurystyka by wyświetlić dłuższą jednostkę jeśli durMin to wielokrotność
    if (durMin > 0 && durMin % 1440 == 0) { duration.text = (durMin~/1440).toString(); unit = 'Dni'; }
    else if (durMin > 0 && durMin % 60 == 0) { duration.text = (durMin~/60).toString(); unit = 'Godziny'; }
  }

  int get asMinutes {
    final v = int.tryParse(duration.text) ?? 0;
    if (unit == 'Dni') return v * 1440;
    if (unit == 'Godziny') return v * 60;
    return v;
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
  final _instructionsCtrl = TextEditingController();
  String _selectedType = 'Napar';
  final List<String> _types = ['Napar', 'Odwar', 'Macerat', 'Nalewka', 'Maść', 'Syrop', 'Inne'];

  final List<_IngredientControllers> _ingredients = [];
  final List<_TimerControllers> _timers = [];

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      final r = widget.recipeToEdit!;
      _titleCtrl.text = r.title; _instructionsCtrl.text = r.instructions; _selectedType = r.type;
      for (var ing in r.ingredients) { _ingredients.add(_IngredientControllers(ing.speciesName, ing.plantPart, ing.amount)); }
      for (var t in r.timers) { _timers.add(_TimerControllers(t.name, t.durationMinutes)); }
    } else {
      _ingredients.add(_IngredientControllers('', '', ''));
    }
  }

  void _save() {
    if (_titleCtrl.text.isEmpty) return;

    final recipeId = widget.recipeToEdit?.id ?? const Uuid().v4();
    final remVm = context.read<ReminderViewModel>();

    // Zbieramy timery i ODPALAMY PRZYPOMNIENIA!
    List<RecipeTimer> finalTimers = [];
    for (var t in _timers) {
      if (t.name.text.isNotEmpty && t.asMinutes > 0) {
        finalTimers.add(RecipeTimer(id: const Uuid().v4(), name: t.name.text, durationMinutes: t.asMinutes));
        // Rozpoczynamy odliczanie (tylko w momencie stworzenia przepisu, można to przenieść do przycisku na podglądzie przepisu w przyszłości)
        remVm.addTimerReminder(title: "Przepis: ${_titleCtrl.text}", body: "Zakończono proces: ${t.name.text}", durationMinutes: t.asMinutes, relatedId: recipeId);
      }
    }

    final recipe = Recipe(
      id: recipeId,
      title: _titleCtrl.text, type: _selectedType, instructions: _instructionsCtrl.text,
      createdAt: widget.recipeToEdit?.createdAt ?? DateTime.now(),
      ingredients: _ingredients.where((c) => c.name.text.isNotEmpty).map((c) => RecipeIngredient(speciesName: c.name.text, plantPart: c.part.text, amount: c.amount.text)).toList(),
      timers: finalTimers,
    );

    context.read<RecipeViewModel>().addOrUpdateRecipe(recipe);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Przepis")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Tytuł przepisu", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(value: _selectedType, items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedType = v!), decoration: const InputDecoration(border: OutlineInputBorder())),

          const Divider(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Składniki:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(onPressed: () => setState(() => _ingredients.add(_IngredientControllers('', '', ''))), icon: const Icon(Icons.add), label: const Text("Składnik"))
          ]),
          ..._ingredients.asMap().entries.map((e) => Row(
            children: [
              Expanded(flex: 3, child: TextField(controller: e.value.name, decoration: const InputDecoration(hintText: "Gatunek", isDense: true))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: e.value.part, decoration: const InputDecoration(hintText: "Surowiec", isDense: true))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: e.value.amount, decoration: const InputDecoration(hintText: "Ilość", isDense: true))),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _ingredients.removeAt(e.key))),
            ],
          )),

          const Divider(height: 40),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Bloki Czasowe (Minutniki):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
            TextButton.icon(onPressed: () => setState(() => _timers.add(_TimerControllers('', 0))), icon: const Icon(Icons.timer), label: const Text("Zegar"))
          ]),
          ..._timers.asMap().entries.map((e) => Row(
            children: [
              Expanded(flex: 4, child: TextField(controller: e.value.name, decoration: const InputDecoration(hintText: "Nazwa (np. Maceracja)", isDense: true))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: TextField(controller: e.value.duration, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Czas", isDense: true))),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: DropdownButton<String>(
                value: e.value.unit, isExpanded: true,
                items: ['Minuty', 'Godziny', 'Dni'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => e.value.unit = v!),
              )),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _timers.removeAt(e.key))),
            ],
          )),

          const Divider(height: 40),
          const Text("Sposób przygotowania:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          TextField(controller: _instructionsCtrl, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), onPressed: _save, child: const Text("ZAPISZ")),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}