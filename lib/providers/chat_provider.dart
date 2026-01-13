import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  IO.Socket? _socket;
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isConnected = false;
  final Map<String, bool> _typingUsers = {}; // userId -> isTyping

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  Map<String, bool> get typingUsers => _typingUsers;
  
  String? _currentUserId;
  String? _token;

  // Need to initialize notifications
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  ChatProvider() {
    _initNotifications();
  }
  
  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  void initSocket(String token, String userId) {
    // If user changed or we are reconnecting with different credentials
    if (_currentUserId != null && _currentUserId != userId) {
       disconnectSocket();
    }
    
    _currentUserId = userId;
    _token = token;
    
    if (_socket != null) {
        if (!_socket!.connected) _socket!.connect();
        return;
    }

    // Use pure IP for socket to avoid issues, or reuse baseUrl logic
    // Removing /api from baseUrl for socket connection
    final socketUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .setExtraHeaders({'Authorization': 'Bearer $token'}) // Pass token in handshake if supported by backend, or just relies on later events
        .build());

    _socket!.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.on('receive_message', (data) {
      final message = Message.fromJson(data);
      _messages.add(message);
      
      if (_currentUserId != null && message.userId != _currentUserId) {
        _showNotification(message);
      }
      
      notifyListeners();
    });
    
    _socket!.on('message_pinned', (data) {
      final messageId = data['messageId'];
      final isPinned = data['isPinned'] == true || data['isPinned'] == 1;
      
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final old = _messages[index];
        _messages[index] = Message(
            id: old.id,
            courseId: old.courseId,
            userId: old.userId,
            userName: old.userName,
            userRole: old.userRole,
            content: old.content,
            type: old.type,
            timestamp: old.timestamp,
            messagePinned: isPinned
        );
        notifyListeners();
      }
    });

    _socket!.on('user_typing', (data) {
      final userId = data['userId'];
      final isTyping = data['isTyping'];
      if (isTyping) {
        _typingUsers[userId] = true;
      } else {
        _typingUsers.remove(userId);
      }
      notifyListeners();
    });
  }
  
  void disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _typingUsers.clear();
    // Note: We don't clear messages here necessarily, as user might want to see them cached.
    // But if switching users, clear is better. 
    // For now, let's keep them until reload.
    notifyListeners();
  }

  void joinRoom(String courseId) {
    if (_socket != null) {
      _socket!.emit('join_room', courseId);
      // Fetch history via API
      fetchMessages(courseId);
    }
  }

  void leaveRoom(String courseId) {
    if (_socket != null) {
      // _socket!.emit('leave_room', courseId);
      _messages = [];
      _typingUsers.clear();
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String courseId) async {
    if (_token == null) return;
    await loadMessages(courseId, _token!);
  }
  
  Future<void> loadMessages(String courseId, String token) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/courses/$courseId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _messages = data.map((json) => Message.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _showNotification(Message msg) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel', 
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      msg.id.hashCode,
      'New message from ${msg.userName}',
      msg.content,
      details,
    );
  }

  void sendMessage(String courseId, String content, AuthProvider auth, {String type = 'text'}) {
    if (_socket == null || !_isConnected) return;
    
    // Send via socket
    final data = {
      'courseId': courseId,
      'userId': auth.userId,
      'userName': auth.userName,
      'userRole': auth.userRole,
      'content': content,
      'type': type,
    };
    
    _socket!.emit('send_message', data);
  }
  
  void sendTyping(String courseId, String userId, String userName, bool isTyping) {
    if (_socket == null) return;
    _socket!.emit('typing', {
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping
    });
  }
  
  Future<void> pinMessage(String courseId, String messageId, bool isPinned, String token) async {
    try {
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/courses/$courseId/messages/$messageId/pin'),
        headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
        },
        body: json.encode({'isPinned': isPinned}),
      );
    } catch (e) {
        print('Error pinning message: $e');
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
