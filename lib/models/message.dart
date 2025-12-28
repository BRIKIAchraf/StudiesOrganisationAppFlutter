class Message {
  final String id;
  final String courseId;
  final String userId;
  final String userName;
  final String userRole;
  final String content;
  final String type;
  final DateTime timestamp;
  final bool messagePinned;

  Message({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.content,
    required this.type,
    required this.timestamp,
    this.messagePinned = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      courseId: json['courseId'].toString(),
      userId: json['userId'].toString(),
      userName: json['userName'] ?? 'Unknown',
      userRole: json['userRole'] ?? 'student',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      timestamp: DateTime.parse(json['timestamp']),
      messagePinned: json['isPinned'] == 1 || json['isPinned'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': messagePinned,
    };
  }
}
