// lib/models/harvest_season.dart

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Reprezentuje model danych pojedynczego sezonu zbioru konkretnego surowca zielarskiego
 * (np. ziele, kłącze, owoce). Definiuje ramy czasowe (datę rozpoczęcia i zakończenia)
 * oraz zarządza stanem powiadomień/przypomnień dla danego surowca.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich importów plików wewnętrznych. Wykorzystywany jako model
 * składowy (kompozycja) w encjach [PlantSpecies], [SoughtPlant] oraz [PlantObservation].
 * ============================================================================
 */

class HarvestSeason {
  final String material;
  final DateTime? startDate; // ZMIANA: Początek zbiorów (z kalendarza)
  final DateTime? endDate;   // ZMIANA: Koniec zbiorów (z kalendarza)
  final bool reminderEnabled;

  HarvestSeason({
    required this.material,
    this.startDate,
    this.endDate,
    this.reminderEnabled = false,
  });

  Map<String, dynamic> toMap() => {
    'material': material,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'reminderEnabled': reminderEnabled ? 1 : 0,
  };

  factory HarvestSeason.fromMap(Map<String, dynamic> map) {
    return HarvestSeason(
      material: map['material'] ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      reminderEnabled: map['reminderEnabled'] == 1,
    );
  }
}