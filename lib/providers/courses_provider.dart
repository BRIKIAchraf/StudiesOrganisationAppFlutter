import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/study_session.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';

class CoursesProvider with ChangeNotifier {
  List<Course> _courses = [];
  String? _authToken;

  final String _baseUrl = ApiConfig.baseUrl;

  void updateToken(String? token) {
    bool tokenChanged = _authToken != token;
    _authToken = token;
    if (tokenChanged && token != null) {
      loadData();
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  List<Course> get courses => _courses;

  List<Course> get upcomingExams {
    final sorted = List<Course>.from(_courses);
    sorted.sort((a, b) => a.examDate.compareTo(b.examDate));
    return sorted.where((c) => c.examDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
  }

  Future<void> updateCourse(
    String id, {
    String? name,
    String? professor,
    DateTime? examDate,
    String? status,
    int? grade,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/courses/$id'),
        headers: _headers,
        body: json.encode({
          if (name != null) 'name': name,
          if (professor != null) 'professor': professor,
          if (examDate != null) 'examDate': examDate.toIso8601String(),
          if (status != null) 'status': status,
          if (grade != null) 'grade': grade,
          if (notes != null) 'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final index = _courses.indexWhere((c) => c.id == id);
        if (index >= 0) {
          final old = _courses[index];
          _courses[index] = Course(
            id: old.id,
            name: name ?? old.name,
            professor: professor ?? old.professor,
            examDate: examDate ?? old.examDate,
            status: status ?? old.status,
            grade: grade ?? old.grade,
            sessions: old.sessions,
            notes: notes ?? old.notes,
          );
          notifyListeners();
        }
      }
    } catch (error) {
      print('Error updating course: $error');
    }
  }

  // Refactor updateCourseStatus to use updateCourse
  Future<void> updateCourseStatus(String id, String status, {int? grade}) async {
    await updateCourse(id, status: status, grade: grade);
  }

  double get averageGrade {
    final gradedCourses = _courses.where((c) => c.grade != null).toList();
    if (gradedCourses.isEmpty) return 0.0;
    final sum = gradedCourses.fold(0, (prev, c) => prev + c.grade!);
    return sum / gradedCourses.length;
  }

  int get completedCoursesCount {
    return _courses.where((c) => c.status == 'completed').length;
  }

  int get studyTimeToday {
    int total = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var course in _courses) {
      for (var session in course.sessions) {
        if (session.date.isAfter(today)) {
          total += session.durationMinutes;
        }
      }
    }
    return total;
  }

  Map<int, int> get weeklyStudyData {
    Map<int, int> data = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    for (var course in _courses) {
      for (var session in course.sessions) {
        if (session.date.isAfter(sevenDaysAgo)) {
          data[session.date.weekday] = (data[session.date.weekday] ?? 0) + session.durationMinutes;
        }
      }
    }
    return data;
  }

  Future<void> _saveData() async {
    // Legacy method, not needed with backend
  }

  Future<void> loadData() async {
    if (_authToken == null) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Load from cache first for immediate UI responsiveness (Offline Mode)
    final cachedData = prefs.getString('cached_courses');
    if (cachedData != null) {
      final List<dynamic> decoded = json.decode(cachedData);
      _courses = decoded.map((item) => Course.fromJson(item)).toList();
      notifyListeners();
    }

    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        _courses = decoded.map((item) => Course.fromJson(item)).toList();
        
        // Save to cache
        await prefs.setString('cached_courses', response.body);
        notifyListeners();
      }
    } catch (error) {
      print('Network error, using cached data: $error');
    }
  }

  // Placeholder for future cloud sync (Firebase/Websockets)
  Future<void> syncWithCloud() async {
    print('Ready for cloud sync engine integration...');
    // In future: push local changes to Firebase
  }

  Future<void> addCourse(String name, String professor, DateTime date) async {
    final newCourse = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      professor: professor,
      examDate: date,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courses'),
        headers: _headers,
        body: json.encode(newCourse.toJson()),
      );

      if (response.statusCode == 201) {
        _courses.add(newCourse);
        notifyListeners();
        
        // Schedule exam alerts
        try {
          final notificationService = NotificationService();
          final notificationId = newCourse.id.hashCode;
          await notificationService.scheduleExamAlert(name, date, notificationId);
        } catch (e) {
          print('Notification scheduling error: $e');
        }
      }
    } catch (error) {
      print('Error adding course: $error');
    }
  }

  Future<void> addSession(String courseId, StudySession session) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/sessions'),
        headers: _headers,
        body: json.encode(session.toJson()),
      );

      if (response.statusCode == 201) {
        final index = _courses.indexWhere((c) => c.id == courseId);
        if (index >= 0) {
          final old = _courses[index];
          final updatedSessions = List<StudySession>.from(old.sessions)..add(session);
          _courses[index] = Course(
            id: old.id,
            name: old.name,
            professor: old.professor,
            examDate: old.examDate,
            sessions: updatedSessions,
            status: old.status,
            grade: old.grade,
            notes: old.notes,
          );
          notifyListeners();
          // Note: In a full app, you'd also refresh AuthProvider points/streaks here.
        }
      }
    } catch (error) {
      print('Error adding session: $error');
    }
  }

  Course? get recommendedCourse {
    if (_courses.isEmpty) return null;
    final active = _courses.where((c) => c.status == 'active').toList();
    if (active.isEmpty) return null;

    active.sort((a, b) {
      final aDays = a.examDate.difference(DateTime.now()).inDays;
      final bDays = b.examDate.difference(DateTime.now()).inDays;
      final aMinutes = a.sessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final bMinutes = b.sessions.fold(0, (sum, s) => sum + s.durationMinutes);
      
      // score = days - (hours/2) -> lower is better
      final aScore = aDays - (aMinutes / 120);
      final bScore = bDays - (bMinutes / 120);
      return aScore.compareTo(bScore);
    });
    return active.first;
  }

  List<String> get achievementBadges {
    List<String> badges = [];
    final totalMin = _courses.fold(0, (s, c) => s + c.sessions.fold(0, (ss, ses) => ss + ses.durationMinutes));
    if (completedCoursesCount >= 1) badges.add('🎓 First Blood');
    if (totalMin >= 300) badges.add('🔥 Deep Worker');
    if (completedCoursesCount >= 5) badges.add('🏆 Academic Legend');
    return badges;
  }

  Future<void> updateSession(String courseId, String sessionId, {int? durationMinutes, String? notes, String? type}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/courses/$courseId/sessions/$sessionId'),
        headers: _headers,
        body: json.encode({
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (notes != null) 'notes': notes,
          if (type != null) 'type': type,
        }),
      );

      if (response.statusCode == 200) {
        final courseIndex = _courses.indexWhere((c) => c.id == courseId);
        if (courseIndex >= 0) {
          final oldCourse = _courses[courseIndex];
          final updatedSessions = oldCourse.sessions.map((s) {
            if (s.id == sessionId) {
              return StudySession(
                id: s.id,
                date: s.date,
                durationMinutes: durationMinutes ?? s.durationMinutes,
                notes: notes ?? s.notes,
                type: type ?? s.type,
              );
            }
            return s;
          }).toList();

          _courses[courseIndex] = Course(
            id: oldCourse.id,
            name: oldCourse.name,
            professor: oldCourse.professor,
            examDate: oldCourse.examDate,
            sessions: updatedSessions,
            status: oldCourse.status,
            grade: oldCourse.grade,
            notes: oldCourse.notes,
          );
          notifyListeners();
        }
      }
    } catch (error) {
      print('Error updating session: $error');
    }
  }

  Future<void> removeSession(String courseId, String sessionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/courses/$courseId/sessions/$sessionId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final courseIndex = _courses.indexWhere((c) => c.id == courseId);
        if (courseIndex >= 0) {
          final oldCourse = _courses[courseIndex];
          final createNewList = oldCourse.sessions.where((s) => s.id != sessionId).toList();
          
          _courses[courseIndex] = Course(
            id: oldCourse.id,
            name: oldCourse.name,
            professor: oldCourse.professor,
            examDate: oldCourse.examDate,
            sessions: createNewList,
            status: oldCourse.status,
            grade: oldCourse.grade,
            notes: oldCourse.notes,
          );
          notifyListeners();
        }
      }
    } catch (error) {
      print('Error deleting session: $error');
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/courses/$id'), headers: _headers);
      if (response.statusCode == 200) {
        _courses.removeWhere((course) => course.id == id);
        notifyListeners();
      }
    } catch (error) {
      print('Error deleting course: $error');
    }
  }
}
