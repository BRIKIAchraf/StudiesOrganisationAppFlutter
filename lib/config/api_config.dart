import 'package:flutter/foundation.dart';

class ApiConfig {
  // --- CONFIGURATION FOR DEVELOPMENT ---
  // Android Emulator → 10.0.2.2
  // Physical device → your PC IPv4 (e.g. 192.168.1.20)
  // iOS simulator / desktop → localhost

  static const String _androidEmulatorHost = '10.0.2.2';// change if needed
  static const String _desktopHost = 'localhost';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$_desktopHost:3000/api';
    }
    // For mobile (Android/iOS)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_androidEmulatorHost:3000/api';
    }
    // Fallback for iOS/Desktop
    return 'http://$_desktopHost:3000/api';
  }

  static String get authUrl => '$baseUrl/auth';
  static String get coursesUrl => '$baseUrl/courses';
  static String get adminUrl => '$baseUrl/admin';
}
