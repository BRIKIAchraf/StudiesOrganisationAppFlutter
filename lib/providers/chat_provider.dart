import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';

class ChatProvider with ChangeNotifier {
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

  void initSocket(String token, String userId) {
    _currentUserId = userId;
    if (_socket != null && _socket!.connected) return;

    // Use pure IP for socket to avoid issues, or reuse baseUrl logic
    // Removing /api from baseUrl for socket connection
    final socketUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    
    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
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
      
      // Simple check: if I am not the sender, show notification
      // Note: We don't have current userId stored easily here without passing it.
      // But we can assume if we received it and we are sticking to the socket, we might be background or foreground.
      // Ideally check if app is in background, but simple trigger is requested.
      // Use a heuristic or just show it (user will see banner).
      // Filter out own messages by checking if we "sent" it? Socket sends back to sender too.
      // We need to know "my" userId.
      // Let's postpone notification if we can't filter.
      // Actually, we can check against typingUsers/auth if we had access. 
      // For now, let's just notify. (User will see "New message from Me" if we don't filter, which is annoying).
      // Correction: We don't have auth here. 
      // Let's add 'currentUserId' to ChatProvider and set it on initSocket.
      
      // Show notification if it's not from me
      if (_currentUserId != null && message.userId != _currentUserId) {
         // Also check if we are currently viewing this chat?
         // Optimally we wouldn't notify if the user is on the chat screen.
         // But for now, simple notification is requested.
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

    _socket!.on('message_reaction', (data) {
       final messageId = data['messageId'];
       final reactionsStr = data['reactions'];
       Map<String, int> reactions = {};
       
       try {
         final decoded = json.decode(reactionsStr);
         decoded.forEach((k, v) => reactions[k.toString()] = v as int);
       } catch (e) {
          // ignore
       }
       
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
           messagePinned: old.messagePinned,
           attachmentUrl: old.attachmentUrl,
           replyToId: old.replyToId,
           reactions: reactions,
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

  void joinRoom(String courseId) {
    if (_socket != null) {
      _socket!.emit('join_room', courseId);
      fetchMessages(courseId);
    }
  }

  void leaveRoom(String courseId) {
    if (_socket != null) {
      // _socket!.emit('leave_room', courseId); // If implemented on server
      _messages = [];
      _typingUsers.clear();
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String courseId) async {
    _isLoading = true;
    notifyListeners();
    
    // We need auth token here. Handled by passing context or token to provider methods
    // But better to store token in provider or passed in init.
    // Ideally, AuthProvider should be accessible.
    // For now, assume global auth or passed in. 
    // Wait... we don't have the token stored in this provider.
    // We should pass it in methods.
  }
  
  // Adjusted fetch to accept token
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

  void sendMessage(String courseId, String content, AuthProvider auth, {String type = 'text', String? attachmentUrl, String? replyToId}) {
    if (_socket == null || !_isConnected) return;
    
    // Send via socket
    final data = {
      'courseId': courseId,
      'userId': auth.userId,
      'userName': auth.userName,
      'userRole': auth.userRole,
      'content': content,
      'type': type,
      'attachmentUrl': attachmentUrl,
      'replyToId': replyToId,
    };
    
    _socket!.emit('send_message', data);
  }
  
  void sendReaction(String courseId, String messageId, String reaction, String userId) {
    if (_socket == null) return;
     _socket!.emit('react_message', {
       'courseId': courseId,
       'messageId': messageId,
       'userId': userId,
       'reaction': reaction
     });
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
