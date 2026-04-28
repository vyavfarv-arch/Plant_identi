// lib/models/sought_plant.dart
import 'dart:convert';

class SoughtPlant {
  final String id;
  final String polishName;
  final String latinName;

  // Preferencje do filtrowania płatów (algorytm)
  final double? prefPhMin;
  final double? prefPhMax;
  final List<String> prefSubstrate;
  final double? prefMoisture;
  final double? prefSunlight;

  SoughtPlant({
    required this.id,
    required this.polishName,
    required this.latinName,
    this.prefPhMin,
    this.prefPhMax,
    this.prefSubstrate = const [],
    this.prefMoisture,
    this.prefSunlight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'polishName': polishName,
      'latinName': latinName,
      'prefPhMin': prefPhMin,
      'prefPhMax': prefPhMax,
      'prefSubstrateJson': jsonEncode(prefSubstrate),
      'prefMoisture': prefMoisture,
      'prefSunlight': prefSunlight,
    };
  }

  factory SoughtPlant.fromMap(Map<String, dynamic> map) {
    return SoughtPlant(
      id: map['id'],
      polishName: map['polishName'] ?? '',
      latinName: map['latinName'] ?? '',
      prefPhMin: map['prefPhMin']?.toDouble(),
      prefPhMax: map['prefPhMax']?.toDouble(),
      prefSubstrate: map['prefSubstrateJson'] != null ? List<String>.from(jsonDecode(map['prefSubstrateJson'])) : [],
      prefMoisture: map['prefMoisture']?.toDouble(),
      prefSunlight: map['prefSunlight']?.toDouble(),
    );
  }
}