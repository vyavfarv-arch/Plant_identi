// lib/viewmodels/reminder_view_model.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart'; // DODANY IMPORT
/**
 * ============================================================================
 * DOKUMENTACJA REPOZYTORIUM - ROLA PLIKU I ZALEŻNOŚCI (Standard dla LLM)
 * ============================================================================
 * Rola pliku:
 * Odpowiada za logikę biznesową asystenta czasowego. Obsługuje procesy
 * dodawania, usuwania i zmiany stanów przypomnień laboratoryjnych (timery procesów
 * przepisu 'RECIPE') oraz alertów fenologicznych w kalendarzu zbiorów surowca ('HARVEST').
 *
 * Zależności wewnętrzne (pliki z /lib):
 * * Z pliku '../models/app_reminder.dart':
 * - Klasa [AppReminder]: Model danych, na którym operuje kolekcja i metody
 * aktualizacji statusu ukończenia oraz wyciszenia dzwonka.
 * * Z pliku '../services/database_helper.dart':
 * - Klasa [DatabaseHelper]: Zapewnia trwałość stanów alarmów, rejestrując
 * i modyfikując wpisy bezpośrednio w bazie SQLite.
 * * Z pliku '../services/notification_service.dart':
 * - Klasa [NotificationService]: Kluczowy moduł wykonawczy, który rejestruje
 * lub anuluje dokładne powiadomienia w systemie operacyjnym Android.
 * ============================================================================
 */
class ReminderViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifService = NotificationService(); // DODANY SERWIS
  List<AppReminder> _reminders = [];

  List<AppReminder> get reminders => _reminders;

  Future<void> loadFromDisk() async {
    final fetchedReminders = await _db.getReminders();
    fetchedReminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    _reminders = fetchedReminders;
    notifyListeners();
  }

  Future<void> addTimerReminder({required String title, required String body, required int durationMinutes, required String relatedId}) async {
    final scheduledTime = DateTime.now().add(Duration(minutes: durationMinutes));
    final reminder = AppReminder(
      id: const Uuid().v4(), title: title, body: body, scheduledTime: scheduledTime, relatedId: relatedId, type: 'RECIPE',
    );
    await _db.insertReminder(reminder);

    if (!reminder.isMuted) {
      // POPRAWKA: .abs() zabezpiecza przed ujemnymi ID odrzucanymi przez Androida
      await _notifService.scheduleNotification(id: reminder.id.hashCode.abs(), title: reminder.title, body: reminder.body, scheduledTime: reminder.scheduledTime);
    }
    await loadFromDisk();
  }

  /// Wyznacza najbliższe wystąpienie corocznego sezonu zbioru.
  /// Rok zapisany w HarvestSeason jest wyłącznie rokiem referencyjnym.
  ({DateTime start, DateTime end}) getNearestHarvestSeason({
    required DateTime startDate,
    required DateTime endDate,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    final crossesYear =
        endDate.month < startDate.month ||
        (endDate.month == startDate.month && endDate.day < startDate.day);

    DateTime seasonStart =
        DateTime(current.year, startDate.month, startDate.day);
    DateTime seasonEnd = DateTime(
      crossesYear ? current.year + 1 : current.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    // Np. sezon 15.11-15.02, a dziś jest styczeń:
    // aktywny sezon rozpoczął się w poprzednim roku.
    if (crossesYear) {
      final previousStart =
          DateTime(current.year - 1, startDate.month, startDate.day);
      final previousEnd = DateTime(
        current.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      if (!current.isBefore(previousStart) && !current.isAfter(previousEnd)) {
        return (start: previousStart, end: previousEnd);
      }
    }

    // Jeżeli sezon w tym roku już minął, wybieramy kolejny.
    if (current.isAfter(seasonEnd)) {
      seasonStart =
          DateTime(current.year + 1, startDate.month, startDate.day);
      seasonEnd = DateTime(
        crossesYear ? current.year + 2 : current.year + 1,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
    }

    return (start: seasonStart, end: seasonEnd);
  }

  Future<DateTime> addHarvestReminder({
    required String plantName,
    required String material,
    required DateTime startDate,
    required DateTime endDate,
    required String relatedId,
  }) async {
    final nearestSeason = getNearestHarvestSeason(
      startDate: startDate,
      endDate: endDate,
    );

    final reminder = AppReminder(
      id: const Uuid().v4(),
      title: "Zbiory: $plantName",
      body: "Surowiec: $material",
      scheduledTime: nearestSeason.start,
      endDate: nearestSeason.end,
      relatedId: relatedId,
      type: 'HARVEST',
    );

    await _db.insertReminder(reminder);

    if (!reminder.isMuted) {
      final now = DateTime.now();

      // Powiadomienie systemowe ustawiamy na 09:00 pierwszego dnia
      // przyszłego sezonu. Jeśli sezon już trwa, wpis pozostaje aktywny
      // w Asystencie Czasowym, ale nie planujemy alarmu w przeszłości.
      if (nearestSeason.start.isAfter(now)) {
        final alarmTime = DateTime(
          nearestSeason.start.year,
          nearestSeason.start.month,
          nearestSeason.start.day,
          9,
          0,
        );

        if (alarmTime.isAfter(now)) {
          await _notifService.scheduleNotification(
            id: reminder.id.hashCode.abs(),
            title: reminder.title,
            body: reminder.body,
            scheduledTime: alarmTime,
          );
        }
      }
    }

    await loadFromDisk();
    return nearestSeason.start;
  }

  Future<void> toggleMute(String id, bool currentMute) async {
    final newMuteStatus = !currentMute;
    await _db.updateReminderMuteStatus(id, newMuteStatus);

    final reminder = _reminders.firstWhere((r) => r.id == id);
    if (newMuteStatus) {
      // POPRAWKA: .abs()
      await _notifService.cancelNotification(reminder.id.hashCode.abs());
    } else if (!reminder.isCompleted && reminder.scheduledTime.isAfter(DateTime.now())) {
      // POPRAWKA: .abs()
      await _notifService.scheduleNotification(id: reminder.id.hashCode.abs(), title: reminder.title, body: reminder.body, scheduledTime: reminder.scheduledTime);
    }
    await loadFromDisk();
  }

  Future<void> toggleReminderStatus(String id, bool isCompleted) async {
    await _db.updateReminderStatus(id, isCompleted);
    // POPRAWKA: Spójne odwołanie do przekazanego id.hashCode.abs() zapobiega anulowaniu złego powiadomienia
    if (isCompleted) await _notifService.cancelNotification(id.hashCode.abs());
    await loadFromDisk();
  }

  Future<void> deleteReminder(String id) async {
    // POPRAWKA: .abs()
    await _notifService.cancelNotification(id.hashCode.abs());
    await _db.deleteReminder(id);
    await loadFromDisk();
  }
}