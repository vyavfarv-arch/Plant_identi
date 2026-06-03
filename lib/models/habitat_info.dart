// lib/models/habitat_info.dart

class HabitatInfo {
  // --- ZUNIFIKOWANE I ROZWINIĘTE OPCJE SIEDLISKOWE (Źródło prawdy dla całej aplikacji) ---

  static const List<String> areaTypeOptions = [
    "Las", "Łąka", "Mokradło", "Zarośla", "Pole", "Pobocze drogi", "Nadrzecze / Brzeg", "Skraj lasu"
  ];

  // Opisy dla 9-stopniowej skali gęstości okapu i zacienienia (zastępuje dawne canopyCover)
  static const List<String> canopyDensityLabels = [
    "1 - Pełna otwartość (0-10% cienia, zupełnie otwarte)",
    "2 - Pojedyncze przeszkody (rzadkie drzewa/krzewy)",
    "3 - Bardzo luźne zarośla / Świetlisty sad",
    "4 - Świetlisty las / Polana leśna",
    "5 - Umiarkowane zacienienie (las mieszany, mozaika)",
    "6 - Wyraźne zacienienie (gęsty grąd/buczyna letnia)",
    "7 - Silne zacienienie (wielowarstwowy las z podszytem)",
    "8 - Głęboki, mroczny cień (gęsty młodnik świerkowy, jary)",
    "9 - Całkowity mrok (90-100% odcięcia, jaskinie/szczeliny)"
  ];

  // Zastępuje dawną „dynamikę wody” – klucz do natlenienia i stagnacji
  static const List<String> waterMovementOptions = [
    "Brak / Stojąca (zastoisko, bagno)",
    "Sącząca się / Źródliskowa",
    "Płynąca (strumień, rzeka)",
    "Brak wód powierzchniowych"
  ];

  static const List<String> substrateOptions = [
    "Ziemia leśna / Próchniczna",
    "Piaszczysta / Luźna",
    "Gliniasta / Zbita",
    "Torfowa / Bagienna",
    "Kamienista / Gruz"
  ];

  static const List<String> exposureOptions = ["N", "S", "E", "W", "Płasko"];

  static const List<String> slopeAngleOptions = [
    "Płaski (0-2°)",
    "Łagodny (2-10°)",
    "Umiarkowany (10-25°)",
    "Stromy (>25°)"
  ];

  // Zastępuje dawną chwilową wilgotność gleby stabilnym reżimem hydrologicznym
  static const List<String> hydrologicalContextOptions = [
    "Skrajnie suche / Drenowane (nasypy, wydmy)",
    "Świeże / Umiarkowane (typowa gleba łąkowa/leśna)",
    "Wilgotne / Stałe zasilanie podziemne (dno doliny)",
    "Mokre / Okresowo podtapiane (łęgi, olsy, blisko wody)",
    "Stale zalane / Szuwarowe (bagno, szuwar)"
  ];

  // Zastępuje dawną grubość ściółki funkcjonalną strukturą okrywy (konkurencja i izolacja)
  static const List<String> soilSurfaceCoverOptions = [
    "Gleba naga / Brak okrywy (czysta ziemia, orka)",
    "Rzadka okrywa (cienka ściółka, mchy)",
    "Gruba ściółka organiczna (liście, igliwie)",
    "Zwarta darń trawiasta (gęste pastwiska/łąki)"
  ];

  static const List<String> humanImpactOptions = [
    "Brak / Naturalne sukcesje",
    "Wypas zwierząt / Koszenie",
    "Intensywne deptanie / Ścieżka",
    "Orka / Nawożenie rolnicze",
    "Składowisko odpadów / Śmietnisko",
    "Zimowe solenie / Droga"
  ];

  // --- NOWE POLA MODELU ---
  final String? areaType;
  final int canopyDensity; // Reprezentacja numeryczna skali 1 - 9
  final String? waterMovement;
  final List<String> substrateType;
  final String? exposure;
  final String? slopeAngle;
  final String? hydrologicalContext;
  final String? soilSurfaceCover;
  final String? humanImpact;
  final double? ph;

  HabitatInfo({
    this.areaType,
    this.canopyDensity = 1, // Domyślnie pełne światło/słońce
    this.waterMovement,
    this.substrateType = const [],
    this.exposure,
    this.slopeAngle,
    this.hydrologicalContext,
    this.soilSurfaceCover,
    this.humanImpact,
    this.ph,
  });

  Map<String, dynamic> toMap() => {
    'areaType': areaType,
    'canopyDensity': canopyDensity,
    'waterMovement': waterMovement,
    'substrateType': substrateType,
    'exposure': exposure,
    'slopeAngle': slopeAngle,
    'hydrologicalContext': hydrologicalContext,
    'soilSurfaceCover': soilSurfaceCover,
    'humanImpact': humanImpact,
    'ph': ph,
  };

  factory HabitatInfo.fromMap(Map<String, dynamic> map) {
    return HabitatInfo(
      areaType: map['areaType'],
      // Zabezpieczenie rzutowania typów z bazy danych SQLite
      canopyDensity: map['canopyDensity'] != null ? (map['canopyDensity'] as num).toInt() : 1,
      waterMovement: map['waterMovement'],
      substrateType: map['substrateType'] != null ? List<String>.from(map['substrateType']) : const [],
      exposure: map['exposure'],
      slopeAngle: map['slopeAngle'],
      hydrologicalContext: map['hydrologicalContext'],
      soilSurfaceCover: map['soilSurfaceCover'],
      humanImpact: map['humanImpact'],
      ph: map['ph']?.toDouble(),
    );
  }
}