// lib/models/harvest_season.dart
class HarvestSeason {
  final String material; // np. "Kwiaty", "Kora"
  final List<int> months; // np. [3, 4] (Marzec, Kwiecień)

  HarvestSeason({required this.material, required this.months});

  Map<String, dynamic> toMap() => {
    'material': material,
    'months': months,
  };

  factory HarvestSeason.fromMap(Map<String, dynamic> map) {
    return HarvestSeason(
      material: map['material'] ?? '',
      months: List<int>.from(map['months'] ?? []),
    );
  }
}