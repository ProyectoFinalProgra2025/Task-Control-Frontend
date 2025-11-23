import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../services/storage_service.dart';

class WorkerChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String chatType;

  const WorkerChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.chatType,
  });

  @override
  State<WorkerChatDetailScreen> createState() => _WorkerChatDetailScreenState();
}

class _WorkerChatDetailScreenState extends State<WorkerChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StorageService _storage = StorageService();
  int? _currentUserId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Get current user ID
    final userData = await _storage.getUserData();
    setState(() {
      _currentUserId = userData?['id'] as int?;
    });

    // Load messages and join SignalR room
    await chatProvider.loadMessages(widget.chatId);
    await chatProvider.joinChatRoom(widget.chatId);

    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(widget.chatId, _messageController.text.trim());
      
      _messageController.clear();
      
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF135BEC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Icon(
                widget.chatType == 'group' ? Icons.group : Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.chatType == 'group')
                    const Text(
                      'Group',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Icon(
                chatProvider.isSignalRConnected ? Icons.circle : Icons.circle_outlined,
                color: chatProvider.isSignalRConnected ? Colors.greenAccent : Colors.white70,
                size: 12,
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.getMessages(widget.chatId);

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet\nSend a message to start the conversation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  );
                }

                // Auto-scroll when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == _currentUserId;
                    
                    // Show sender name for group chats on messages from others
                    String? senderName;
                    if (!isMine && widget.chatType == 'group') {
                      // Try to find sender name from chat members
                      final chat = chatProvider.chats.firstWhere(
                        (c) => c.id == widget.chatId,
                        orElse: () => ChatModel(
                          id: widget.chatId,
                          type: ChatType.group,
                          members: [],
                          createdAt: DateTime.now(),
                        ),
                      );
                      final member = chat.members.firstWhere(
                        (m) => m.userId == message.senderId,
                        orElse: () => ChatMemberModel(
                          userId: message.senderId,
                          userName: 'User',
                          email: '',
                          role: ChatRole.member,
                        ),
                      );
                      senderName = member.userName;
                    }

                    return _buildMessageBubble(message, isMine, senderName, isDark);
                  },
                );
              },
            ),
          ),
          // Input Area
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[900]!.withOpacity(0.5)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isSending,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      color: _isSending
                          ? Colors.grey
                          : const Color(0xFF135BEC),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMine, String? senderName, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine
                        ? const Color(0xFF135BEC)
                        : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: !isMine
                        ? Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.body,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMine
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.grey[900]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.detailTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMine
                              ? Colors.white.withOpacity(0.7)
                              : (isDark ? Colors.grey[500] : Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.leaveChatRoom(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
