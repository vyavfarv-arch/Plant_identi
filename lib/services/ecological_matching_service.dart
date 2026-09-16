// lib/services/ecological_matching_service.dart
import '../models/releve.dart';
import '../models/habitat_info.dart';
import '../models/plant_species.dart';
import '../models/has_ellenberg_profile.dart';

/// Ciągły profil ekologiczny obszaru wyliczony z HabitatInfo.
/// Wartości są następnie zaokrąglane do najbliższego węzła Ellenberga
/// podczas porównania z dyskretnym profilem gatunku.
/// Pojedyncze oszacowanie osi Ellenberga z informacją o jakości estymacji.
/// confidence nie oznacza prawdopodobieństwa biologicznego; mówi jedynie,
/// jak mocne przesłanki terenowe miała aplikacja do wyznaczenia value.
class EnvironmentalEstimate {
  final double? value;
  final double confidence;

  const EnvironmentalEstimate({
    required this.value,
    required this.confidence,
  });

  const EnvironmentalEstimate.unknown()
      : value = null,
        confidence = 0.0;

  bool get isKnown => value != null && confidence > 0.0;
}

/// Profil siedliska powstający wyłącznie z prostych obserwacji terenowych.
/// Każda oś ma osobną wartość oraz confidence.
class ContinuousEcologicalProfile {
  final EnvironmentalEstimate sunlight;     // L
  final EnvironmentalEstimate moisture;     // F
  final EnvironmentalEstimate reaction;     // R
  final EnvironmentalEstimate nitrogen;     // N
  final EnvironmentalEstimate temperature;  // T
  final EnvironmentalEstimate continent;    // K
  final EnvironmentalEstimate salinity;     // S

  const ContinuousEcologicalProfile({
    required this.sunlight,
    required this.moisture,
    required this.reaction,
    required this.nitrogen,
    required this.temperature,
    required this.continent,
    required this.salinity,
  });
}

/// Stan pojedynczej osi po porównaniu rośliny z siedliskiem.
class EcologicalAxisMatch {
  final String axis;
  final double? match;
  final double? areaValue;
  final double estimateConfidence;
  final int? areaNode;
  final int? plantState;

  const EcologicalAxisMatch({
    required this.axis,
    required this.match,
    required this.areaValue,
    this.estimateConfidence = 0.0,
    required this.areaNode,
    required this.plantState,
  });

  bool get isKnown => match != null;
  bool get isGood => match == 1.0;
  bool get isTolerated => match == 0.5;
  bool get isConflict => match == 0.0;

  String get symbol {
    if (!isKnown) return '?';
    if (isGood) return '✓';
    if (isTolerated) return '~';
    return '✗';
  }
}

class ContinuousEcologicalMatchingResult {
  final double score;

  /// Łączna jakość danych użytych do wyniku.
  /// Dla L/F/R/N/T/K/S bierze pod uwagę confidence translatora,
  /// a dla pH bezpośredni pomiar ma confidence = 1.
  final double confidence;

  final Map<String, EcologicalAxisMatch> axisMatches;
  final Map<String, String> diagnostics;
  final List<String> conflicts;

  const ContinuousEcologicalMatchingResult({
    required this.score,
    required this.confidence,
    required this.axisMatches,
    required this.diagnostics,
    required this.conflicts,
  });

  bool get isPotentialMatch => score >= 0.75;
  bool get hasConflicts => conflicts.isNotEmpty;
}

class AdvancedEcologicalTranslator {
  static EnvironmentalEstimate _estimate({
    required double value,
    required double confidence,
    required double min,
    required double max,
  }) {
    return EnvironmentalEstimate(
      value: value.clamp(min, max).toDouble(),
      confidence: confidence.clamp(0.0, 1.0).toDouble(),
    );
  }

