// lib/models/recipe.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Definiuje modele struktur danych dla zielarskich przepisów i receptur. Składa
 * się z klas: [RecipeIngredient] (składniki), [RecipeStep] (zarządzanie krokami tekstowymi
 * oraz mechanicznymi minutnikami) i [Recipe] (główny pojemnik receptury z obsługą etykiet).
 *
 * Zależności wewnętrzne (pliki z /lib):
 * - Brak bezpośrednich importów innych plików z katalogu /lib. Plik stanowi niezależną,
 * zamkniętą domenę danych zarządzaną bezpośrednio przez warstwę RecipeViewModel.
 * ============================================================================
 */
class RecipeIngredient {
  final String speciesName;
  final String plantPart;
  final String amount;

  RecipeIngredient({required this.speciesName, required this.plantPart, required this.amount});

  Map<String, dynamic> toMap() => {'speciesName': speciesName, 'plantPart': plantPart, 'amount': amount};
  factory RecipeIngredient.fromMap(Map<String, dynamic> map) => RecipeIngredient(
    speciesName: map['speciesName'] ?? '', plantPart: map['plantPart'] ?? '', amount: map['amount'] ?? '',
  );
}

class RecipeStep {
  final String id;
  final String type;
  final String content;
  final int durationMinutes;

  RecipeStep({String? id, required this.type, required this.content, this.durationMinutes = 0}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {'id': id, 'type': type, 'content': content, 'durationMinutes': durationMinutes};

  factory RecipeStep.fromMap(Map<String, dynamic> map) => RecipeStep(
    id: map['id'], type: map['type'] ?? 'text', content: map['content'] ?? '', durationMinutes: map['durationMinutes'] ?? 0,
  );
}

class Recipe {
  final String id;
  final String title;
  final String type;
  final String note;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> labels; // NOWOŚĆ: Grupowanie w labele
  final DateTime createdAt;

  Recipe({
    required this.id, required this.title, required this.type,
    this.note = '',
    required this.ingredients, required this.steps,
    this.labels = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'type': type,
    'instructions': note,
    'ingredientsJson': jsonEncode(ingredients.map((x) => x.toMap()).toList()),
    'stepsJson': jsonEncode(steps.map((x) => x.toMap()).toList()),
    'labelsJson': jsonEncode(labels), // Serializacja tabeli etykiet
    'createdAt': createdAt.toIso8601String(),
  };

  factory Recipe.fromMap(Map<String, dynamic> map) {
    List<String> parsedLabels = [];
    if (map['labelsJson'] != null && map['labelsJson'].toString().isNotEmpty) {
      try {
        parsedLabels = List<String>.from(jsonDecode(map['labelsJson']));
      } catch (_) {}
    }

    return Recipe(
      id: map['id'], title: map['title'] ?? '', type: map['type'] ?? '',
      note: map['instructions'] ?? '',
      ingredients: map['ingredientsJson'] != null ? List<RecipeIngredient>.from(jsonDecode(map['ingredientsJson']).map((x) => RecipeIngredient.fromMap(x))) : [],
      steps: map['stepsJson'] != null ? List<RecipeStep>.from(jsonDecode(map['stepsJson']).map((x) => RecipeStep.fromMap(x))) : [],
      labels: parsedLabels,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}