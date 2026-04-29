// lib/models/recipe.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';

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

// NOWOŚĆ: Krok przepisu. Może to być tekst albo minutnik.
class RecipeStep {
  final String id;
  final String type; // 'text' LUB 'timer'
  final String content; // Tekst instrukcji LUB nazwa minutnika
  final int durationMinutes; // Używane tylko gdy type == 'timer'

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
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps; // ZMIANA: Lista przeplatających się kroków i minutników
  final DateTime createdAt;

  Recipe({
    required this.id, required this.title, required this.type,
    required this.ingredients, required this.steps, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'type': type,
    'ingredientsJson': jsonEncode(ingredients.map((x) => x.toMap()).toList()),
    'stepsJson': jsonEncode(steps.map((x) => x.toMap()).toList()),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'], title: map['title'] ?? '', type: map['type'] ?? '',
    ingredients: map['ingredientsJson'] != null ? List<RecipeIngredient>.from(jsonDecode(map['ingredientsJson']).map((x) => RecipeIngredient.fromMap(x))) : [],
    steps: map['stepsJson'] != null ? List<RecipeStep>.from(jsonDecode(map['stepsJson']).map((x) => RecipeStep.fromMap(x))) : [],
    createdAt: DateTime.parse(map['createdAt']),
  );
}