  static ContinuousEcologicalProfile translateArea(HabitatInfo h) {
    // -----------------------------------------------------------------
    // L — światło.
    // Brak canopyDensity oznacza brak danych, a nie pełną otwartość.
    // Ekspozycja i nachylenie są tylko korektami istniejącego pomiaru
    // zwarcia — same nie wystarczają do wyznaczenia L.
    // -----------------------------------------------------------------
    final int? canopy = h.canopyDensity;
    EnvironmentalEstimate sunlight;

    if (canopy == null) {
      sunlight = const EnvironmentalEstimate.unknown();
    } else {
      double l = 10.0 - canopy;
      double lConfidence = 0.75;

      final bool slopeKnown = h.slopeAngle != null;
      final bool exposureKnown = h.exposure != null;

      if (slopeKnown &&
          exposureKnown &&
          h.slopeAngle != "Płaski (0-2°)") {
        if (h.exposure == "S") l += 0.8;
        if (h.exposure == "N") l -= 0.8;
        lConfidence += 0.15;
      }

      if (h.areaType != null) {
        lConfidence += 0.10;
        if (h.areaType == "Las" && canopy >= 6) {
          l -= 0.3;
        }
      }

      sunlight = _estimate(
        value: l,
        confidence: lConfidence,
        min: 1.0,
        max: 9.0,
      );
    }

    // -----------------------------------------------------------------
    // F — wilgotność.
    // Najmocniejsza oś w obecnym HabitatInfo: kontekst hydrologiczny,
    // obecność/ruch wody oraz retencja wynikająca z rodzaju podłoża.
    // Bez żadnej z tych wskazówek zwracamy unknown zamiast sztucznego F=4.
    // -----------------------------------------------------------------
    double? f;
    double fConfidence = 0.0;

    final context = h.hydrologicalContext ?? "";
    if (context.contains("Skrajnie suche")) {
      f = 1.5;
      fConfidence = 0.80;
    } else if (context.contains("Wilgotne")) {
      f = 7.0;
      fConfidence = 0.80;
    } else if (context.contains("Mokre")) {
      f = 9.0;
      fConfidence = 0.85;
    } else if (context.contains("Stale zalane")) {
      f = 11.0;
      fConfidence = 0.90;
    }

    final movement = h.waterMovement ?? "";
    if (movement.isNotEmpty) {
      f ??= 4.0;
      if (movement.contains("Stojąca")) f += 1.0;
      if (movement.contains("Źródliskowa")) f += 0.5;
      if (movement.contains("Płynąca")) f += 0.2;
      fConfidence += 0.20;
    }

    if (h.substrateType.isNotEmpty) {
      f ??= 4.0;
      if (h.substrateType.any((s) => s.contains("Torfowa"))) f += 1.5;
      if (h.substrateType.any((s) => s.contains("Gliniasta"))) f += 0.4;
      if (h.substrateType.any((s) => s.contains("Piaszczysta"))) f -= 1.0;
      fConfidence += 0.15;
    }

    final moisture = f == null
        ? const EnvironmentalEstimate.unknown()
        : _estimate(value: f, confidence: fConfidence, min: 1.0, max: 12.0);

    // -----------------------------------------------------------------
    // R — reakcja siedliska.
    // ŚWIADOMIE NIE używamy h.ph. pH jest osobną osią plantScore().
    // Obecny formularz daje tylko słabe pośrednie przesłanki dla R.
    // Dlatego R ma niższe confidence i pozostaje unknown, gdy ich brak.
    // -----------------------------------------------------------------
    double? r;
    double rConfidence = 0.0;

    if (h.substrateType.any((s) => s.contains("Torfowa")) &&
        movement.contains("Stojąca")) {
      r = 3.0;
      rConfidence = 0.45;
    } else if (h.substrateType.any((s) => s.contains("Ziemia leśna")) &&
        h.areaType == "Las") {
      r = 4.5;
      rConfidence = 0.35;
    } else if (h.substrateType.any((s) => s.contains("Gliniasta"))) {
      r = 6.0;
      rConfidence = 0.30;
    }

    final reaction = r == null
        ? const EnvironmentalEstimate.unknown()
        : _estimate(value: r, confidence: rConfidence, min: 1.0, max: 9.0);

    // -----------------------------------------------------------------
    // N — zasobność w azot / żyzność.
    // Opieramy się na widocznych śladach użytkowania i powierzchni gleby.
    // Nie wymagamy żadnego pomiaru chemicznego.
    // -----------------------------------------------------------------
    double? n;
    double nConfidence = 0.0;
    final impact = h.humanImpact ?? "";

    if (impact.contains("Śmietnisko")) {
      n = 8.5;
      nConfidence = 0.75;
    } else if (impact.contains("Orka")) {
      n = 7.5;
      nConfidence = 0.65;
    } else if (impact.contains("Wypas")) {
      n = 5.0;
      nConfidence = 0.55;
    }

    final cover = h.soilSurfaceCover ?? "";
    if (cover.isNotEmpty) {
      n ??= 3.5;
      if (cover.contains("Gruba ściółka")) n += 0.8;
      if (cover.contains("Zwarta darń")) n += 1.2;
      nConfidence += 0.15;
    }

    if (h.substrateType.any((s) => s.contains("Piaszczysta"))) {
      n ??= 3.5;
      n -= 1.0;
      nConfidence += 0.10;
    }

    final nitrogen = n == null
        ? const EnvironmentalEstimate.unknown()
        : _estimate(value: n, confidence: nConfidence, min: 1.0, max: 9.0);

    // -----------------------------------------------------------------
    // T — temperatura siedliskowa.
    // To słaba estymacja mikroklimatu, nie pomiar temperatury.
    // Wymagamy konkretnych przesłanek zamiast domyślnego T=5.
    // -----------------------------------------------------------------
    double? t;
    double tConfidence = 0.0;

    if (sunlight.isKnown &&
        sunlight.value! > 6.0 &&
        h.exposure == "S" &&
        h.slopeAngle == "Stromy (>25°)") {
      t = 6.5;
      tConfidence = 0.45;
    }

    if (h.areaType == "Las" && canopy != null && canopy >= 6) {
      t ??= 5.0;
      t -= 1.0;
      tConfidence += 0.30;
    }

    if (movement.contains("Stojąca")) {
      t ??= 5.0;
      t -= 0.5;
      tConfidence += 0.15;
    }

    final temperature = t == null
        ? const EnvironmentalEstimate.unknown()
        : _estimate(value: t, confidence: tConfidence, min: 1.0, max: 9.0);

    // -----------------------------------------------------------------
    // K — kontynentalizm.
    // Z lokalnego opisu pojedynczego płatu można go oszacować tylko słabo.
    // Zachowujemy dotychczasowe obserwowalne przesłanki, ale z niskim confidence.
    // -----------------------------------------------------------------
    double? k;
    double kConfidence = 0.0;

    if (canopy != null &&
        canopy <= 2 &&
        (h.areaType == "Pole" || h.areaType == "Łąka")) {
      k = 4.3;
      kConfidence = 0.25;
    } else if (canopy != null && canopy >= 6 && h.areaType == "Las") {
      k = 3.0;
      kConfidence = 0.25;
    }

    final continent = k == null
        ? const EnvironmentalEstimate.unknown()
        : _estimate(value: k, confidence: kConfidence, min: 1.0, max: 9.0);

    // -----------------------------------------------------------------
    // S — zasolenie.
    // Widoczne/znane zimowe solenie jest mocną przesłanką.
    // Samo pobocze drogi jest słabszą przesłanką.
    // Brak takich danych NIE oznacza S=0.
    // -----------------------------------------------------------------
    double? s;
    double sConfidence = 0.0;

    if (impact.contains("Zimowe solenie")) {
      s = 2.5;
      sConfidence = 0.80;
    } else if (h.areaType == "Pobocze drogi") {
      s = 2.0;
      sConfidence = 0.40;
    }

    final salinity = s == null
        ? const EnvironmentalEstimate.unknown()
        : _estimate(value: s, confidence: sConfidence, min: 0.0, max: 9.0);

    return ContinuousEcologicalProfile(
      sunlight: sunlight,
      moisture: moisture,
      reaction: reaction,
      nitrogen: nitrogen,
      temperature: temperature,
      continent: continent,
      salinity: salinity,
    );
  }
}

