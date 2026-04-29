// lib/models/recipe.dart
import 'dart:convert';

class RecipeIngredient {
  final String speciesName;
  final String plantPart;
  final String amount;

  RecipeIngredient({required this.speciesName, required this.plantPart, required this.amount});

  Map<String, dynamic> toMap() => {'speciesName': speciesName, 'plantPart': plantPart, 'amount': amount};

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) => RecipeIngredient(
    speciesName: map['speciesName'] ?? '',
    plantPart: map['plantPart'] ?? '',
    amount: map['amount'] ?? '',
  );
}

class Recipe {
  final String id;
  final String title;
  final String type;
  final List<RecipeIngredient> ingredients;
  final String instructions;
  final DateTime createdAt;

  Recipe({
    required this.id, required this.title, required this.type,
    required this.ingredients, required this.instructions, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type,
    'ingredientsJson': jsonEncode(ingredients.map((x) => x.toMap()).toList()),
    'instructions': instructions,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    id: map['id'],
    title: map['title'] ?? '',
    type: map['type'] ?? '',
    ingredients: map['ingredientsJson'] != null
        ? List<RecipeIngredient>.from(jsonDecode(map['ingredientsJson']).map((x) => RecipeIngredient.fromMap(x)))
        : [],
    instructions: map['instructions'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );
}                                                                                   