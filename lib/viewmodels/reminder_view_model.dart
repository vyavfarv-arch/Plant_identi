// lib/viewmodels/reminder_view_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_reminder.dart';
import '../services/database_helper.dart';

class ReminderViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<AppReminder> _reminders = [];

  List<AppReminder> get reminders => _reminders;
  List<AppReminder> get pendingReminders => _reminders.where((r) => !r.isCompleted).toList();

  Future<void> loadFromDisk() async {
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  // Ustawianie minutnika (np. z przepisu na 14 dni)
  Future<void> addTimerReminder({required String title, required String body, required int durationMinutes, required String relatedId}) async {
    final scheduledTime = DateTime.now().add(Duration(minutes: durationMinutes));

    final reminder = AppReminder(
      id: const Uuid().v4(),
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      relatedId: relatedId,
      type: 'RECIPE',
    );

    await _db.insertReminder(reminder);
    await loadFromDisk();

    // W profesjonalnej aplikacji tutaj wywołałbyś paczkę flutter_local_notifications,
    // aby zaplanować fizyczne powiadomienie push w systemie Android/iOS.
    debugPrint("USTAWIONO MINUTNIK: $title na $scheduledTime");
  }

  // Ustawianie powiadomień sezonowych (np. o zbiorach w marcu)
  Future<void> addHarvestReminder({required String plantName, required String material, required int month, required String relatedId}) async {
    final now = DateTime.now();
    int targetYear = now.year;

    // Jeśli miesiąc już minął, ustawiamy na przyszły rok
    if (month < now.month) {
      targetYear++;
    }

    final scheduledTime = DateTime(targetYear, month, 1, 9, 0); // 1. dzień miesiąca, godz 9:00

    final reminder = AppReminder(
      id: const Uuid().v4(),
      title: "Czas na zbiory: $plantName",
      body: "Surowiec: $material. Najlepszy moment na zbiór właśnie się rozpoczął!",
      scheduledTime: scheduledTime,
      relatedId: relatedId,
      type: 'HARVEST',
    );

    await _db.insertReminder(reminder);
    await loadFromDisk();
  }

  Future<void> toggleReminderStatus(String id, bool isCompleted) async {
    await _db.updateReminderStatus(id, isCompleted);
    await loadFromDisk();
  }

  Future<void> deleteReminder(String id) async {
    await _db.deleteReminder(id);
    await loadFromDisk();
  }
}