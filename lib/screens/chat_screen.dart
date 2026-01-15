import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../services/file_service.dart';
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
  String? _replyToId; // ID of message being replied to
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      chat.initSocket(auth.token!, auth.userId!); 
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
    _msgController.removeListener(_onTyping);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({String? attachment}) {
    if (_msgController.text.trim().isEmpty && attachment == null) return;
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    
    chat.sendMessage(
      widget.courseId, 
      _msgController.text.trim(), 
      auth,
      replyToId: _replyToId,
      attachmentUrl: attachment,
      type: attachment != null ? 'image' : 'text'
    );
    
    _msgController.clear();
    setState(() => _replyToId = null);
    
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
  
  Future<void> _pickAndSendFile() async {
      final fileService = FileService();
      // Show loading snippet?
      final url = await fileService.pickAndUploadFile(); 
      
      if (url != null) {
         _sendMessage(attachment: url);
      } else {
         // Optionally show error
      }
  }

  void _attachFile() {
      // Pick file type logic
      showModalBottomSheet(context: context, builder: (ctx) => Wrap(
           children: [
             ListTile(
               leading: const Icon(Icons.image),
               title: const Text('Send Image/File'),
               onTap: () {
                 Navigator.pop(ctx);
                 _pickAndSendFile();
               }
             ),
             // Mock document for backup if file picker fails in emulator sometimes
             ListTile(title: const Text('Mock Document (Demo)'), onTap: () {
                _sendMessage(attachment: 'https://pdfobject.com/pdf/sample.pdf');
                Navigator.pop(ctx);
             }),
           ],
      ));
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final isProfessorOrAdmin = auth.userRole == 'professor' || auth.userRole == 'admin';
    final currentUserId = auth.userId;

    // Search logic
    final displayMessages = _searchQuery.isEmpty 
       ? chat.messages 
       : chat.messages.where((m) => m.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final pinnedMessages = chat.messages.where((m) => m.messagePinned).toList();
    
    // Find reply message object
    Message? replyMessage;
    if (_replyToId != null) {
       try { replyMessage = chat.messages.firstWhere((m) => m.id == _replyToId); } catch(_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Search...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.white70)),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.courseName, style: const TextStyle(fontSize: 16)),
                Text(chat.isConnected ? 'Online' : 'Connecting...', style: TextStyle(fontSize: 12, color: chat.isConnected ? Colors.greenAccent : Colors.white70)),
              ],
            ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
               _isSearching = !_isSearching;
               if(!_isSearching) _searchQuery = '';
            }),
          )
        ],
      ),
      body: Column(
        children: [
          // Pinned List (Same as before)
          if (pinnedMessages.isNotEmpty && !_isSearching)
            Container(
              color: AppColors.primary.withOpacity(0.1),
              height: 50,
              child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: pinnedMessages.length, itemBuilder: (ctx, i) {
                 final m = pinnedMessages[i];
                 return Chip(
                    label: Text("${m.userName}: ${m.content}", style: const TextStyle(fontSize: 10)), 
                    avatar: const Icon(Icons.push_pin, size: 12),
                    backgroundColor: Colors.white,
                 );
              }),
            ),
            
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: displayMessages.length,
                    itemBuilder: (ctx, i) {
                      final msg = displayMessages[i];
                      return _buildMessageBubble(msg, msg.userId == currentUserId, isProfessorOrAdmin, chat, auth.userId!);
                    },
                  ),
          ),
          
          if (_replyToId != null && replyMessage != null)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                   const Icon(Icons.reply, color: Colors.grey),
                   const SizedBox(width: 8),
                   Expanded(child: Text("Replying to ${replyMessage.userName}: ${replyMessage.content}", overflow: TextOverflow.ellipsis)),
                   IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _replyToId = null))
                ],
              ),
            ),
              
          // Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(onPressed: _attachFile, icon: const Icon(Icons.attach_file, color: Colors.grey)),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () => _sendMessage(),
                    mini: true,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe, bool canPin, ChatProvider chat, String myId) {
    // Find replying to msg
    Message? repliedMsg;
    if (msg.replyToId != null) {
       try { repliedMsg = chat.messages.firstWhere((m) => m.id == msg.replyToId); } catch (_) {}
    }

    return GestureDetector(
      onLongPress: () {
         // Show options
         showModalBottomSheet(context: context, builder: (ctx) => Wrap(
           children: [
             ListTile(leading: const Text("👍"), title: const Text("Like"), onTap: () { chat.sendReaction(widget.courseId, msg.id, "👍", myId); Navigator.pop(ctx); }),
             ListTile(leading: const Text("❤️"), title: const Text("Love"), onTap: () { chat.sendReaction(widget.courseId, msg.id, "❤️", myId); Navigator.pop(ctx); }),
             ListTile(leading: const Icon(Icons.reply), title: const Text("Reply"), onTap: () { setState(() => _replyToId = msg.id); Navigator.pop(ctx); }),
             if (canPin) ListTile(leading: const Icon(Icons.push_pin), title: Text(msg.messagePinned ? "Unpin" : "Pin"), onTap: () { chat.pinMessage(widget.courseId, msg.id, !msg.messagePinned, ""); Navigator.pop(ctx); }),
           ],
         ));
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (repliedMsg != null)
                 Container(
                   margin: const EdgeInsets.only(bottom: 4),
                   padding: const EdgeInsets.all(4),
                   decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                   child: Text("Replying to: ${repliedMsg.content}", style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                 ),
                 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) Text(msg.userName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    
                    if (msg.attachmentUrl != null)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                         child: Image.network(msg.attachmentUrl!, height: 100, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                       ),
                       
                    Text(msg.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
              
              // Reactions
              if (msg.reactions.isNotEmpty)
                Wrap(
                   spacing: 4,
                   children: msg.reactions.entries.map((e) => Container(
                     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                     decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                     child: Text("${e.key} ${e.value}", style: const TextStyle(fontSize: 10)),
                   )).toList(),
                )
            ],
          ),
        ),
      ),
    );
  }
}
