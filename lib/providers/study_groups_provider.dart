import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/persistence_service.dart';
import '../models/user.dart'; // Assuming User model is accessible or needed for types, though usually auth handles user context.
// Ideally we should import the StudyGroup model if it was in a separate file, 
// but it was defined in the screen file previously. 
// I should probably move the model to its own file or redefine it here/import it.
// For now, I'll assume I need to move the model to a shared location or define it here if not shared.
// Actually, better to view `lib/screens/study_groups_screen.dart` to see where the model is.
// It seems it was defined IN the screen file in my previous turn. I should extract it.
// But to be safe and avoid circular deps if I can't move it easily right now without reading, 
// I will define the class specific to the provider or copy it to a models file first.
// Let's create `lib/models/study_group.dart` first? No, let's Stick to the plan.
// I'll define the model in the provider or assume it will be moved.
// Let's create `lib/models/study_group.dart` as part of this step to be clean.

// WAIT, I cannot create multiple files easily in one step if I want to be safe. 
// I'll create the provider and include the model definition there or import if I move it.
// I'll move the model to `lib/models/study_group.dart` in the next step or same step if I can.
// Let's just create the provider and put the model class in a separate file `lib/models/study_group.dart` first?
// The user prompt asked to create the provider. 

// Let's create the provider code.

import 'package:flutter/foundation.dart';

class StudyGroup {
  final String id;
  final String name;
  final String courseId;
  final String courseName;
  final String description;
  final List<String> memberIds;
  final List<String> memberNames;
  final String createdBy;
  final DateTime createdAt;
  final int maxMembers;

  StudyGroup({
    required this.id,
    required this.name,
    required this.courseId,
    required this.courseName,
    required this.description,
    required this.memberIds,
    required this.memberNames,
    required this.createdBy,
    required this.createdAt,
    this.maxMembers = 10,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      description: json['description'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      memberNames: List<String>.from(json['memberNames'] ?? []),
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      maxMembers: json['maxMembers'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'courseId': courseId,
      'courseName': courseName,
      'description': description,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'maxMembers': maxMembers,
    };
  }
}

class StudyGroupsProvider with ChangeNotifier {
  List<StudyGroup> _myGroups = [];
  List<StudyGroup> _availableGroups = [];
  bool _isLoading = false;
  String? _error;

  List<StudyGroup> get myGroups => _myGroups;
  List<StudyGroup> get availableGroups => _availableGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String _baseUrl = ApiConfig.baseUrl;

  // Headers helper - assumes AuthProvider updates or we pass token. 
  // For simplicity, we'll assume we get the token or store it. 
  // Ideally, we pass the token to methods.
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try load from cache first for immediate UI
      final persistence = PersistenceService();
      final cached = persistence.getCachedStudyGroups();
      if (cached != null) {
         // This is a simplified cache restore.
         // Realistically we need to separate my/available or just dump all in one.
         // For now let's just fetch API as primary source.
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/study-groups'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _myGroups = (data['myGroups'] as List)
            .map((g) => StudyGroup.fromJson(g))
            .toList();
        _availableGroups = (data['available'] as List)
            .map((g) => StudyGroup.fromJson(g))
            .toList();
            
        // Save to cache
        // await persistence.saveStudyGroups(...);
      } else {
        _error = 'Failed to load groups: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading groups: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String courseId, String courseName, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/study-groups'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'courseId': courseId,
          'courseName': courseName,
          'description': description,
          'maxMembers': 10,
        }),
      );

      if (response.statusCode == 201) {
        final newGroup = StudyGroup.fromJson(json.decode(response.body));
        _myGroups.add(newGroup);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Create group error: $e');
      return false;
    }
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/study-groups/$groupId/join'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final group = StudyGroup.fromJson(json.decode(response.body));
        
        // Remove from available and add to my groups
        _availableGroups.removeWhere((g) => g.id == groupId);
        _myGroups.add(group);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Join group error: $e');
      return false;
    }
  }
  
  Future<bool> leaveGroup(String groupId) async {
    try {
        final response = await http.post(
            Uri.parse('$_baseUrl/study-groups/$groupId/leave'),
            headers: _headers,
        );
        
        if (response.statusCode == 200) {
             // Move from my groups to available (if not deleted/full/etc, but simple logic for now)
             final groupIndex = _myGroups.indexWhere((g) => g.id == groupId);
             if (groupIndex >= 0) {
                 final group = _myGroups[groupIndex];
                 _myGroups.removeAt(groupIndex);
                 // We don't have the full updated group object to put back into available with correct member count
                 // So best is to reload or just remove locally.
                 // Reloading is safer.
                 loadGroups(); 
             }
             notifyListeners();
             return true;
        }
        return false;
    } catch (e) {
        return false;
    }
  }
}
