import 'study_session.dart';

class Course {
  final String id;
  final String name;
  final String professor;
  final DateTime examDate;
  final String status; // 'active' or 'completed'
  final int? grade;
  final String? notes;
  final List<StudySession> sessions;

  Course({
    required this.id,
    required this.name,
    required this.professor,
    required this.examDate,
    this.sessions = const [],
    this.status = 'active',
    this.grade,
    this.notes,
  });
  
  bool get isCompleted => status == 'completed';

  int get totalStudyMinutes {
    return sessions.fold(0, (sum, item) => sum + item.durationMinutes);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'professor': professor,
      'examDate': examDate.toIso8601String(),
      'status': status,
      'grade': grade,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    var sessionsList = <StudySession>[];
    if (json['sessions'] != null) {
      json['sessions'].forEach((v) {
        sessionsList.add(StudySession.fromJson(v));
      });
    }
    
    return Course(
      id: json['id'],
      name: json['name'],
      professor: json['professor'] ?? '',
      examDate: DateTime.parse(json['examDate']),
      status: json['status'] ?? 'active',
      grade: json['grade'],
      sessions: sessionsList,
    );
  }
}
