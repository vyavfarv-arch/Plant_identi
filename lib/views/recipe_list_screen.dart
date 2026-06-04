// lib/views/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recipe_view_model.dart';
import '../viewmodels/reminder_view_model.dart';
import 'recipe_form_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  String? _selectedFilterLabel;

  @override
  Widget build(BuildContext context) {
    final recipeVm = context.watch<RecipeViewModel>();
    final remVm = context.read<ReminderViewModel>();

    // Pobierz unikalne labele ze wszystkich przepisów do okna filtrowania
    final allLabels = recipeVm.recipes.expand((r) => r.labels).toSet().toList()..sort();

    // Filtruj listę przepisów
    final filteredRecipes = recipeVm.recipes.where((r) {
      if (_selectedFilterLabel == null) return true;
      return r.labels.contains(_selectedFilterLabel);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Twoje Przepisy"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: _selectedFilterLabel != null ? Colors.orange : null),
            tooltip: "Filtruj za pomocą labeli",
            onPressed: () => _showFilterDialog(context, allLabels),
          ),
          IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Nowy przepis",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeFormScreen()))
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedFilterLabel != null)
              Container(
                color: Colors.teal.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filtrowanie: #$_selectedFilterLabel (${filteredRecipes.length} przepisów)",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade900, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilterLabel = null),
                      child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: filteredRecipes.isEmpty
                  ? const Center(child: Text("Brak przepisów pasujących do wybranej etykiety."))
                  : ListView.builder(
                itemCount: filteredRecipes.length,
                itemBuilder: (ctx, i) {
                  final r = filteredRecipes[i];
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
                                Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Text("Typ: ${r.type}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (r.labels.isNotEmpty)
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: r.labels.map((lbl) => Container(
                                              margin: const EdgeInsets.only(right: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange.shade200)),
                                              child: Text("#$lbl", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                            )).toList(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, List<String> allLabels) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Filtruj przepisy etykietą"),
        content: allLabels.isEmpty
            ? const Text("Brak zdefiniowanych etykiet w Twoich przepisach.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            : SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: allLabels.map((l) => ListTile(
              leading: const Icon(Icons.tag, color: Colors.orange),
              title: Text(l),
              selected: _selectedFilterLabel == l,
              onTap: () {
                setState(() => _selectedFilterLabel = l);
                Navigator.pop(ctx);
              },
            )).toList(),
          ),
        ),
        actions: [
          if (_selectedFilterLabel != null)
            TextButton(
              onPressed: () {
                setState(() => _selectedFilterLabel = null);
                Navigator.pop(ctx);
              },
              child: const Text("WYCZYŚĆ FILTR", style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ZAMKNIJ")),
        ],
      ),
    );
  }

  String _formatMinutes(int mins) {
    if (mins >= 1440 && mins % 1440 == 0) return "${mins ~/ 1440} Dni";
    if (mins >= 60 && mins % 60 == 0) return "${mins ~/ 60} Godzin";
    return "$mins Minut";
  }
}