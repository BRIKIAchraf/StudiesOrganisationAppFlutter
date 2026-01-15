import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted push notification permission');
      
      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');
      
      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token refreshed: $newToken');
        // TODO: Send to backend
      });

      // Configure local notifications
      await _configureLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle notification tap when app is terminated
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } else {
      debugPrint('❌ User declined push notification permission');
    }
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
        // Handle notification tap
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message: ${message.notification?.title}');
    
    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'New Message',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Message opened app: ${message.notification?.title}');
    
    // Navigate based on message data
    final type = message.data['type'];
    final id = message.data['id'];
    
    switch (type) {
      case 'exam':
        debugPrint('Navigate to exam: $id');
        // TODO: Navigate to calendar/exam
        break;
      case 'chat':
        debugPrint('Navigate to chat: $id');
        // TODO: Navigate to chat
        break;
      case 'enrollment':
        debugPrint('Navigate to enrollment: $id');
        // TODO: Navigate to course
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    const androidDetails = AndroidNotificationDetails(
      'push_notifications',
      'Push Notifications',
      channelDescription: 'Notifications from server',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data.toString(),
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('❌ Unsubscribed from topic: $topic');
  }

  // Badge management
  Future<void> setBadgeCount(int count) async {
    // iOS only
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.notification?.title}');
}
