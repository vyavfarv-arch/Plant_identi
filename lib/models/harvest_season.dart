// lib/models/harvest_season.dart
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