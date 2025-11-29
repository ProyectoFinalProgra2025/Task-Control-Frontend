import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../../services/storage_service.dart';
import '../../config/theme_config.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String recipientName;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.recipientName,
    required this.isGroup,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StorageService _storage = StorageService();

  String? _currentUserId;
  bool _isSending = false;
  final Set<String> _displayedMessageIds = {};
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadChatData();
    _subscribeToNewMessages();
  }

  // Suscribirse a mensajes nuevos para marcarlos como leídos automáticamente
  void _subscribeToNewMessages() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // Escuchar cambios en los mensajes del chat actual
    chatProvider.addListener(_onMessagesChanged);
  }

  void _onMessagesChanged() {
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = chatProvider.getMessages(widget.chatId);
    
    // Buscar mensajes no leídos de otros usuarios y marcarlos como leídos
    bool hasUnreadFromOthers = false;
    for (final msg in messages) {
      if (msg.senderId != _currentUserId && !msg.isRead) {
        hasUnreadFromOthers = true;
        break;
      }
    }
    
    // Si hay mensajes no leídos de otros, marcar como leídos
    if (hasUnreadFromOthers) {
      chatProvider.markChatAsRead(widget.chatId);
    }
  }

  Future<void> _loadChatData() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Get current user ID
    final userData = await _storage.getUserData();
    setState(() {
      _currentUserId = userData?['id']?.toString();
    });

    // Load messages and join SignalR room
    await chatProvider.loadMessages(widget.chatId);
    await chatProvider.joinChatRoom(widget.chatId);

    // Mark chat as read AFTER loading messages (calls API)
    await chatProvider.markChatAsRead(widget.chatId);

    // Scroll to bottom after loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(widget.chatId, messageText);

      // Scroll to bottom after sending (with slight delay for message to appear)
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _scrollToBottom(animated: true);
        }
      });
    } catch (e) {
      // Restore message if send failed
      _messageController.text = messageText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _getRecipientInfo(ChatModel chat) {
    if (widget.isGroup) {
      return '${chat.members.length} members';
    }
    return 'Online'; // Can be enhanced with real online status from backend
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final chat = chatProvider.chats.firstWhere(
              (c) => c.id == widget.chatId,
              orElse: () => ChatModel(
                id: widget.chatId,
                type: widget.isGroup ? ChatType.group : ChatType.oneToOne,
                members: [],
                createdAt: DateTime.now(),
              ),
            );

            return InkWell(
              onTap: () {
                if (!widget.isGroup) {
                  _showUserInfoDialog(context, chat);
                }
              },
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Center(
                      child: Text(
                        widget.recipientName.isNotEmpty
                            ? widget.recipientName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.recipientName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!widget.isGroup) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _getRecipientInfo(chat),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTextTertiary
                              : AppTheme.lightTextTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppTheme.darkTextTertiary
                                : AppTheme.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-scroll when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _scrollController.hasClients) {
                    final position = _scrollController.position;
                    // Only auto-scroll if user is near bottom (within 100px)
                    if (position.maxScrollExtent - position.pixels < 100) {
                      _scrollToBottom(animated: true);
                    }
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == _currentUserId;

                    // Determine if message is new (for animation)
                    final isNewMessage = !_displayedMessageIds.contains(message.id);
                    if (isNewMessage) {
                      _displayedMessageIds.add(message.id);
                    }

                    // Show sender name for group chats on messages from others
                    String? senderName;
                    if (!isMine && widget.isGroup) {
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

                    return _buildMessageBubble(
                      message,
                      isMine,
                      senderName,
                      isDark,
                      isNewMessage,
                    );
                  },
                );
              },
            ),
          ),
          // Input Area
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppTheme.darkBorder.withOpacity(0.3)
                      : AppTheme.lightBorder,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkBackground
                            : AppTheme.lightBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBorder.withOpacity(0.3)
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextTertiary
                                : AppTheme.lightTextTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !_isSending,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryPurple,
                          AppTheme.primaryPurple.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSending ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(24),
                        child: Center(
                          child: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
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

  Widget _buildMessageBubble(
    MessageModel message,
    bool isMine,
    String? senderName,
    bool isDark,
    bool isNewMessage,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: isNewMessage ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
                    color: AppTheme.primaryPurple,
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
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMine
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryPurple,
                                AppTheme.primaryPurple.withOpacity(0.85),
                              ],
                            )
                          : null,
                      color: isMine
                          ? null
                          : (isDark ? AppTheme.darkCard : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMine
                            ? const Radius.circular(18)
                            : const Radius.circular(4),
                        bottomRight: isMine
                            ? const Radius.circular(4)
                            : const Radius.circular(18),
                      ),
                      border: !isMine
                          ? Border.all(
                              color: isDark
                                  ? AppTheme.darkBorder.withOpacity(0.3)
                                  : AppTheme.lightBorder,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isMine
                              ? AppTheme.primaryPurple.withOpacity(0.2)
                              : Colors.black.withOpacity(isDark ? 0.1 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.detailTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: isMine
                                    ? Colors.white.withOpacity(0.8)
                                    : (isDark
                                        ? AppTheme.darkTextTertiary
                                        : AppTheme.lightTextTertiary),
                              ),
                            ),
                            // Show read status for own messages
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead
                                    ? Icons.done_all
                                    : Icons.check,
                                size: 14,
                                color: message.isRead
                                    ? Colors.lightBlueAccent
                                    : Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              title: Text(
                'Chat Info',
                style: TextStyle(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show chat info
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppTheme.dangerRed),
              title: Text('Delete Chat',
                  style: TextStyle(color: AppTheme.dangerRed)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete chat
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Mostrar información pública del usuario
  void _showUserInfoDialog(BuildContext context, ChatModel chat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Encontrar el otro miembro del chat (no el usuario actual)
    final otherMember = chat.members.firstWhere(
      (member) => member.userId != _currentUserId,
      orElse: () => chat.members.isNotEmpty
          ? chat.members.first
          : ChatMemberModel(
              userId: '',
              userName: 'Unknown',
              email: '',
              role: ChatRole.member,
            ),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar grande
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPurple,
                      AppTheme.primaryPurple.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    otherMember.userName.isNotEmpty
                        ? otherMember.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Nombre
              Text(
                otherMember.userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Email
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        otherMember.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Rol
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  otherMember.role == ChatRole.owner ? 'Owner' : 'Member',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.removeListener(_onMessagesChanged);
    chatProvider.leaveChatRoom(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}
