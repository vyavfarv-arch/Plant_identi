import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Ukrywamy pasek "Debug" w prawym rogu
      debugShowCheckedModeBanner: false,
      title: 'Moja Aplikacja',
      theme: ThemeData(
        // Ustawiamy nowoczesny styl Material 3 i kolor niebieski
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Zmienne do przechowywania stanu
  int _openCount = 0;
  int _clickCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Przy starcie ekranu ładujemy dane
    _loadData();
  }

  // Funkcja: Ładuje dane z pamięci i zwiększa licznik otwarć
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // 1. Pobieramy zapisane wartości (jeśli ich nie ma, to 0)
      int savedOpens = prefs.getInt('open_count') ?? 0;
      _clickCount = prefs.getInt('click_count') ?? 0;

      // 2. Zwiększamy licznik otwarć o 1 (bo właśnie włączyliśmy apkę)
      _openCount = savedOpens + 1;

      // 3. Wyłączamy ekran ładowania
      _isLoading = false;
    });

    // 4. Zapisujemy nową liczbę otwarć trwale w pamięci
    await prefs.setInt('open_count', _openCount);
  }

  // Funkcja: Obsługuje kliknięcie przycisku
  Future<void> _incrementClick() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _clickCount++; // Zmieniamy wartość na ekranie
    });

    // Zapisujemy wartość w pamięci telefonu
    await prefs.setInt('click_count', _clickCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Licznik Offline'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // Kręciołek, gdy dane się ładują
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Sekcja: Ile razy otwarto
            const Text('Aplikacja uruchomiona razy:', style: TextStyle(fontSize: 16)),
            Text(
              '$_openCount',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 40), // Odstęp

            // Sekcja: Ile razy kliknięto
            const Text('Przycisk wciśnięty razy:', style: TextStyle(fontSize: 16)),
            Text(
              '$_clickCount',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // Pływający przycisk na dole
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _incrementClick,
        label: const Text('Kliknij mnie'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}