class EcologicalMatchingService {
  // Kary służą do zasady czynnika ograniczającego.
  // Nie są wagami poszczególnych osi.
  static const double _toleratedPenalty = 0.90;
  static const double _conflictPenalty = 0.40;

  // pH jest wielkością ciągłą, dlatego potrzebujemy pasa tolerancji
  // poza zakresem preferowanym gatunku.
  static const double _phToleranceMargin = 1.0;

  /// Zamienia stan 0/1/2 profilu gatunku na wspólną skalę match.
  static double _stateToMatch(int state) {
    if (state >= 2) return 1.0;
    if (state == 1) return 0.5;
    return 0.0;
  }

  /// Porównuje jedną oś Ellenberga.
  ///
  /// Pusty profil gatunku = brak wiedzy -> match == null.
  /// Jeżeli profil istnieje, ale nie zawiera węzła obszaru,
  /// warunki są traktowane jako nieprzyjazne -> match == 0.
  static EcologicalAxisMatch _calculateEllenbergMatch({
    required String axis,
    required EnvironmentalEstimate areaEstimate,
    required Map<int, int> plantProfile,
    required int minValue,
    required int maxValue,
  }) {
    if (!areaEstimate.isKnown || plantProfile.isEmpty) {
      return EcologicalAxisMatch(
        axis: axis,
        match: null,
        areaValue: areaEstimate.value,
        estimateConfidence: areaEstimate.confidence,
        areaNode: null,
        plantState: null,
      );
    }

    final int node =
        areaEstimate.value!.round().clamp(minValue, maxValue);
    final int state = (plantProfile[node] ?? 0).clamp(0, 2);

    return EcologicalAxisMatch(
      axis: axis,
      match: _stateToMatch(state),
      areaValue: areaEstimate.value,
      estimateConfidence: areaEstimate.confidence,
      areaNode: node,
      plantState: state,
    );
  }

