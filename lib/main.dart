import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/observation_vm.dart';
import 'views/camera_screen.dart';

void main() async {
  // 1. Wymagane, gdy używamy asynchronicznego main (np. dla aparatu/GPS)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // 2. MultiProvider pozwala na dodawanie kolejnych ViewModeli w przyszłości
    MultiProvider(
      providers: [
        // Tworzymy ObservationViewModel i od razu wywołujemy ..init()
        // aby przygotować aparat i GPS zanim użytkownik wejdzie na ekran
        ChangeNotifierProvider(
          create: (_) => ObservationViewModel()..init(),
        ),

        // Tutaj w przyszłości dodasz MapViewModel:
        // ChangeNotifierProvider(create: (_) => MapViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant ID - Rejestrator',

      // Personalizacja wyglądu pod tematykę roślinną
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        // Styl dla przycisków i AppBarów
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),

      // Startujemy od razu od ekranu aparatu
      home: const CameraScreen(),
    );
  }
}