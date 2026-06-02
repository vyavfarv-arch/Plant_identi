// lib/views/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      body: SafeArea(child:  recipes.isEmpty
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
              subtitle: Text("${r.type} | Składniki: ${r.ingredients.length}"),
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HIERARCHIA 1: Wyżej nadany tytuł przepisu
                        Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(height: 4),

                        // HIERARCHIA 2: Typ produktu (napar / inne etc)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text("Typ: ${r.type}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                        ),
                        const SizedBox(height: 12),

                        // HIERARCHIA 3: Notatka wyświetlana jako opis zamiast starego układu
                        if (r.note.isNotEmpty) ...[
                          Text(r.note, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87, fontStyle: FontStyle.italic)),
                        ] else ...[
                          const Text("Brak dodatkowych notatek do tego przepisu.", style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],

                        const Divider(height: 30),
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

                        ...r.steps.map((step) {
                          if (step.type == 'text') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(step.content, style: const TextStyle(fontSize: 15, height: 1.4)),
                            );
                          } else {
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
                                        body: "Trwa proces: ${step.content}",
                                        durationMinutes: step.durationMinutes,
                                        relatedId: r.id
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text("Rozpoczęto odliczanie: ${step.content}"),
                                        backgroundColor: Colors.indigo
                                    ));
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
      ),),
    );
  }

  String _formatMinutes(int mins) {
    if (mins >= 1440 && mins % 1440 == 0) return "${mins ~/ 1440} Dni";
    if (mins >= 60 && mins % 60 == 0) return "${mins ~/ 60} Godzin";
    return "$mins Minut";
  }
}