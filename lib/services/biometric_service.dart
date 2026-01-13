import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if device supports biometrics
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // Check if face ID is available
  Future<bool> hasFaceId() async {
    if (kIsWeb) return false;
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  // Check if fingerprint is available
  Future<bool> hasFingerprint() async {
    if (kIsWeb) return false;
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) || 
           biometrics.contains(BiometricType.strong);
  }

  // Authenticate with biometrics
  Future<bool> authenticate({String reason = 'Please authenticate to login'}) async {
    if (kIsWeb) return false;
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_login_enabled') ?? false;
  }

  // Enable biometric login
  Future<void> enableBiometricLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_login_enabled', true);
    await prefs.setString('biometric_user_email', email);
  }

  // Disable biometric login
  Future<void> disableBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_login_enabled', false);
    await prefs.remove('biometric_user_email');
    await prefs.remove('biometric_user_password');
  }

  // Get stored email for biometric login
  Future<String?> getBiometricUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_user_email');
  }

  // Store credentials for biometric re-auth (encrypt in production!)
  Future<void> storeCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_user_email', email);
    // In production, use flutter_secure_storage for password
    await prefs.setString('biometric_user_password', password);
  }

  // Get stored password for biometric login
  Future<String?> getStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('biometric_user_password');
  }
}
