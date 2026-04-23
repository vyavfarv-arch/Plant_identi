import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/observation_vm.dart';
import 'viewmodels/observation_vm.dart';
import 'viewmodels/releve_view_model.dart';
import 'viewmodels/search_filter_view_model.dart';
import 'views/home_screen.dart';
import 'services/phytosociology_service.dart'; // DODAJ TEN IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhytosociologyService().init();

  runApp(
    MultiProvider(
      providers: [
        // Ładujemy dane z dysku przy starcie dla obu VM danych
        ChangeNotifierProvider(create: (_) => ObservationViewModel()..loadFromDisk()),
        ChangeNotifierProvider(create: (_) => ReleveViewModel()..loadFromDisk()),
        ChangeNotifierProvider(create: (_) => SearchFilterViewModel()),
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