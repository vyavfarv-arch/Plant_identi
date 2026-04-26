// lib/models/habitat_info.dart

class HabitatInfo {
  final List<String> substrateType;
  final double moisture;
  final double? ph;
  final List<String> litterLayer;
  final double sunlight;  // NOWE: Indeks nasłonecznienia (0-4)
  final double pollution; // NOWE: Indeks zanieczyszczenia (0-4)

  HabitatInfo({
    this.substrateType = const [],
    this.moisture = 1.0,
    this.ph,
    this.litterLayer = const [],
    this.sunlight = 2.0,  // Domyślnie: Półcień
    this.pollution = 0.0, // Domyślnie: Dzikie
  });

  Map<String, dynamic> toMap() {
    return {
      'substrateType': substrateType,
      'moisture': moisture,
      'ph': ph,
      'litterLayer': litterLayer,
      'sunlight': sunlight,
      'pollution': pollution,
    };
  }

  factory HabitatInfo.fromMap(Map<String, dynamic> map) {
    return HabitatInfo(
      substrateType: List<String>.from(map['substrateType'] ?? []),
      moisture: (map['moisture'] ?? 1.0).toDouble(),
      ph: map['ph']?.toDouble(),
      litterLayer: List<String>.from(map['litterLayer'] ?? []),
      sunlight: (map['sunlight'] ?? 2.0).toDouble(),
      pollution: (map['pollution'] ?? 0.0).toDouble(),
    );
  }
}