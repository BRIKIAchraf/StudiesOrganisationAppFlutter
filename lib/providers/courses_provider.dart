import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/course.dart';
import '../models/study_session.dart';
import '../models/document.dart';
import '../models/enrollment.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../services/persistence_service.dart';

class CoursesProvider with ChangeNotifier {
  List<Course> _myCourses = []; // Enrolled or Created
  List<Course> _availableCourses = []; // For discovery
  List<Document> _documents = []; // Current course documents
  
  String? _authToken;
  final String _baseUrl = ApiConfig.baseUrl;

  void updateToken(String? token) {
    bool tokenChanged = _authToken != token;
    _authToken = token;
    if (tokenChanged && token != null) {
      loadMyCourses();
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  List<Course> get courses => _myCourses;
  List<Course> get availableCourses => _availableCourses;
  List<Document> get currentDocuments => _documents;

  List<Course> get upcomingExams {
    final sorted = List<Course>.from(_myCourses);
    sorted.sort((a, b) => a.examDate.compareTo(b.examDate));
    return sorted.where((c) => c.examDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
  }

  // --- Load My Courses (Enrolled / Created) ---
  Future<void> loadMyCourses() async {
    if (_authToken == null) return;
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Fetch Courses
      final courseResponse = await http.get(Uri.parse('$_baseUrl/courses'), headers: _headers);
      
      // 2. Fetch Sessions (if student)
      List<StudySession> allSessions = [];
      try {
           final sessionResponse = await http.get(Uri.parse('$_baseUrl/sessions'), headers: _headers);
           if (sessionResponse.statusCode == 200) {
              final List<dynamic> sData = json.decode(sessionResponse.body);
              allSessions = sData.map((s) => StudySession.fromJson(s)).toList();
           }
      } catch (_) {
        // Ignore session fetch error (e.g. if professor calls this endpoint)
      }

      if (courseResponse.statusCode == 200) {
        await prefs.setString('cached_courses', courseResponse.body); // CACHE

        final List<dynamic> decoded = json.decode(courseResponse.body);
        _myCourses = decoded.map((item) {
            final c = Course.fromJson(item);
            final usersSessions = allSessions.where((s) => s.courseId == c.id).toList();
            return Course(
               id: c.id,
               title: c.title,
               professorId: c.professorId,
               professorName: c.professorName,
               examDate: c.examDate,
               description: c.description,
               enrollmentStatus: c.enrollmentStatus,
               grade: c.grade,
               sessions: usersSessions,
            );
        }).toList();
        
        // Schedule Notifications for Exams
        for (var course in _myCourses) {
           int notifId = course.id.hashCode;
           if (course.examDate.isAfter(DateTime.now())) {
             NotificationService().scheduleExamAlert(course.title, course.examDate, notifId);
           }
        }
        
        notifyListeners();
      }
    } catch (error) {
      print('Network error loading my courses: $error');
      if (prefs.containsKey('cached_courses')) {
         print('Loading from cache...');
         final List<dynamic> decoded = json.decode(prefs.getString('cached_courses')!);
         // Note: Sessions might be empty in offline mode if we don't cache sessions separately. 
         // For now, minimal implementation.
         _myCourses = decoded.map((item) => Course.fromJson(item)).toList();
         notifyListeners();
      }
    }
  }

  // --- Discovery (Students) ---
  Future<void> loadAvailableCourses() async {
    if (_authToken == null) return;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/courses/all'), headers: _headers);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);
        _availableCourses = decoded.map((item) => Course.fromJson(item)).toList();
        
        // Filter out already enrolled courses from available list logic if needed
        // Assuming backend sends all, we can filter locally or just show status
        notifyListeners();
      }
    } catch (error) {
      print('Error loading available courses: $error');
    }
  }

