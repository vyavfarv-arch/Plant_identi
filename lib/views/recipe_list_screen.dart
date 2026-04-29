// lib/views/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/recipe_view_model.dart';
import '../viewmodels/reminder_view_model.dart';
import 'recipe_form_screen.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeVm = context.watch<RecipeViewModel>();
    final remVm = context.read<ReminderViewModel>();
    final recipes = recipeVm.recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Twoje Przepisy"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: "Nowy przepis", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen()))),
        ],
      ),
      body: recipes.isEmpty
          ? const Center(child: Text("Brak przepisów. Kliknij + aby dodać."))
          : ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (ctx, i) {
          final r = recipes[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ExpansionTile(
              leading: CircleAvatar(backgroundColor: Colors.teal.shade100, child: const Icon(Icons.menu_book, color: Colors.teal)),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${r.type} | Składniki: ${r.ingredients.length} \nDodano: ${DateFormat('yyyy-MM-dd').format(r.createdAt)}"),
              children: [
                // Ograniczenie wielkości dropdowna (np. do 2/3 ekranu)
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Składniki:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(height: 5),
                        ...r.ingredients.map((ing) => Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ing.speciesName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            Text("${ing.plantPart}  -  ", style: const TextStyle(color: Colors.grey)),
                            Text(ing.amount, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        )),
                        const Divider(height: 30),
                        const Text("Przygotowanie:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(height: 10),

                        // Rysowanie przeplatanych KROKÓW (Tekst i Minutniki)
                        ...r.steps.map((step) {
                          if (step.type == 'text') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(step.content, style: const TextStyle(fontSize: 15, height: 1.4)),
                            );
                          } else {
                            // Przycisk odpalający Minutnik!
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.indigo.shade200)),
                              child: ListTile(
                                leading: const Icon(Icons.timer, color: Colors.indigo),
                                title: Text(step.content, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("Czas: ${_formatMinutes(step.durationMinutes)}"),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                  onPressed: () {
                                    remVm.addTimerReminder(
                                        title: "Przepis: ${r.title}",
                                        body: "Zakończono: ${step.content}",
                                        durationMinutes: step.durationMinutes,
                                        relatedId: r.id
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Uruchomiono odliczanie: ${step.content}!"), backgroundColor: Colors.green));
                                  },
                                  child: const Text("START"),
                                ),
                              ),
                            );
                          }
                        }),

                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeFormScreen(recipeToEdit: r))), icon: const Icon(Icons.edit), label: const Text("Edytuj")),
                            TextButton.icon(onPressed: () => recipeVm.deleteRecipe(r.id), icon: const Icon(Icons.delete, color: Colors.red), label: const Text("Usuń", style: TextStyle(color: Colors.red))),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMinutes(int mins) {
    if (mins >= 1440 && mins % 1440 == 0) return "${mins ~/ 1440} Dni";
    if (mins >= 60 && mins % 60 == 0) return "${mins ~/ 60} Godzin";
    return "$mins Minut";
  }
}