  /// pH:
  /// - wewnątrz [prefPhMin, prefPhMax] -> dobre (1.0)
  /// - do 1.0 pH poza zakresem -> tolerowane (0.5)
  /// - dalej -> nieprzyjazne (0.0)
  /// - brak pomiaru pH lub brak zakresu gatunku -> null
  ///
  /// Używamy wyłącznie faktycznie podanego h.ph. Nie używamy tutaj
  /// wartości pH oszacowanej przez translator, aby nie udawać pomiaru.
  static EcologicalAxisMatch _calculatePhMatch({
    required double? areaPh,
    required double? plantMin,
    required double? plantMax,
  }) {
    if (areaPh == null || plantMin == null || plantMax == null) {
      return EcologicalAxisMatch(
        axis: 'pH',
        match: null,
        areaValue: areaPh,
        estimateConfidence: 0.0,
        areaNode: null,
        plantState: null,
      );
    }

    final low = plantMin <= plantMax ? plantMin : plantMax;
    final high = plantMin <= plantMax ? plantMax : plantMin;

    double match;
    if (areaPh >= low && areaPh <= high) {
      match = 1.0;
    } else {
      final distance = areaPh < low ? low - areaPh : areaPh - high;
      match = distance <= _phToleranceMargin ? 0.5 : 0.0;
    }

    return EcologicalAxisMatch(
      axis: 'pH',
      match: match,
      areaValue: areaPh,
      estimateConfidence: 1.0,
      areaNode: null,
      plantState: match == 1.0 ? 2 : (match == 0.5 ? 1 : 0),
    );
  }

