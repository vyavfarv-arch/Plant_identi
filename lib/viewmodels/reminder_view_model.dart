// lib/viewmodels/reminder_view_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart'; // DODANY IMPORT

class ReminderViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifService = NotificationService(); // DODANY SERWIS
  List<AppReminder> _reminders = [];

  List<AppReminder> get reminders => _reminders;

  Future<void> loadFromDisk() async {
    _reminders = await _db.getReminders();
    notifyListeners();
  }

  Future<void> addTimerReminder({required String title, required String body, required int durationMinutes, required String relatedId}) async {
    final scheduledTime = DateTime.now().add(Duration(minutes: durationMinutes));
    final reminder = AppReminder(
      id: const Uuid().v4(), title: title, body: body, scheduledTime: scheduledTime, relatedId: relatedId, type: 'RECIPE',
    );
    await _db.insertReminder(reminder);

    // WYSYŁAMY DO SYSTEMU ANDROID
    if (!reminder.isMuted) {
      await _notifService.scheduleNotification(id: reminder.id.hashCode, title: reminder.title, body: reminder.body, scheduledTime: reminder.scheduledTime);
    }
    await loadFromDisk();
  }

  Future<void> addHarvestReminder({required String plantName, required String material, required DateTime startDate, required DateTime endDate, required String relatedId}) async {
    final reminder = AppReminder(
      id: const Uuid().v4(), title: "Zbiory: $plantName", body: "Surowiec: $material",
      scheduledTime: startDate, endDate: endDate, relatedId: relatedId, type: 'HARVEST',
    );
    await _db.insertReminder(reminder);

    // WYSYŁAMY DO SYSTEMU ANDROID (np. przypomnienie o 9:00 rano w dniu startu)
    if (!reminder.isMuted) {
      final alarmTime = DateTime(startDate.year, startDate.month, startDate.day, 9, 0);
      await _notifService.scheduleNotification(id: reminder.id.hashCode, title: reminder.title, body: reminder.body, scheduledTime: alarmTime);
    }
    await loadFromDisk();
  }

  Future<void> toggleMute(String id, bool currentMute) async {
    final newMuteStatus = !currentMute;

    await _db.updateReminderMuteStatus(id, newMuteStatus);

    final reminder = _reminders.firstWhere((r) => r.id == id);
    if (newMuteStatus) {
      await _notifService.cancelNotification(reminder.id.hashCode);
    } else if (!reminder.isCompleted && reminder.scheduledTime.isAfter(DateTime.now())) {
      await _notifService.scheduleNotification(id: reminder.id.hashCode, title: reminder.title, body: reminder.body, scheduledTime: reminder.scheduledTime);
    }

    await loadFromDisk();
  }
  Future<void> toggleReminderStatus(String id, bool isCompleted) async {
    await _db.updateReminderStatus(id, isCompleted);
    if (isCompleted) await _notifService.cancelNotification(id.hashCode); // Jeśli zakończono ręcznie, anuluj powiadomienie
    await loadFromDisk();
  }

  Future<void> deleteReminder(String id) async {
    await _notifService.cancelNotification(id.hashCode); // Kasujemy z systemu telefonu
    await _db.deleteReminder(id);
    await loadFromDisk();
  }
}