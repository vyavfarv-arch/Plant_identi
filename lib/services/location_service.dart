import 'package:geolocator/geolocator.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Moduł geolokalizacyjny. Odpowiada za weryfikację uprawnień systemowych, żądanie
 * dostępu do GPS oraz pobieranie aktualnych współrzędnych geograficznych urządzenia.
 * Posiada wbudowany guard czasowy (`timeLimit: Duration(seconds: 5)`), zapobiegający
 * zawieszeniu interfejsu aplikacji w gęstym lesie lub przy braku sygnału.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich importów innych plików z /lib. Dostarcza dane pozycji (`Position`)
 * dla widoków map oraz kontrolerów ewidencji okazów i płatów.
 * ============================================================================
 */
class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    try {
      // DODANO: timeLimit zapobiega nieskończonemu oczekiwaniu
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // Jeśli upłynie czas (TimeoutException), zwracamy null, aby nie blokować apki
      print("Błąd lokalizacji (prawdopodobnie timeout): $e");
      return null;
    }
  }
}