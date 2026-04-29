// lib/views/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/recipe_view_model.dart';
import 'recipe_form_screen.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeVm = context.watch<RecipeViewModel>();
    final recipes = recipeVm.recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Twoje Przepisy"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'add') Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen()));
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'add', child: Text('Dodaj nowy przepis', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
      body: recipes.isEmpty
          ? const Center(child: Text("Brak przepisów. Kliknij 3 kropki, aby dodać."))
          : ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (ctx, i) {
          final r = recipes[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: const Icon(Icons.menu_book, color: Colors.teal),
              ),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${r.type} | Składniki: ${r.ingredients.length} \nDodano: ${DateFormat('yyyy-MM-dd').format(r.createdAt)}"),
              children: [
                const Divider(),
                ...r.ingredients.map((ing) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ing.speciesName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Text("${ing.plantPart}  -  ", style: const TextStyle(color: Colors.grey)),
                      Text(ing.amount, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )).toList(),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(alignment: Alignment.centerLeft, child: Text(r.instructions)),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeFormScreen(recipeToEdit: r))),
                      icon: const Icon(Icons.edit), label: const Text("Edytuj"),
                    ),
                    TextButton.icon(
                      onPressed: () => recipeVm.deleteRecipe(r.id),
                      icon: const Icon(Icons.delete, color: Colors.red), label: const Text("Usuń", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}