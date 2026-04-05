import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'description_grid_screen.dart';
import 'browse_plants_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant ID - Menu')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.eco, size: 80, color: Colors.green),
              const SizedBox(height: 40),

              _buildMenuButton(context,
                  title: '1. Dodaj roślinę',
                  icon: Icons.add_a_photo,
                  color: Colors.green,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()))
              ),
              const SizedBox(height: 20),

              // NOWY PRZYCISK (Punkt 4 z Twojej listy)
              _buildMenuButton(context,
                  title: '2. Opisz Spotkane Rośliny',
                  icon: Icons.edit_note,
                  color: Colors.teal,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DescriptionGridScreen()))
              ),
              const SizedBox(height: 20),

              _buildMenuButton(context,
                  title: '3. Przeglądaj rośliny',
                  icon: Icons.library_books,
                  color: Colors.blue,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowsePlantsScreen()))
              ),
              const SizedBox(height: 20),

              _buildMenuButton(context,
                  title: '4. Pokaż mapę roślin',
                  icon: Icons.map,
                  color: Colors.orange,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()))
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
    );
  }
}