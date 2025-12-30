class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'professor'
  final String? professorId;
  final int points;
  final int streak;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.professorId,
    this.points = 0,
    this.streak = 0,
  });

  bool get isProfessor => role == 'professor';
  bool get isStudent => role == 'student';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'student',
      professorId: json['professorId'],
      points: json['points'] ?? 0,
      streak: json['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'professorId': professorId,
      'points': points,
      'streak': streak,
    };
  }
}
