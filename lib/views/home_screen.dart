// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'description_grid_screen.dart';
import 'browse_plants_screen.dart';
import 'map_screen.dart';
import 'releve_list_map_screen.dart';
import 'search_plants_screen.dart';
import 'recipe_list_screen.dart';
import 'reminder_list_screen.dart';
import 'add_plant_choice_screen.dart';
import '../viewmodels/database_view_model.dart'; // NOWOŚĆ
import '../viewmodels/observation_view_model.dart';
import '../viewmodels/releve_view_model.dart';
import '../viewmodels/recipe_view_model.dart';
import '../viewmodels/reminder_view_model.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Pulpit główny (Dashboard) aplikacji. Renderuje siatkę 9 klocków nawigacyjnych
 * dających dostęp do głównych modułów oraz deleguje akcje kopii zapasowej
 * i przywracania bazy do niezależnej warstwy DatabaseViewModel.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Widoki nawigacyjne: [DescriptionGridScreen], [BrowsePlantsScreen], [MapScreen],
 * [ReleveListMapScreen], [SearchPlantsScreen], [RecipeListScreen],
 * [ReminderListScreen], [AddPlantChoiceScreen].
 * * ViewModels: [DatabaseViewModel] do obsługi operacji na pliku bazy danych.
 * ============================================================================
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbVm = context.watch<DatabaseViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantifikator'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.eco, size: 60, color: Colors.green),
                  const SizedBox(height: 30),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildGridButton(
                          context,
                          title: 'Dodaj roślinę', icon: Icons.add_a_photo, color: Colors.green,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlantChoiceScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Opisz rośliny', icon: Icons.edit_note, color: Colors.teal,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DescriptionGridScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Katalog', icon: Icons.library_books, color: Colors.blue,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowsePlantsScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Mapa roślin', icon: Icons.map, color: Colors.orange,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Obszary', icon: Icons.layers, color: Colors.indigo,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReleveListMapScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Szukaj roślin', icon: Icons.search_rounded, color: Colors.deepOrange,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPlantsScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Przepisy', icon: Icons.menu_book, color: Colors.pink,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeListScreen())),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Baza i Kopia', icon: Icons.cloud_sync, color: Colors.brown,
                          onPressed: () => _showBackupRestoreOptions(context),
                        ),
                        _buildGridButton(
                          context,
                          title: 'Przypomnienia', icon: Icons.notifications_active, color: Colors.amber.shade700,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderListScreen())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (dbVm.isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  void _showBackupRestoreOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Zarządzanie bazą danych"),
        content: const Text("Wybierz czynność dla bazy danych i zestawów Machine Learning:"),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share, color: Colors.brown),
            label: const Text("EKSPORT ML (CSV)", style: TextStyle(color: Colors.brown)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DatabaseViewModel>().exportML();
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.cloud_upload, color: Colors.green),
            label: const Text("UTWÓRZ KOPIĘ (.DB)", style: TextStyle(color: Colors.green)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DatabaseViewModel>().performBackup();
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.cloud_download, color: Colors.indigo),
            label: const Text("PRZYWRÓĆ KOPIĘ (.DB)", style: TextStyle(color: Colors.indigo)),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<DatabaseViewModel>().performRestore();
              if (success && context.mounted) {
                // Po udanym wgraniu pliku .db, odświeżamy pozostałe kontrolery z poziomu widoku:
                await context.read<ObservationViewModel>().loadFromDisk();
                await context.read<ReleveViewModel>().loadFromDisk();
                await context.read<RecipeViewModel>().loadFromDisk();
                await context.read<ReminderViewModel>().loadFromDisk();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kopia bazy danych została pomyślnie przywrócona!"), backgroundColor: Colors.green),
                );
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANULUJ", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}