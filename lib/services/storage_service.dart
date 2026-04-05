import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_observation.dart';

class StorageService {
  static const String _key = 'plant_observations';

  // Zapisywanie całej listy obserwacji
  Future<void> saveObservations(List<PlantObservation> observations) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      observations.map((o) => o.toMap()).toList(),
    );
    await prefs.setString(_key, encodedData);
  }

  // Odczytywanie listy z pamięci
  Future<List<PlantObservation>> loadObservations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    final List<dynamic> decodedData = jsonDecode(data);
    return decodedData.map((item) => PlantObservation.fromMap(item)).toList();
  }
}