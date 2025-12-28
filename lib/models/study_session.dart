class StudySession {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final String notes;
  final String type; // 'stopwatch', 'pomodoro'

  StudySession({
    required this.id,
    required this.date,
    required this.durationMinutes,
    this.notes = '',
    this.type = 'stopwatch',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'type': type,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
      notes: json['notes'] ?? '',
      type: json['type'] ?? 'stopwatch',
    );
  }
}
