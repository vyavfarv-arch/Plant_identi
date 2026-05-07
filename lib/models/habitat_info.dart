// lib/models/habitat_info.dart

class HabitatInfo {
  // --- STATYCZNE LISTY OPCJI (Źródło prawdy dla UI) ---
  static const List<String> areaTypeOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Ugór"];
  static const List<String> exposureOptions = ["N", "S", "E", "W", "Płasko"];
  static const List<String> canopyCoverOptions = ["Otwarte (0-25%)", "Półotwarte (25-60%)", "Zacienione (60-85%)", "Gęste (>85%)"];
  static const List<String> waterDynamicsOptions = ["Stale wilgotne", "Sezonowo zalewane", "Sezonowo wysychające", "Stale suche"];
  static const List<String> slopeAngleOptions = ["Płaski (0-2°)", "Łagodny (2-10°)", "Umiarkowany (10-25°)", "Stromy (>25°)"];
  static const List<String> litterThicknessOptions = ["Brak", "Cienka (<2cm)", "Umiarkowana (2-10cm)", "Gruba (>10cm)"];
  static const List<String> distanceToWaterOptions = ["Do 5m", "5-50m", "Powyżej 50m"];
  static const List<String> substrateOptions = ["Piasek", "Glina", "Torf", "Skała wapienna", "Skała krzemianowa"];
  static const List<String> moistureLabels = ["Sucho", "Świeżo", "Wilgotno", "Mokro"];

  // --- POLA MODELU ---
  final String? areaType;
  final String? exposure;
  final String? canopyCover;
  final String? waterDynamics;
  final String? slopeAngle;
  final String? litterThickness;
  final String? distanceToWater;

  final List<String> substrateType;
  final double moisture;
  final double? ph;

  HabitatInfo({
    this.areaType, this.exposure, this.canopyCover,
    this.waterDynamics, this.slopeAngle, this.litterThickness,
    this.distanceToWater,
    this.substrateType = const [], this.moisture = 1.0, this.ph,
  });

  Map<String, dynamic> toMap() => {
    'areaType': areaType, 'exposure': exposure, 'canopyCover': canopyCover,
    'waterDynamics': waterDynamics,
    'slopeAngle': slopeAngle, 'litterThickness': litterThickness, 'distanceToWater': distanceToWater,
    'substrateType': substrateType, 'moisture': moisture, 'ph': ph,
  };

  factory HabitatInfo.fromMap(Map<String, dynamic> map) => HabitatInfo(
    areaType: map['areaType'], exposure: map['exposure'], canopyCover: map['canopyCover'],
    waterDynamics: map['waterDynamics'],
    slopeAngle: map['slopeAngle'], litterThickness: map['litterThickness'], distanceToWater: map['distanceToWater'],
    substrateType: List<String>.from(map['substrateType'] ?? []),
    moisture: (map['moisture'] ?? 1.0).toDouble(),
    ph: map['ph']?.toDouble(),
  );
}