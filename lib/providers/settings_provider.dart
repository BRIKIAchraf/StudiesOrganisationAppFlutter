import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _userName = 'Student';
  String _matricola = '123456';

  double _textScaleFactor = 1.0;
  String? _language;

  bool get isDarkMode => _isDarkMode;
  double get textScaleFactor => _textScaleFactor;
  String get userName => _userName;
  String get matricola => _matricola;
  String? get language => _language;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _userName = prefs.getString('userName') ?? 'Student';
    _matricola = prefs.getString('matricola') ?? '123456';
    _language = prefs.getString('language');
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScaleFactor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _language!);
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
