// lib/models/recipe.dart
import 'dart:convert';

// NOWOŚĆ: Model bloku czasowego
class RecipeTimer {
  final String id;
  final String name; // np. "Maceracja w oleju"
  final int durationMinutes; // Przechowujemy czas w minutach, żeby obsłużyć i 10 min, i 14 dni (20160 min)

  RecipeTimer({required this.id, required this.name, required this.durationMinutes});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'durationMinutes': durationMinutes};

  factory RecipeTimer.fromMap(Map<String, dynamic> map) => RecipeTimer(
    id: map['id'], name: map['name'] ?? '', durationMinutes: map['durationMinutes'] ?? 0,
  );
}

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

class Recipe {
  final String id;
  final String title;
  final String type;
  final List<RecipeIngredient> ingredients;
  final String instructions;
  final DateTime createdAt;
  final List<RecipeTimer> timers; // NOWOŚĆ: Zapisane w przepisie minutniki

  Recipe({
    required this.id, required this.title, required this.type,
    required this.ingredients, required this.instructions, required this.createdAt,
    this.timers = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'type': type,
    'ingredientsJson': jsonEncode(ingredients.map((x) => x.toMap()).toList()),
    'instructions': instructions,
    'createdAt': createdAt.toIso8601String(),
    'timersJson': jsonEncode(timers.map((x) => x.toMap()).toList()), // NOWOŚĆ
  };

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'], title: map['title'] ?? '', type: map['type'] ?? '',
    ingredients: map['ingredientsJson'] != null
        ? List<RecipeIngredient>.from(jsonDecode(map['ingredientsJson']).map((x) => RecipeIngredient.fromMap(x))) : [],
    instructions: map['instructions'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
    timers: map['timersJson'] != null
        ? List<RecipeTimer>.from(jsonDecode(map['timersJson']).map((x) => RecipeTimer.fromMap(x))) : [], // NOWOŚĆ
  );
}