  // --- Enroll (Student) ---
  Future<void> enrollInCourse(String courseId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/enroll'),
        headers: _headers,
      );
      if (response.statusCode == 201) {
        // Refresh to show pending status
        loadMyCourses();
      }
    } catch (e) {
      print('Enrollment error: $e');
    }
  }

  // --- Approve (Professor) ---
  Future<void> approveStudent(String courseId, String enrollmentId, String status) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/enrollments/$enrollmentId/approve'),
        headers: _headers,
        body: json.encode({'status': status}),
      );
      // Logic to refresh or update local state could be added
    } catch (e) {
      print('Approval error: $e');
    }
  }

  // --- Professor Create Course ---
  Future<void> addCourse(String title, String description, DateTime date) async {
    try {
       final response = await http.post(
        Uri.parse('$_baseUrl/courses'),
        headers: _headers,
        body: json.encode({
          'title': title,
          'description': description,
          'examDate': date.toIso8601String()
        }),
      );
      if (response.statusCode == 201) {
        loadMyCourses();
      }
    } catch (e) {
      print('Error creating course: $e');
    }
  }

  // --- Enrollment: Management ---
  Future<List<Enrollment>> fetchEnrollments(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$courseId/enrollments'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Enrollment.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching enrollments: $e');
    }
    return [];
  }

  // --- Documents ---
  Future<void> loadDocuments(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses/$courseId/documents'), 
        headers: _headers
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _documents = data.map((j) => Document.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading documents: $e');
    }
  }

  Future<void> uploadDocument(String courseId, String title, String filePath) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/documents'),
        headers: _headers,
        body: json.encode({'title': title, 'filePath': filePath}),
      );
      loadDocuments(courseId);
    } catch (e) {
      print('Error uploading doc: $e');
    }
  }

  // --- Sessions (Legacy / Student Tracking) ---
  Future<void> addSession(String courseId, StudySession session) async {
    // Only if Student
    try {
      await http.post(
        Uri.parse('$_baseUrl/courses/$courseId/sessions'),
        headers: _headers,
        body: json.encode(session.toJson()),
      );
      
      // Optimistic update
      final index = _myCourses.indexWhere((c) => c.id == courseId);
      if (index >= 0) {
        _myCourses[index].sessions.add(session);
        notifyListeners();
        
        // SAVE TO CACHE
        final persistence = PersistenceService();
        final allSessions = _myCourses
            .expand((c) => c.sessions.map((s) => s.toJson()))
            .toList();
        await persistence.saveStudySessions(allSessions);
        
        debugPrint('✅ Session saved to cache');
      }
    } catch (e) {
      debugPrint('❌ Session add error: $e');
      rethrow;
    }
  }
  
  // Analytics Getters needed for Home Screen
  int get studyTimeToday {
    int total = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (var course in _myCourses) {
      for (var session in course.sessions) {
        if (session.date.isAfter(today)) {
          total += session.durationMinutes;
        }
      }
    }
    return total;
  }
  
  Course? get recommendedCourse {
    if (_myCourses.isEmpty) return null;
    // Simple logic: closest exam
    final active = _myCourses.where((c) => c.examDate.isAfter(DateTime.now())).toList();
    active.sort((a, b) => a.examDate.compareTo(b.examDate));
    return active.isNotEmpty ? active.first : null;
  }
  
  List<String> get achievementBadges {
     // Mock logic
     return []; 
  }

  // --- Analytics for Home Screen ---
  int get completedCoursesCount => _myCourses.where((c) => c.examDate.isBefore(DateTime.now())).length;
  
  double get averageGrade {
    if (_myCourses.isEmpty) return 0.0;
    int total = 0;
    int count = 0;
    for (var c in _myCourses) {
      if (c.grade != null) {
        total += c.grade!;
        count++;
      }
    }
    return count == 0 ? 0.0 : total / count;
  }

  Map<int, int> get weeklyStudyData {
    final data = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (var c in _myCourses) {
      for (var s in c.sessions) {
        if (s.date.isAfter(startOfWeek) && s.date.isBefore(endOfWeek)) {
          data[s.date.weekday] = (data[s.date.weekday] ?? 0) + s.durationMinutes;
        }
      }
    }
    return data;
  }

  Future<void> loadData() async {
    await loadMyCourses();
    await loadAvailableCourses();
  }

  Future<void> removeSession(String courseId, String sessionId) async {
      // Local removal
      final index = _myCourses.indexWhere((c) => c.id == courseId);
      if (index >= 0) {
        _myCourses[index].sessions.removeWhere((s) => s.id == sessionId);
        notifyListeners();
      }
  }
}
