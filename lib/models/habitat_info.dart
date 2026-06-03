// lib/models/habitat_info.dart
import 'dart:convert';

class HabitatInfo {
  static const List<String> areaTypeOptions = ["Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Nadrzecze / Brzeg", "Skraj lasu"];
  static const List<String> canopyDensityLabels = ["1 - Pełna otwartość", "2 - Pojedyncze przeszkody", "3 - Luźne zarośla", "4 - Świetlisty las", "5 - Umiarkowane zacienienie", "6 - Wyraźne zacienienie", "7 - Silne zacienienie", "8 - Głęboki, mroczny cień", "9 - Całkowity mrok"];
  static const List<String> waterMovementOptions = ["Brak / Stojąca (zastoisko, bagno)", "Sącząca się / Źródliskowa", "Płynąca (strumień, rzeka)", "Brak wód powierzchniowych"];
  static const List<String> substrateOptions = ["Ziemia leśna / Próchniczna", "Piaszczysta / Luźna", "Gliniasta / Zbita", "Torfowa / Bagienna", "Kamienista / Gruz"];
  static const List<String> exposureOptions = ["N", "S", "E", "W", "Płasko"];
  static const List<String> slopeAngleOptions = ["Płaski (0-2°)", "Łagodny (2-10°)", "Umiarkowany (10-25°)", "Stromy (>25°)"];
  static const List<String> hydrologicalContextOptions = ["Skrajnie suche / Drenowane", "Świeże / Umiarkowane", "Wilgotne / Stałe zasilanie podziemne", "Mokre / Okresowo podtapiane", "Stale zalane / Szuwarowe"];
  static const List<String> soilSurfaceCoverOptions = ["Gleba naga / Brak okrywy", "Rzadka okrywa", "Gruba ściółka organiczna", "Zwarta darń trawiasta"];
  static const List<String> humanImpactOptions = ["Brak / Naturalne sukcesje", "Wypas zwierząt / Koszenie", "Intensywne deptanie / Ścieżka", "Orka / Nawożenie rolnicze", "Składowisko odpadów / Śmietnisko", "Zimowe solenie / Droga"];

  final String? areaType;
  final int canopyDensity;
  final String? waterMovement;
  final List<String> substrateType;
  final String? exposure;
  final String? slopeAngle;
  final String? hydrologicalContext;
  final String? soilSurfaceCover;
  final String? humanImpact;
  final double? ph;

  HabitatInfo({this.areaType, this.canopyDensity = 1, this.waterMovement, this.substrateType = const [], this.exposure, this.slopeAngle, this.hydrologicalContext, this.soilSurfaceCover, this.humanImpact, this.ph});

  Map<String, dynamic> toMap() => {
    'areaType': areaType,
    'canopyDensity': canopyDensity,
    'waterMovement': waterMovement,
    'substrateType': jsonEncode(substrateType), // FIX: Serializacja listy do JSON
    'exposure': exposure,
    'slopeAngle': slopeAngle,
    'hydrologicalContext': hydrologicalContext,
    'soilSurfaceCover': soilSurfaceCover,
    'humanImpact': humanImpact,
    'ph': ph,
  };

  factory HabitatInfo.fromMap(Map<String, dynamic> map) {
    List<String> parsedSubstrates = [];
    if (map['substrateType'] != null) {
      try { parsedSubstrates = List<String>.from(jsonDecode(map['substrateType'])); } catch (_) { parsedSubstrates = []; }
    }
    return HabitatInfo(
      areaType: map['areaType'],
      canopyDensity: map['canopyDensity'] != null ? (map['canopyDensity'] as num).toInt() : 1,
      waterMovement: map['waterMovement'],
      substrateType: parsedSubstrates,
      exposure: map['exposure'], slopeAngle: map['slopeAngle'], hydrologicalContext: map['hydrologicalContext'], soilSurfaceCover: map['soilSurfaceCover'], humanImpact: map['humanImpact'], ph: map['ph']?.toDouble(),
    );
  }
}