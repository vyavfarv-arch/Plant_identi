class HabitatInfo {
  final List<String> substrateType; // Multiselect
  final double moisture; // Slider 0-3 (Sucho, Świeżo, Wilgotno, Mokro)
  final double? ph; // Opcjonalne pH
  final List<String> litterLayer; // Multiselect

  HabitatInfo({
    this.substrateType = const [],
    this.moisture = 1.0,
    this.ph,
    this.litterLayer = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'substrateType': substrateType,
      'moisture': moisture,
      'ph': ph,
      'litterLayer': litterLayer,
    };
  }

  factory HabitatInfo.fromMap(Map<String, dynamic> map) {
    return HabitatInfo(
      substrateType: List<String>.from(map['substrateType'] ?? []),
      moisture: (map['moisture'] ?? 1.0).toDouble(),
      ph: map['ph']?.toDouble(),
      litterLayer: List<String>.from(map['litterLayer'] ?? []),
    );
  }
}