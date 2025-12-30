import 'study_session.dart';

class Course {
  final String id;
  final String title; // Changed from name to title match backend (or keep name and map)
  final String professorId;
  final String professorName;
  final DateTime examDate;
  final String description;
  final String? enrollmentStatus; // 'pending', 'approved', 'rejected', null (not enrolled)
  
  // Grade/Notes are student specific, may need separate handling or flexible map
  final int? grade;
  final List<StudySession> sessions;

  Course({
    required this.id,
    required this.title,
    required this.professorId,
    required this.professorName,
    required this.examDate,
    required this.description,
    this.enrollmentStatus,
    this.sessions = const [],
    this.grade,
  });
  
  // Helpers
  bool get isEnrolled => enrollmentStatus == 'approved';
  bool get isPending => enrollmentStatus == 'pending';

  int get totalStudyMinutes {
    return sessions.fold(0, (sum, item) => sum + item.durationMinutes);
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    var sessionsList = <StudySession>[];
    if (json['sessions'] != null && json['sessions'] is List) {
      json['sessions'].forEach((v) {
        sessionsList.add(StudySession.fromJson(v));
      });
    } else if (json['sessions'] is String) {
       // Backend sends JSON string sometimes
       // handled in provider map usually but good to be safe
    }
    
    return Course(
      id: json['id'].toString(),
      title: json['title'] ?? json['name'] ?? 'Untitled',
      professorId: json['professorId']?.toString() ?? '',
      professorName: json['professorName'] ?? 'Unknown Professor',
      examDate: json['examDate'] != null ? DateTime.parse(json['examDate']) : DateTime.now().add(const Duration(days: 30)),
      description: json['description'] ?? '',
      enrollmentStatus: json['enrollmentStatus'], // could be null
      grade: json['grade'],
      sessions: sessionsList,
    );
  }
}
