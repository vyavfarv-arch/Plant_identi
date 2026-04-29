// lib/models/app_reminder.dart

class AppReminder {
  final String id;
  final String title; // Np. "Koniec maceracji: Nagietek" lub "Zbiory: Kwiat Mniszka"
  final String body;  // Dodatkowy opis
  final DateTime scheduledTime; // Kiedy ma zadzwonić
  final String relatedId; // ID przepisu lub ID gatunku (żeby móc kliknąć i przejść do szczegółów)
  final String type; // 'RECIPE' (minutnik) lub 'HARVEST' (kalendarz)
  final bool isCompleted;

  AppReminder({
    required this.id, required this.title, required this.body,
    required this.scheduledTime, required this.relatedId, required this.type,
    this.isCompleted = false
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'body': body,
    'scheduledTime': scheduledTime.toIso8601String(),
    'relatedId': relatedId, 'type': type,
    'isCompleted': isCompleted ? 1 : 0,
  };

  factory AppReminder.fromMap(Map<String, dynamic> map) => AppReminder(
    id: map['id'], title: map['title'], body: map['body'],
    scheduledTime: DateTime.parse(map['scheduledTime']),
    relatedId: map['relatedId'], type: map['type'],
    isCompleted: map['isCompleted'] == 1,
  );
}