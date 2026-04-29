// lib/viewmodels/recipe_view_model.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/database_helper.dart';

class RecipeViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Recipe> _recipes = [];

  List<Recipe> get recipes => _recipes;

  Future<void> loadFromDisk() async {
    _recipes = await _db.getRecipes();
    // Sortuj najnowsze na górze
    _recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> addOrUpdateRecipe(Recipe recipe) async {
    await _db.insertRecipe(recipe);
    await loadFromDisk();
  }

  Future<void> deleteRecipe(String id) async {
    await _db.deleteRecipe(id);
    await loadFromDisk();
  }
}