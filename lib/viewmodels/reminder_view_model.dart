// lib/viewmodels/reminder_view_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_reminder.dart';
import '../services/database_helper.dart';

class ReminderViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<AppReminder> _reminders = [];

  List<AppReminder> get reminders => _reminders;

  Future<void> loadFromDisk() async {
    _reminders = await _db.getReminders();
    notifyListeners();
  }

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
  }
  Future<void> toggleMute(String id, bool currentMute) async {
    final db = await _db.database;
    await db.update('app_reminders', {'isMuted': currentMute ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
    await loadFromDisk();
  }

  // ZMIANA: Przyjmujemy konkretną datę (np. startDate z kalendarza)
  Future<void> addHarvestReminder({
    required String plantName, required String material,
    required DateTime startDate, required DateTime endDate, required String relatedId
  }) async {
    final reminder = AppReminder(
      id: const Uuid().v4(),
      title: "Zbiory: $plantName",
      body: "Surowiec: $material",
      scheduledTime: startDate,
      endDate: endDate,
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