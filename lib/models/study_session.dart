class StudySession {
  final String id;
  final String courseId;
  final DateTime date;
  final int durationMinutes;
  final String notes;
  final String type; // 'stopwatch', 'pomodoro'

  StudySession({
    required this.id,
    required this.courseId,
    required this.date,
    required this.durationMinutes,
    this.notes = '',
    this.type = 'stopwatch',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'notes': notes,
      'type': type,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'].toString(),
      courseId: json['courseId']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'] ?? json['duration'] ?? 0,
      notes: json['notes'] ?? '',
      type: json['type'] ?? 'stopwatch',
    );
  }
}
