import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const ChatScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize socket/chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      
      // Init socket if not already (assuming token is available or handled)
      chat.initSocket(auth.token!, auth.userId!); // Token should be non-null if here
      chat.joinRoom(widget.courseId);
      chat.loadMessages(widget.courseId, auth.token!);
    });
    
    _msgController.addListener(_onTyping);
  }

  void _onTyping() {
    final chat = context.read<ChatProvider>();
    final auth = context.read<AuthProvider>();
    
    if (_msgController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chat.sendTyping(widget.courseId, auth.userId!, auth.userName!, true);
    } else if (_msgController.text.isEmpty && _isTyping) {
      _isTyping = false;
      chat.sendTyping(widget.courseId, auth.userId!, auth.userName!, false);
    }
  }

  @override
  void dispose() {
    // Leave room on dispose, or keep it if we want background updates? 
    // Usually leave to save resources
    // But context.read might be unsafe if disposed.
    // We'll trust the provider to handle room leaving if we call it.
    // For now, let's just dispose listener.
    _msgController.removeListener(_onTyping);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;
    
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    
    chat.sendMessage(widget.courseId, _msgController.text.trim(), auth);
    _msgController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _pinMessage(Message message) {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    
    // Toggle pin status
    chat.pinMessage(widget.courseId, message.id, !message.messagePinned, auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final isProfessorOrAdmin = auth.userRole == 'professor' || auth.userRole == 'admin';
    final currentUserId = auth.userId;

    // Filter pinned messages
    final pinnedMessages = chat.messages.where((m) => m.messagePinned).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseName, style: const TextStyle(fontSize: 16)),
            Text(
              chat.isConnected ? 'Online' : 'Connecting...',
              style: TextStyle(fontSize: 12, color: chat.isConnected ? Colors.greenAccent : Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Pinned Messages Area
          if (pinnedMessages.isNotEmpty)
            Container(
              color: AppColors.primary.withOpacity(0.1),
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: pinnedMessages.length,
                itemBuilder: (ctx, i) {
                  final msg = pinnedMessages[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.push_pin, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${msg.userName}: ${msg.content}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (isProfessorOrAdmin)
                          IconButton(
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () => _pinMessage(msg),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
          // Chat List
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = chat.messages[i];
                      final isMe = msg.userId == currentUserId;
                      return _buildMessageBubble(msg, isMe, isProfessorOrAdmin);
                    },
                  ),
          ),
          
          // Typing Indicator
          if (chat.typingUsers.isNotEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
               child: Row(
                 children: [
                   const Text(
                     "Someone is typing...",
                     style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                   ),
                 ],
               ),
             ),
             
          // Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    mini: true,
                    elevation: 0,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe, bool canPin) {
    final isProf = msg.userRole == 'professor' || msg.userRole == 'admin';
    
    return GestureDetector(
      onLongPress: canPin ? () => _pinMessage(msg) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) 
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.userName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isProf ? AppColors.primary : Colors.grey[700],
                        ),
                      ),
                      if (isProf)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 10, color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe 
                    ? AppColors.primary 
                    : (isProf ? AppColors.primary.withOpacity(0.1) : Colors.grey[200]),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg.messagePinned) const Icon(Icons.push_pin, size: 10, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(msg.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
