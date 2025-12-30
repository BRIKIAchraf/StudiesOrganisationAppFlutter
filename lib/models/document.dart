class Document {
  final String id;
  final String courseId;
  final String title;
  final String filePath; // URL or local path
  final DateTime uploadedAt;

  Document({
    required this.id,
    required this.courseId,
    required this.title,
    required this.filePath,
    required this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'].toString(),
      courseId: json['courseId'].toString(),
      title: json['title'],
      filePath: json['filePath'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'filePath': filePath,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
