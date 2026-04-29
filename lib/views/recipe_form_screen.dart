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
  _IngredientControllers(String n, String p, String a)
      : name = TextEditingController(text: n), part = TextEditingController(text: p), amount = TextEditingController(text: a);
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

  @override
  void initState() {
    super.initState();
    if (widget.recipeToEdit != null) {
      _titleCtrl.text = widget.recipeToEdit!.title;
      _instructionsCtrl.text = widget.recipeToEdit!.instructions;
      _selectedType = widget.recipeToEdit!.type;
      for (var ing in widget.recipeToEdit!.ingredients) {
        _ingredients.add(_IngredientControllers(ing.speciesName, ing.plantPart, ing.amount));
      }
    } else {
      _ingredients.add(_IngredientControllers('', '', '')); // Jeden domyślny na start
    }
  }

  void _addIngredient() => setState(() => _ingredients.add(_IngredientControllers('', '', '')));
  void _removeIngredient(int index) => setState(() => _ingredients.removeAt(index));

  void _save() {
    if (_titleCtrl.text.isEmpty) return;

    final recipe = Recipe(
      id: widget.recipeToEdit?.id ?? const Uuid().v4(),
      title: _titleCtrl.text,
      type: _selectedType,
      instructions: _instructionsCtrl.text,
      createdAt: widget.recipeToEdit?.createdAt ?? DateTime.now(),
      ingredients: _ingredients.where((c) => c.name.text.isNotEmpty).map((c) => RecipeIngredient(
        speciesName: c.name.text, plantPart: c.part.text, amount: c.amount.text,
      )).toList(),
    );

    context.read<RecipeViewModel>().addOrUpdateRecipe(recipe);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipeToEdit == null ? "Dodaj Przepis" : "Edytuj Przepis"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Tytuł przepisu (np. Maść nagietkowa)", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: "Typ preparatu", border: OutlineInputBorder()),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Składniki:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
              TextButton.icon(onPressed: _addIngredient, icon: const Icon(Icons.add), label: const Text("Dodaj Składnik")),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: _ingredients.length,
            itemBuilder: (ctx, i) {
              final c = _ingredients[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: TextField(controller: c.name, decoration: const InputDecoration(labelText: "Gatunek", isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: c.part, decoration: const InputDecoration(labelText: "Surowiec", hintText: "Kwiat", isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: c.amount, decoration: const InputDecoration(labelText: "Gramatura", hintText: "50g", isDense: true))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeIngredient(i)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text("Sposób przygotowania:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 10),
          TextField(controller: _instructionsCtrl, maxLines: 6, decoration: const InputDecoration(hintText: "Opisz krok po kroku...", border: OutlineInputBorder())),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: _save,
            child: const Text("ZAPISZ PRZEPIS", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}