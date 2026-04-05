import 'dart:convert';

class PlantObservation {
  final String id;
  final List<String> photoPaths;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final Map<String, String> characteristics; // Fizjonomia (to co robiliśmy wcześniej)

  // NOWE POLA SZCZEGÓŁOWEGO OPISU:
  String? abundance;
  DateTime? observationDate;

  // A. Taksonomia
  String? family;
  String? genus;
  String? species;
  String? subspecies;

  // B. Nazewnictwo
  String? latinName;
  String? polishName;
  String? localName; // To pole będzie główną nazwą wyświetlaną

  // C. Pewność
  String? certainty; // wysoki / średni / niski
  String? idDoubts;

  // D. Cechy diagnostyczne
  String? keyMorphologicalTraits;
  String? microscopicTraits;
  String? differences;
  String? confusingSpecies;

  // E. Wykorzystanie
  String? plantUsage;

  PlantObservation({
    required this.id,
    required this.photoPaths,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.characteristics,
    this.abundance,
    this.observationDate,
    this.family,
    this.genus,
    this.species,
    this.subspecies,
    this.latinName,
    this.polishName,
    this.localName,
    this.certainty,
    this.idDoubts,
    this.keyMorphologicalTraits,
    this.microscopicTraits,
    this.differences,
    this.confusingSpecies,
    this.plantUsage,
  });

  // Pomocniczy getter do wyświetlania nazwy w menu i na mapie
  String get displayName => (localName != null && localName!.isNotEmpty)
      ? localName!
      : (polishName != null && polishName!.isNotEmpty) ? polishName! : "Nieznana roślina";

  bool get isComplete =>
      abundance != null &&
          displayName != "Nieznana roślina" &&
          observationDate != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPaths': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'characteristics': jsonEncode(characteristics),
      'abundance': abundance,
      'observationDate': observationDate?.toIso8601String(),
      'family': family,
      'genus': genus,
      'species': species,
      'subspecies': subspecies,
      'latinName': latinName,
      'polishName': polishName,
      'localName': localName,
      'certainty': certainty,
      'idDoubts': idDoubts,
      'keyMorphologicalTraits': keyMorphologicalTraits,
      'microscopicTraits': microscopicTraits,
      'differences': differences,
      'confusingSpecies': confusingSpecies,
      'plantUsage': plantUsage,
    };
  }

  factory PlantObservation.fromMap(Map<String, dynamic> map) {
    return PlantObservation(
      id: map['id'] ?? '',
      photoPaths: List<String>.from(jsonDecode(map['photoPaths'])),
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      characteristics: Map<String, String>.from(jsonDecode(map['characteristics'])),
      abundance: map['abundance'],
      observationDate: map['observationDate'] != null ? DateTime.parse(map['observationDate']) : null,
      family: map['family'],
      genus: map['genus'],
      species: map['species'],
      subspecies: map['subspecies'],
      latinName: map['latinName'],
      polishName: map['polishName'],
      localName: map['localName'],
      certainty: map['certainty'],
      idDoubts: map['idDoubts'],
      keyMorphologicalTraits: map['keyMorphologicalTraits'],
      microscopicTraits: map['microscopicTraits'],
      differences: map['differences'],
      confusingSpecies: map['confusingSpecies'],
      plantUsage: map['plantUsage'],
    );
  }
}