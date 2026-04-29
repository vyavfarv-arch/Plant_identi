import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/observation_view_model.dart'; // Jedyny plik dla obserwacji
import 'viewmodels/releve_view_model.dart'; // Zarządzanie obszarami
import 'viewmodels/search_filter_view_model.dart'; // Filtrowanie
import 'services/phytosociology_service.dart'; //
import 'views/home_screen.dart';
import 'viewmodels/recipe_view_model.dart';
import 'viewmodels/reminder_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ObservationViewModel()..loadFromDisk()),
        ChangeNotifierProvider(create: (_) => ReleveViewModel()..loadFromDisk()),
        ChangeNotifierProvider(create: (_) => SearchFilterViewModel()..loadSoughtPlants()),
        ChangeNotifierProvider(create: (_) => RecipeViewModel()..loadFromDisk()),

        // NOWOŚĆ: Rejestrujemy ViewModel Przypomnień
        ChangeNotifierProvider(create: (_) => ReminderViewModel()..loadFromDisk()),
      ],
      child: MaterialApp(
        title: 'Plantifikator',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}