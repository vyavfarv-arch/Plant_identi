// lib/models/habitat_info.dart

class HabitatInfo {
  // --- KRYTYCZNE (Wysokie znaczenie) ---
  final String? areaType;         // Las, łąka, mokradło, zarośla, pole, pobocze, teren miejski, skraj lasu
  final String? exposure;         // N, S, E, W, Płasko
  final String? canopyCover;      // Otwarte (0-25%), Półotwarte (25-60%), Zacienione (60-85%), Gęste (>85%)

  final String? waterDynamics;    // Stale wilgotne, Sezonowo zalewane, Sezonowo wysychające, Stale suche
  final String? soilDepth;        // Płytka skalista, Średnia, Głęboka próchnowa

  // --- WAŻNE (Średnie znaczenie) ---
  final String? slopeAngle;       // Płaski (0-2°), Łagodny (2-10°), Umiarkowany (10-25°), Stromy (>25°)
  final String? litterThickness;  // Brak, Cienka (<2cm), Umiarkowana (2-10cm), Gruba (>10cm)
  final String? distanceToWater;  // Do 5m, 5-50m, Powyżej 50m

  // --- CIEKAWE (Niskie znaczenie / Notatki zielarskie) ---
  final String? deadWood;         // Brak, Leżące pnie, Próchno
  final String? landUseHistory;   // Nigdy nie uprawiane, Dawne pastwisko, Dawne pole, Aktywnie koszone, Aktywnie pasione

  // Zostawiamy stare, z których korzystałeś
  final List<String> substrateType;
  final double moisture;
  final double? ph;

  HabitatInfo({
    this.areaType, this.exposure, this.canopyCover,
    this.waterDynamics, this.soilDepth, this.slopeAngle, this.litterThickness,
    this.distanceToWater, this.deadWood, this.landUseHistory,
    this.substrateType = const [], this.moisture = 1.0, this.ph,
  });

  Map<String, dynamic> toMap() => {
    'areaType': areaType, 'exposure': exposure, 'canopyCover': canopyCover,
    'waterDynamics': waterDynamics, 'soilDepth': soilDepth,
    'slopeAngle': slopeAngle, 'litterThickness': litterThickness, 'distanceToWater': distanceToWater,
    'deadWood': deadWood, 'landUseHistory': landUseHistory,
    'substrateType': substrateType, 'moisture': moisture, 'ph': ph,
  };

  factory HabitatInfo.fromMap(Map<String, dynamic> map) => HabitatInfo(
    areaType: map['areaType'], exposure: map['exposure'], canopyCover: map['canopyCover'],
    waterDynamics: map['waterDynamics'], soilDepth: map['soilDepth'],
    slopeAngle: map['slopeAngle'], litterThickness: map['litterThickness'], distanceToWater: map['distanceToWater'],
    deadWood: map['deadWood'], landUseHistory: map['landUseHistory'],
    substrateType: List<String>.from(map['substrateType'] ?? []),
    moisture: (map['moisture'] ?? 1.0).toDouble(),
    ph: map['ph']?.toDouble(),
  );
}