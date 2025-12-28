import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = 'Student';
  String _matricola = '123456';

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  String get matricola => _matricola;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _userName = prefs.getString('userName') ?? 'Student';
    _matricola = prefs.getString('matricola') ?? '123456';
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> updateProfile(String name, String matricola) async {
    _userName = name;
    _matricola = matricola;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    await prefs.setString('matricola', _matricola);
    notifyListeners();
  }
}
