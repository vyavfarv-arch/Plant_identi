// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/observation_view_model.dart';
import 'viewmodels/releve_view_model.dart';
import 'viewmodels/search_filter_view_model.dart';
import 'viewmodels/recipe_view_model.dart';
import 'viewmodels/reminder_view_model.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => ReminderViewModel()..loadFromDisk()),
      ],
      child: MaterialApp(
        title: 'Plantifikator',
        debugShowCheckedModeBanner: false, // ZMIANA: Usunięcie paska DEBUG w prawym górnym rogu
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}