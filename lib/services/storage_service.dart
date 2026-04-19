import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_observation.dart';
import '../models/releve.dart';


class StorageService {
  static const String _key = 'plant_observations';
  static const String _releveKey = 'phytosociological_releves';

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


// Zapisywanie listy obszarów
  Future<void> saveReleves(List<Releve> releves) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      releves.map((r) => r.toMap()).toList(),
    );
    await prefs.setString(_releveKey, encodedData);
  }

// Odczytywanie listy obszarów
  Future<List<Releve>> loadReleves() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_releveKey);
    if (data == null) return [];

    final List<dynamic> decodedData = jsonDecode(data);
    return decodedData.map((item) => Releve.fromMap(item)).toList();
  }
}