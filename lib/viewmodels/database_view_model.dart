// lib/viewmodels/database_view_model.dart
import 'package:flutter/material.dart';
import '../services/data_export_service.dart';

/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Kontroler logiki biznesowej zarządzający stanem operacji bazodanowych (MVVM).
 * Odpowiada za obsługę asynchronicznych akcji eksportu danych ML, tworzenia kopii
 * zapasowej oraz przywracania bazy danych, udostępniając flagi stanu ładowania i błędów.
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z katalogu '../services/':
 * - Klasa [DataExportService]: Komponent wykonawczy realizujący niskopoziomowe operacje I/O bazy danych.
 * ============================================================================
 */
class DatabaseViewModel extends ChangeNotifier {
  final DataExportService _exportService = DataExportService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<void> exportML() async {
    _setLoading(true);
    _setError(null);
    try {
      await _exportService.exportDataForML();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> performBackup() async {
    _setLoading(true);
    _setError(null);
    try {
      await _exportService.backupDatabase();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> performRestore() async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _exportService.restoreDatabase();
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}