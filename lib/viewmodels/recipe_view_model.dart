// lib/viewmodels/recipe_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/database_helper.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Zarządza kolekcją przepisów zielarskich przechowywanych w lokalnej bazie
 * SQLite. Udostępnia widokom aktualną, posortowaną listę receptur oraz operacje
 * wczytywania, dodawania/aktualizacji i usuwania przepisów.
 *
 * Zależności wewnętrzne:
 * - Recipe: model receptury.
 * - DatabaseHelper: trwały zapis i odczyt tabeli recipes.
 * ============================================================================
 */
class RecipeViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Recipe> _recipes = [];

  /// Przepisy są udostępniane jako lista tylko do odczytu.
  List<Recipe> get recipes => List.unmodifiable(_recipes);

  /// Wczytuje wszystkie przepisy z SQLite.
  ///
  /// Najnowsze przepisy znajdują się na początku listy.
  Future<void> loadFromDisk() async {
    final loadedRecipes = await _db.getRecipes();

    loadedRecipes.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    _recipes = loadedRecipes;
    notifyListeners();
  }

  /// Dodaje nowy przepis albo aktualizuje istniejący.
  ///
  /// DatabaseHelper.insertRecipe korzysta z ConflictAlgorithm.replace,
  /// dlatego ten sam zapis obsługuje oba przypadki na podstawie Recipe.id.
  Future<void> addOrUpdateRecipe(Recipe recipe) async {
    await _db.insertRecipe(recipe);
    await loadFromDisk();
  }

  /// Usuwa przepis o podanym ID i odświeża kolekcję.
  Future<void> deleteRecipe(String id) async {
    await _db.deleteRecipe(id);
    await loadFromDisk();
  }
}
