class AppReminder {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime; // Dla zbiorów: Data rozpoczęcia
  final DateTime? endDate;       // NOWOŚĆ: Data zakończenia (dla zbiorów)
  final String relatedId;
  final String type;
  final bool isCompleted;
  final bool isMuted;           // NOWOŚĆ: Stan dzwonka (czy powiadomienie aktywne)

  AppReminder({
    required this.id, required this.title, required this.body,
    required this.scheduledTime, this.endDate, required this.relatedId,
    required this.type, this.isCompleted = false, this.isMuted = false
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'body': body,
    'scheduledTime': scheduledTime.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'relatedId': relatedId, 'type': type,
    'isCompleted': isCompleted ? 1 : 0,
    'isMuted': isMuted ? 1 : 0,
  };

  factory AppReminder.fromMap(Map<String, dynamic> map) => AppReminder(
    id: map['id'], title: map['title'], body: map['body'],
    scheduledTime: DateTime.parse(map['scheduledTime']),
    endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    relatedId: map['relatedId'], type: map['type'],
    isCompleted: map['isCompleted'] == 1,
    isMuted: map['isMuted'] == 1,
  );
}