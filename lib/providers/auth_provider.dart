import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';
import '../services/notification_service.dart';


class AuthProvider extends ChangeNotifier {
  String? _token;
  User? _user;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  User? get user => _user;
  
  // Helpers for legacy access compatibility
  String? get userId => _user?.id;
  String? get userName => _user?.name;
  String? get userRole => _user?.role;
  String? get professorId => _user?.professorId;
  int get points => _user?.points ?? 0;
  int get streak => _user?.streak ?? 0;
  bool get isAdmin => _user?.role == 'admin'; // Removed admin role but kept gettersafe

  final String _authUrl = ApiConfig.authUrl;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey('userData')) return;

    try {
      final userData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
      _token = userData['token'];
      // Reconstitute User object from stored data
      _user = User.fromJson(userData['user']);
      notifyListeners();
    } catch (e) {
      print('Auto login parse error: $e');
    }
  }

  Future<void> login(String email, String password) async {
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
      _user = User.fromJson(responseData['user']);

      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'user': _user!.toJson(),
      });
      await prefs.setString('userData', userData);
      
      
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, {required String role, String? professorId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_authUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'professorId': professorId,
        }),
      );

      if (response.statusCode != 201) {
        final responseData = json.decode(response.body);
        throw responseData['error'] ?? 'Registration failed';
      }
      
      // Auto login after register
      await login(email, password);
    } catch (error) {
      rethrow;
    }
  }

  // Biometrics wrapper

  Future<void> switchRole(String newRole) async {
    if (_user != null) {
      // Create new user object with updated role for local state
      // In real app, this might need backend validation or re-login
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: newRole,
        professorId: _user!.professorId,
        points: _user!.points,
        streak: _user!.streak,
      );
      
      // Update prefs
      final prefs = await SharedPreferences.getInstance();
      final userData = json.decode(prefs.getString('userData') ?? '{}');
      userData['user'] = _user!.toJson();
      await prefs.setString('userData', json.encode(userData));
      
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? bio,
    String? university,
    String? department,
    String? year,
    String? profilePictureUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_authUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'bio': bio,
          'university': university,
          'department': department,
          'year': year,
          'profilePictureUrl': profilePictureUrl,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _user = User.fromJson(userData);
        
        // Update prefs
        final prefs = await SharedPreferences.getInstance();
        final stored = json.decode(prefs.getString('userData') ?? '{}');
        stored['user'] = _user!.toJson();
        await prefs.setString('userData', json.encode(stored));
        
        notifyListeners();
      } else {
        throw 'Failed to update profile';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    notifyListeners();
  }
}
