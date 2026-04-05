import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/observation_vm.dart';
import 'viewmodels/plants_view_model.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ObservationViewModel()),
        ChangeNotifierProvider(create: (_) => PlantsViewModel()..loadFromDisk()),
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
      title: 'Plantifikator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.black,
        ),
      ),

      home: const HomeScreen(),
    );
  }
}