  /// GŁÓWNA FUNKCJA: plantScore(plant, habitat).
  ///
  /// 1. HabitatInfo -> profil obszaru.
  /// 2. L/F/R/N/T/K/S -> {0.0, 0.5, 1.0}.
  /// 3. pH -> {0.0, 0.5, 1.0}, jeżeli istnieje pomiar.
  /// 4. Bazą jest średnia znanych osi.
  /// 5. Każda tolerowana oś lekko obniża wynik.
  /// 6. Każdy konflikt silnie obniża wynik (czynnik ograniczający).
  /// 7. confidence informuje, jak duża część profilu była znana.
  static ContinuousEcologicalMatchingResult scorePlantInArea(
    Releve area,
    HasEllenbergProfile species,
  ) {
    if (area.habitat == null) {
      return const ContinuousEcologicalMatchingResult(
        score: 0.0,
        confidence: 0.0,
        axisMatches: {},
        diagnostics: {},
        conflicts: [],
      );
    }

    final habitat = area.habitat!;
    final areaProfile = AdvancedEcologicalTranslator.translateArea(habitat);

    final axes = <String, EcologicalAxisMatch>{
      'L': _calculateEllenbergMatch(
        axis: 'L',
        areaEstimate: areaProfile.sunlight,
        plantProfile: species.ellenbergL,
        minValue: 1,
        maxValue: 9,
      ),
      'F': _calculateEllenbergMatch(
        axis: 'F',
        areaEstimate: areaProfile.moisture,
        plantProfile: species.ellenbergF,
        minValue: 1,
        maxValue: 12,
      ),
      'R': _calculateEllenbergMatch(
        axis: 'R',
        areaEstimate: areaProfile.reaction,
        plantProfile: species.ellenbergR,
        minValue: 1,
        maxValue: 9,
      ),
      'N': _calculateEllenbergMatch(
        axis: 'N',
        areaEstimate: areaProfile.nitrogen,
        plantProfile: species.ellenbergN,
        minValue: 1,
        maxValue: 9,
      ),
      'T': _calculateEllenbergMatch(
        axis: 'T',
        areaEstimate: areaProfile.temperature,
        plantProfile: species.ellenbergT,
        minValue: 1,
        maxValue: 9,
      ),
      'K': _calculateEllenbergMatch(
        axis: 'K',
        areaEstimate: areaProfile.continent,
        plantProfile: species.ellenbergK,
        minValue: 1,
        maxValue: 9,
      ),
      'S': _calculateEllenbergMatch(
        axis: 'S',
        areaEstimate: areaProfile.salinity,
        plantProfile: species.ellenbergS,
        minValue: 0,
        maxValue: 9,
      ),
      'pH': _calculatePhMatch(
        areaPh: habitat.ph,
        plantMin: species.prefPhMin,
        plantMax: species.prefPhMax,
      ),
    };

    final known = axes.values.where((axis) => axis.isKnown).toList();
    final diagnostics = <String, String>{
      for (final entry in axes.entries) entry.key: entry.value.symbol,
    };
    final conflicts = axes.entries
        .where((entry) => entry.value.isConflict)
        .map((entry) => entry.key)
        .toList(growable: false);

    if (known.isEmpty) {
      return ContinuousEcologicalMatchingResult(
        score: 0.0,
        confidence: 0.0,
        axisMatches: Map.unmodifiable(axes),
        diagnostics: Map.unmodifiable(diagnostics),
        conflicts: const [],
      );
    }

    // Osie oszacowane pewniej mają większy wpływ na bazowy wynik.
    // pH, jako bezpośrednio podana wartość, ma estimateConfidence = 1.0.
    final totalEvidenceWeight = known.fold<double>(
      0.0,
      (sum, axis) => sum + axis.estimateConfidence,
    );

    if (totalEvidenceWeight <= 0.0) {
      return ContinuousEcologicalMatchingResult(
        score: 0.0,
        confidence: 0.0,
        axisMatches: Map.unmodifiable(axes),
        diagnostics: Map.unmodifiable(diagnostics),
        conflicts: List.unmodifiable(conflicts),
      );
    }

    final baseScore = known.fold<double>(
          0.0,
          (sum, axis) => sum + (axis.match! * axis.estimateConfidence),
        ) /
        totalEvidenceWeight;

    // Siła kary również zależy od jakości estymacji osi.
    // Konflikt oparty na słabej przesłance nie powinien niszczyć wyniku
    // tak samo jak konflikt oparty na bardzo pewnej informacji.
    double limitingFactor = 1.0;
    for (final axis in known) {
      if (axis.isConflict) {
        limitingFactor *=
            1.0 - ((1.0 - _conflictPenalty) * axis.estimateConfidence);
      } else if (axis.isTolerated) {
        limitingFactor *=
            1.0 - ((1.0 - _toleratedPenalty) * axis.estimateConfidence);
      }
    }

    final score = (baseScore * limitingFactor).clamp(0.0, 1.0);

    // Maksymalnie 8 pełnych źródeł informacji.
    // Np. trzy osie o confidence 0.5 dają 1.5 / 8, nie 3 / 8.
    final confidence = (totalEvidenceWeight / 8.0).clamp(0.0, 1.0);

    return ContinuousEcologicalMatchingResult(
      score: score,
      confidence: confidence,
      axisMatches: Map.unmodifiable(axes),
      diagnostics: Map.unmodifiable(diagnostics),
      conflicts: List.unmodifiable(conflicts),
    );
  }

