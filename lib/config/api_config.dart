import 'dart:io' show Platform;

class ApiConfig {
  // --- CONFIGURATION FOR PHYSICAL DEVICE ---
  // 1. Run 'ipconfig' on your computer
  // 2. Find your IPv4 Address (e.g., 192.168.1.XX)
  // 3. Replace '10.0.2.2' with your IP below if running on a real phone
  // For USB debugging with `adb reverse tcp:3000 tcp:3000`, use 127.0.0.1
  static const String _pcIpAddress = '10.0.2.2'; 
  
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 10.0.2.2 is the special alias to your host loopback interface (127.0.0.1 on your development machine)
      return 'http://$_pcIpAddress:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  static String get authUrl => '$baseUrl/auth';
  static String get coursesUrl => '$baseUrl/courses';
  static String get adminUrl => '$baseUrl/admin';
}
