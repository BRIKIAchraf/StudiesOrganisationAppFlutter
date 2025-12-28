import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

import '../config/api_config.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userName;
  String? _userRole;
  String? _professorId;
  int _points = 0;
  int _streak = 0;
  bool _biometricEnabled = false;

  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;
  String? get professorId => _professorId;
  int get points => _points;
  int get streak => _streak;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _userRole == 'admin';
  bool get biometricEnabled => _biometricEnabled;

  final String _authUrl = ApiConfig.authUrl;
  final BiometricService _biometricService = BiometricService();

  // Check if biometric login is available
  Future<bool> canUseBiometric() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.isBiometricLoginEnabled();
    return isAvailable && isEnabled;
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = await _biometricService.isBiometricLoginEnabled();
    
    if (!prefs.containsKey('userData')) return;

    final userData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    _token = userData['token'];
    _userId = userData['userId'];
    _userName = userData['name'];
    _userRole = userData['role'];
    _professorId = userData['professorId'];
    _points = userData['points'] ?? 0;
    _streak = userData['streak'] ?? 0;
    notifyListeners();
  }

  Future<void> login(String email, String password, {bool enableBiometric = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$_authUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode != 200) {
        throw responseData['error'] ?? 'Authentication failed';
      }

      _token = responseData['token'];
      _userId = responseData['user']['id'];
      _userName = responseData['user']['name'];
      _userRole = responseData['user']['role'];
      _professorId = responseData['user']['professorId'];
      _points = responseData['user']['points'] ?? 0;
      _streak = responseData['user']['streak'] ?? 0;

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'name': _userName,
        'role': _userRole,
        'professorId': _professorId,
        'points': _points,
        'streak': _streak,
      });
      await prefs.setString('userData', userData);
      
      // Enable biometric if requested
      if (enableBiometric) {
        await _biometricService.storeCredentials(email, password);
        await _biometricService.enableBiometricLogin(email);
        _biometricEnabled = true;
      }
      
      // Trigger welcome notification and schedule daily reminders
      try {
        final notificationService = NotificationService();
        await notificationService.showWelcomeNotification(_userName!);
        await notificationService.scheduleDailyReminder();
      } catch (e) {
        print('Notification error: $e');
      }
      
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  // Biometric login - authenticate using stored credentials
  Future<bool> biometricLogin() async {
    try {
      final canUse = await canUseBiometric();
      if (!canUse) return false;

      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to login to Study Planner',
      );

      if (authenticated) {
        final email = await _biometricService.getBiometricUserEmail();
        final password = await _biometricService.getStoredPassword();

        if (email != null && password != null) {
          await login(email, password);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Biometric login error: $e');
      return false;
    }
  }

  // Enable biometric login for current user
  Future<void> setupBiometric(String email, String password) async {
    await _biometricService.storeCredentials(email, password);
    await _biometricService.enableBiometricLogin(email);
    _biometricEnabled = true;
    notifyListeners();
  }

  // Disable biometric login
  Future<void> disableBiometric() async {
    await _biometricService.disableBiometricLogin();
    _biometricEnabled = false;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, {String role = 'student', String? professorId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_authUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (professorId != null) 'professorId': professorId,
        }),
      );

      if (response.statusCode != 201) {
        final responseData = json.decode(response.body);
        throw responseData['error'] ?? 'Registration failed';
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> switchRole(String newRole) async {
    if (_token == null) return;
    try {
      final response = await http.put(
        Uri.parse('$_authUrl/role'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        _userRole = newRole;
        final prefs = await SharedPreferences.getInstance();
        final userData = json.decode(prefs.getString('userData')!);
        userData['role'] = _userRole;
        await prefs.setString('userData', json.encode(userData));
        notifyListeners();
      } else {
        throw 'Failed to update role';
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _userRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    notifyListeners();
  }
}

