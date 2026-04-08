import 'package:geolocator/geolocator.dart';

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