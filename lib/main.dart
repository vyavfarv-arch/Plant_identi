import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/observation_view_model.dart'; // Jedyny plik dla obserwacji
import 'viewmodels/releve_view_model.dart'; // Zarządzanie obszarami
import 'viewmodels/search_filter_view_model.dart'; // Filtrowanie
import 'services/phytosociology_service.dart'; //
import 'views/home_screen.dart'; // DODANO: Brakujący import dla HomeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhytosociologyService().init();

  runApp(
    MultiProvider(
      providers: [
        // Zaktualizowano: ObservationViewModel w Twoim pliku obsługuje zarówno sesję aparatu,
        // jak i bazę danych roślin (loadFromDisk)
        ChangeNotifierProvider(create: (_) => ObservationViewModel()..loadFromDisk()),

        // Obsługa obszarów, ich nazw i hierarchii
        ChangeNotifierProvider(create: (_) => ReleveViewModel()..loadFromDisk()),

        // Globalny stan filtrów (zakresy dat, rodziny, multiselect)
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