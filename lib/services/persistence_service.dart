import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._internal();
  factory PersistenceService() => _instance;
  PersistenceService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PersistenceService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ===== USER DATA =====
  
  Future<void> saveUserData({
    required String userId,
    required String userName,
    required String email,
    required String role,
    String? university,
    String? department,
    String? bio,
    String? photoUrl,
  }) async {
    await prefs.setString('userId', userId);
    await prefs.setString('userName', userName);
    await prefs.setString('userEmail', email);
    await prefs.setString('userRole', role);
    if (university != null) await prefs.setString('university', university);
    if (department != null) await prefs.setString('department', department);
    if (bio != null) await prefs.setString('bio', bio);
    if (photoUrl != null) await prefs.setString('photoUrl', photoUrl);
  }

  Map<String, String?> getUserData() {
    return {
      'userId': prefs.getString('userId'),
      'userName': prefs.getString('userName'),
      'userEmail': prefs.getString('userEmail'),
      'userRole': prefs.getString('userRole'),
      'university': prefs.getString('university'),
      'department': prefs.getString('department'),
      'bio': prefs.getString('bio'),
      'photoUrl': prefs.getString('photoUrl'),
    };
  }

  Future<void> updateUserProfile({
    String? userName,
    String? university,
    String? department,
    String? bio,
    String? photoUrl,
  }) async {
    if (userName != null) await prefs.setString('userName', userName);
    if (university != null) await prefs.setString('university', university);
    if (department != null) await prefs.setString('department', department);
    if (bio != null) await prefs.setString('bio', bio);
    if (photoUrl != null) await prefs.setString('photoUrl', photoUrl);
  }

  // ===== COURSES DATA =====
  
  Future<void> saveCourses(List<Map<String, dynamic>> courses) async {
    final jsonString = json.encode(courses);
    await prefs.setString('cached_courses', jsonString);
    await prefs.setString('courses_last_sync', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedCourses() {
    final jsonString = prefs.getString('cached_courses');
    if (jsonString == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding courses: $e');
      return null;
    }
  }

  // ===== STUDY SESSIONS =====
  
  Future<void> saveStudySessions(List<Map<String, dynamic>> sessions) async {
    final jsonString = json.encode(sessions);
    await prefs.setString('cached_sessions', jsonString);
  }

  List<Map<String, dynamic>>? getCachedStudySessions() {
    final jsonString = prefs.getString('cached_sessions');
    if (jsonString == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding sessions: $e');
      return null;
    }
  }

  // ===== SETTINGS =====
  
  Future<void> saveSettings({
    bool? isDarkMode,
    double? textScaleFactor,
    String? language,
  }) async {
    if (isDarkMode != null) await prefs.setBool('isDarkMode', isDarkMode);
    if (textScaleFactor != null) await prefs.setDouble('textScaleFactor', textScaleFactor);
    if (language != null) await prefs.setString('language', language);
  }

  Map<String, dynamic> getSettings() {
    return {
      'isDarkMode': prefs.getBool('isDarkMode') ?? false,
      'textScaleFactor': prefs.getDouble('textScaleFactor') ?? 1.0,
      'language': prefs.getString('language') ?? 'en',
    };
  }

  // ===== STUDY GROUPS =====
  
  Future<void> saveStudyGroups(List<Map<String, dynamic>> groups) async {
    final jsonString = json.encode(groups);
    await prefs.setString('cached_study_groups', jsonString);
  }

  List<Map<String, dynamic>>? getCachedStudyGroups() {
    final jsonString = prefs.getString('cached_study_groups');
    if (jsonString == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding study groups: $e');
      return null;
    }
  }

  // ===== NOTIFICATIONS PREFERENCES =====
  
  Future<void> saveNotificationPreferences({
    bool? examReminders,
    bool? chatNotifications,
    bool? achievementAlerts,
    String? fcmToken,
  }) async {
    if (examReminders != null) await prefs.setBool('notif_exam_reminders', examReminders);
    if (chatNotifications != null) await prefs.setBool('notif_chat', chatNotifications);
    if (achievementAlerts != null) await prefs.setBool('notif_achievements', achievementAlerts);
    if (fcmToken != null) await prefs.setString('fcm_token', fcmToken);
  }

  Map<String, dynamic> getNotificationPreferences() {
    return {
      'examReminders': prefs.getBool('notif_exam_reminders') ?? true,
      'chatNotifications': prefs.getBool('notif_chat') ?? true,
      'achievementAlerts': prefs.getBool('notif_achievements') ?? true,
      'fcmToken': prefs.getString('fcm_token'),
    };
  }

  // ===== ACHIEVEMENTS & GAMIFICATION =====
  
  Future<void> saveAchievements(List<String> achievements) async {
    await prefs.setStringList('achievements', achievements);
  }

  List<String> getAchievements() {
    return prefs.getStringList('achievements') ?? [];
  }

  Future<void> saveStreak(int days) async {
    await prefs.setInt('current_streak', days);
    await prefs.setString('last_study_date', DateTime.now().toIso8601String());
  }

  int getStreak() {
    return prefs.getInt('current_streak') ?? 0;
  }

  // ===== CLEAR DATA =====
  
  Future<void> clearUserData() async {
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
    await prefs.remove('university');
    await prefs.remove('department');
    await prefs.remove('bio');
    await prefs.remove('photoUrl');
  }

  Future<void> clearAllCache() async {
    await prefs.remove('cached_courses');
    await prefs.remove('cached_sessions');
    await prefs.remove('cached_study_groups');
    await prefs.remove('courses_last_sync');
  }

  Future<void> clearAll() async {
    await prefs.clear();
  }

  // ===== SYNC STATUS =====
  
  Future<void> markSynced(String key) async {
    await prefs.setString('${key}_last_sync', DateTime.now().toIso8601String());
  }

  DateTime? getLastSync(String key) {
    final syncTime = prefs.getString('${key}_last_sync');
    if (syncTime == null) return null;
    return DateTime.parse(syncTime);
  }

  bool needsSync(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final lastSync = getLastSync(key);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }
}
