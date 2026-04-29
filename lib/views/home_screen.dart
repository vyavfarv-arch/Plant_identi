// lib/views/home_screen.dart
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'description_grid_screen.dart';
import 'browse_plants_screen.dart';
import 'map_screen.dart';
import 'releve_list_map_screen.dart';
import "search_plants_screen.dart";
import 'recipe_list_screen.dart';
import '../services/data_export_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantifikator'),
        elevation: 0,
      ),
      body: Padding(
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
                    title: 'Dodaj roślinę',
                    icon: Icons.add_a_photo,
                    color: Colors.green,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Opisz rośliny',
                    icon: Icons.edit_note,
                    color: Colors.teal,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DescriptionGridScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Magazyn',
                    icon: Icons.library_books,
                    color: Colors.blue,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowsePlantsScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Mapa roślin',
                    icon: Icons.map,
                    color: Colors.orange,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Obszary',
                    icon: Icons.layers,
                    color: Colors.indigo,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReleveListMapScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Szukaj roślin',
                    icon: Icons.search_rounded,
                    color: Colors.deepOrange,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPlantsScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Przepisy',
                    icon: Icons.menu_book,
                    color: Colors.pink,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeListScreen())),
                  ),
                  _buildGridButton(
                    context,
                    title: 'Eksport ML',
                    icon: Icons.import_export,
                    color: Colors.brown,
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator()),
                      );
                      await DataExportService().exportDataForML();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed
  }) {
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}