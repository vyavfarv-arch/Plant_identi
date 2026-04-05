import 'package:geolocator/geolocator.dart';

class LocationService {
  // Pobieranie aktualnej pozycji użytkownika
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Sprawdź czy usługi lokalizacji są włączone
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // GPS jest wyłączony
    }

    // 2. Sprawdź uprawnienia
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Użytkownik odrzucił prośbę
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Użytkownik zablokował uprawnienia na stałe
    }

    // 3. Pobierz pozycję
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
  }
}