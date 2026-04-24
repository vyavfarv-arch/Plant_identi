class PlantSpecies {
  final String latinName;
  final String polishName;
  final List<String> associatedSyntaxa; // np. ["Alnion glutinosae", "Fagion sylvaticae"]
  final List<String> preferredSubstrates; // ["Torf", "Glina"]
  final double preferredMoistureMin;
  final double preferredMoistureMax;
  final int floweringStartMonth;
  final int floweringEndMonth;
  final String properties; // Właściwości lecznicze itp.

  PlantSpecies({
    required this.latinName,
    required this.polishName,
    required this.associatedSyntaxa,
    required this.preferredSubstrates,
    required this.preferredMoistureMin,
    required this.preferredMoistureMax,
    required this.floweringStartMonth,
    required this.floweringEndMonth,
    required this.properties,
  });
}