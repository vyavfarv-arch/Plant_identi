// lib/models/harvest_season.dart
class HarvestSeason {
  final String material;
  final List<int> months;
  final bool reminderEnabled; // NOWOŚĆ: Flaga przypomnienia

  HarvestSeason({
    required this.material,
    required this.months,
    this.reminderEnabled = false,
  });

  Map<String, dynamic> toMap() => {
    'material': material,
    'months': months,
    'reminderEnabled': reminderEnabled ? 1 : 0, // Zapis jako INT dla SQLite
  };

  factory HarvestSeason.fromMap(Map<String, dynamic> map) {
    return HarvestSeason(
      material: map['material'] ?? '',
      months: List<int>.from(map['months'] ?? []),
      reminderEnabled: map['reminderEnabled'] == 1,
    );
  }
}