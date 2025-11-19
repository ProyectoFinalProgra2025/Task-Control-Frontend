import 'package:flutter/material.dart';

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

  // Mock messages - Replace with actual API calls
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'text': 'Hi! Can you check the AC unit on floor 3?',
      'isMine': false,
      'time': '10:30 AM',
      'senderName': 'Jane Doe',
    },
    {
      'id': '2',
      'text': 'Sure, I\'ll head there right now.',
      'isMine': true,
      'time': '10:32 AM',
    },
    {
      'id': '3',
      'text': 'Thanks! Let me know if you need any tools.',
      'isMine': false,
      'time': '10:33 AM',
      'senderName': 'Jane Doe',
    },
    {
      'id': '4',
      'text': 'Sounds good, I\'ll get on it right away.',
      'isMine': true,
      'time': '10:42 AM',
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().toString(),
        'text': _messageController.text.trim(),
        'isMine': true,
        'time': _formatTime(DateTime.now()),
      });
    });

    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // TODO: Send message to API
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
              child: const Icon(Icons.person, size: 20, color: Colors.white),
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, isDark);
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
                  // Attachment Button
                  IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      // TODO: Attach file
                    },
                  ),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Button
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF135BEC),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isDark) {
    final isMine = message['isMine'] as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine && message['senderName'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message['senderName'],
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
                        message['text'],
                        style: TextStyle(
                          fontSize: 15,
                          color: isMine
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.grey[900]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message['time'],
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