  /// Alias zachowany dla starszego kodu.
  static ContinuousEcologicalMatchingResult calculateCompatibility(
    Releve area,
    HasEllenbergProfile species,
  ) {
    return scorePlantInArea(area, species);
  }

  /// Kierunek 1: roślina -> ranking obszarów.
  static List<MapEntry<Releve, ContinuousEcologicalMatchingResult>>
      findPotentialAreasForPlant(
    HasEllenbergProfile species,
    List<Releve> areas, {
    bool onlyPotentialMatches = true,
  }) {
    final results = <MapEntry<Releve, ContinuousEcologicalMatchingResult>>[];

    for (final area in areas) {
      final match = scorePlantInArea(area, species);
      if (!onlyPotentialMatches || match.isPotentialMatch) {
        results.add(MapEntry(area, match));
      }
    }

    results.sort((a, b) {
      final scoreCompare = b.value.score.compareTo(a.value.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.value.confidence.compareTo(a.value.confidence);
    });
    return results;
  }

  static bool isSevereMismatch(Releve area, PlantSpecies? species) {
    if (species == null || area.habitat == null) return false;

    final result = scorePlantInArea(area, species);

    // Konflikt na choć jednej znanej osi jest sam w sobie sygnałem
    // wymagającym sprawdzenia. Niski score pozostaje drugim kryterium.
    return result.hasConflicts || result.score < 0.55;
  }

  /// Kierunek 2: obszar -> ranking roślin.
  static List<MapEntry<PlantSpecies, ContinuousEcologicalMatchingResult>>
      findPotentialPlantsForArea(
    Releve area,
    List<PlantSpecies> dictionary, {
    bool onlyPotentialMatches = true,
  }) {
    final results =
        <MapEntry<PlantSpecies, ContinuousEcologicalMatchingResult>>[];

    for (final species in dictionary) {
      final match = scorePlantInArea(area, species);
      if (!onlyPotentialMatches || match.isPotentialMatch) {
        results.add(MapEntry(species, match));
      }
    }

    results.sort((a, b) {
      final scoreCompare = b.value.score.compareTo(a.value.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.value.confidence.compareTo(a.value.confidence);
    });
    return results;
  }
}
