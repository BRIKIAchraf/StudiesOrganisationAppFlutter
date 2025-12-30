class Enrollment {
  final String id;
  final String courseId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;

  Enrollment({
    required this.id,
    required this.courseId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    required this.requestedAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'].toString(),
      courseId: json['courseId'].toString(),
      studentId: json['studentId'].toString(),
      studentName: json['name'] ?? 'Unknown',
      studentEmail: json['email'] ?? '',
      status: json['status'],
      requestedAt: DateTime.parse(json['requestedAt']),
    );
  }
}
