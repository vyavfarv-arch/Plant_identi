// lib/viewmodels/recipe_view_model.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/database_helper.dart';
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Zarządza bazą wiedzy użytkownika w zakresie receptur i przepisów zielarskich.
 * Odpowiada za asynchroniczne pobieranie danych z dysku, chronologiczne sortowanie
 * przepisów (najnowsze na górze), dodawanie nowych form, edycję oraz ich usuwanie.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/recipe.dart':
 * - Klasa [Recipe]: Model danych reprezentujący strukturę receptury zielarskiej,
 * wykorzystywany do zasilania interfejsu list i formularzy.
 * * Z pliku '../services/database_helper.dart':
 * - Klasa [DatabaseHelper]: Komponent dostępu do danych, realizujący operacje
 * zapisu i kasowania rekordów w tabeli 'recipes'.
 * ============================================================================
 */
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