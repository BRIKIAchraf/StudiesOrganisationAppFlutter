import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones();
  }

  // Welcome notification on login
  Future<void> showWelcomeNotification(String userName) async {
    await _notificationsPlugin.show(
      1,
      'Welcome back, $userName! 🎓',
      'Ready to continue your academic journey?',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'welcome_channel',
          'Welcome Notifications',
          channelDescription: 'Welcome messages on login',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // Daily study reminder
  Future<void> scheduleDailyReminder() async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 18, 0); // 6 PM daily
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      2,
      '📚 Daily Study Reminder',
      'Don\'t forget to log your study session today!',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Study Reminders',
          channelDescription: 'Daily reminders to study',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  // Exam proximity alerts
  Future<void> scheduleExamAlert(String courseName, DateTime examDate, int notificationId) async {
    final now = DateTime.now();
    
    // 3 days before
    final threeDaysBefore = examDate.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '⚠️ Exam Alert: $courseName',
        'Your exam is in 3 days! Time to review.',
        tz.TZDateTime.from(threeDaysBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_alerts',
            'Exam Proximity Alerts',
            channelDescription: 'Alerts for upcoming exams',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFFFF9800),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 1 day before
    final oneDayBefore = examDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        notificationId + 1,
        '🔥 Exam Tomorrow: $courseName',
        'Final review time! Your exam is tomorrow.',
        tz.TZDateTime.from(oneDayBefore, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_alerts',
            'Exam Proximity Alerts',
            channelDescription: 'Alerts for upcoming exams',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFFFF5722),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Exam day
    final examDay = DateTime(examDate.year, examDate.month, examDate.day, 8, 0); // 8 AM on exam day
    if (examDay.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        notificationId + 2,
        '🎯 Exam Today: $courseName',
        'Good luck! You\'ve got this! 💪',
        tz.TZDateTime.from(examDay, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_alerts',
            'Exam Proximity Alerts',
            channelDescription: 'Alerts for upcoming exams',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFFF44336),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Achievement unlock notification
  Future<void> showAchievementNotification(String achievement) async {
    await _notificationsPlugin.show(
      100,
      '🏆 Achievement Unlocked!',
      achievement,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Achievement Notifications',
          channelDescription: 'Notifications for unlocked achievements',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFFD700),
          playSound: true,
        ),
      ),
    );
  }

  // Streak notification
  Future<void> showStreakNotification(int streakDays) async {
    await _notificationsPlugin.show(
      101,
      '🔥 $streakDays Day Streak!',
      'Amazing consistency! Keep it up!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streaks',
          'Streak Notifications',
          channelDescription: 'Notifications for study streaks',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF6F00),
        ),
      ),
    );
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exam_reminders',
          'Exam Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showInstantNotification(String title, String body) async {
    await _notificationsPlugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_alerts',
          'Instant Alerts',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}
