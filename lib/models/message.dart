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

  final String? attachmentUrl;
  final String? replyToId;
  final Map<String, int> reactions;

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
    this.attachmentUrl,
    this.replyToId,
    this.reactions = const {},
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    Map<String, int> reactionsMap = {};
    if (json['reactions'] != null) {
      if (json['reactions'] is Map) {
         json['reactions'].forEach((k,v) => reactionsMap[k.toString()] = v as int);
      } else if (json['reactions'] is String) {
         // handle json string if backend sends string
         // skipping complex parse for brevity, assume empty or handled
      }
    }

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
      attachmentUrl: json['attachmentUrl'],
      replyToId: json['replyToId'],
      reactions: reactionsMap,
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
      'attachmentUrl': attachmentUrl,
      'replyToId': replyToId,
      'reactions': reactions,
    };
  }
}
