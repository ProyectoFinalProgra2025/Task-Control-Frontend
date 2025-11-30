import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat_service.dart';
import '../../services/chat_realtime_service.dart';
import 'user_profile_screen.dart';

/// Pantalla de detalle de chat - Conversación individual
class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final ChatRealtimeService _realtimeService = ChatRealtimeService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherUserTyping = false;
  String? _typingUserName;
  StreamSubscription<ChatRealtimeEvent>? _realtimeSubscription;
  Timer? _typingTimer;

  String get _displayName => widget.conversation.getDisplayName(widget.currentUserId);
  String? get _otherUserId => widget.conversation.getOtherUserId(widget.currentUserId);
  bool get _isGroup => widget.conversation.type == ConversationType.group;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Unirse a la conversación para recibir eventos
    await _realtimeService.joinConversation(widget.conversation.id);
    
    // Suscribirse a eventos
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
    
    // Cargar mensajes
    await _loadMessages();
    
    // Marcar todos como leídos
    _chatService.markAllMessagesRead(widget.conversation.id);
  }

  void _handleRealtimeEvent(ChatRealtimeEvent event) {
    // Para mensajes nuevos, verificar conversationId
    if (event.type == ChatEventType.newMessage) {
      if (event.conversationId != widget.conversation.id) return;
      
      // Agregar nuevo mensaje
      if (event.data != null) {
        final message = ChatMessage.fromJson(event.data!);
        setState(() {
          // Evitar duplicados (el mensaje puede ya estar si lo envié yo)
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.insert(0, message);
            _scrollToBottom();
          }
        });
        // Marcar como leído si no es mío
        if (message.senderId != widget.currentUserId) {
          _chatService.markMessageRead(message.id);
        }
      }
      return;
    }
    
    // Otros eventos requieren que sea de esta conversación
    if (event.conversationId != widget.conversation.id) return;

    switch (event.type) {
      case ChatEventType.newMessage:
        // Ya manejado arriba
        break;
      case ChatEventType.messageDelivered:
      case ChatEventType.messageRead:
        // Actualizar estado del mensaje
        _updateMessageStatus(event);
        break;
      case ChatEventType.typing:
        if (event.senderId != widget.currentUserId) {
          setState(() {
            _otherUserTyping = event.isTyping;
            _typingUserName = event.senderName;
          });
        }
        break;
      default:
        break;
    }
  }

  void _updateMessageStatus(ChatRealtimeEvent event) {
    final messageId = event.messageId;
    if (messageId == null) return;

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      // Actualizar el estado del mensaje localmente
      setState(() {
        final oldMessage = _messages[index];
        MessageStatus newStatus = oldMessage.status;
        
        if (event.type == ChatEventType.messageDelivered) {
          newStatus = MessageStatus.delivered;
        } else if (event.type == ChatEventType.messageRead) {
          newStatus = MessageStatus.read;
        }
        
        // Usar copyWithStatus para crear mensaje actualizado
        _messages[index] = oldMessage.copyWithStatus(newStatus);
      });
    }
  }

  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(widget.conversation.id);
    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Scroll to bottom después de cargar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Enviar indicador de "dejó de escribir"
    _sendStoppedTyping();

    final message = await _chatService.sendMessage(
      widget.conversation.id,
      content,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (message != null) {
        // Agregar mensaje inmediatamente a la UI (evita esperar realtime)
        setState(() {
          // Evitar duplicados
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.insert(0, message);
          }
        });
        _scrollToBottom();
      }
    }
  }

  void _onTyping() {
    // Cancelar timer anterior
    _typingTimer?.cancel();
    
    // Enviar indicador de "escribiendo"
    if (_otherUserId != null) {
      _realtimeService.sendTypingIndicator(
        widget.conversation.id,
        _isGroup 
            ? widget.conversation.members
                .where((m) => m.userId != widget.currentUserId)
                .map((m) => m.userId)
                .toList()
            : [_otherUserId!],
      );
    }
    
    // Configurar timer para dejar de escribir
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _sendStoppedTyping();
    });
  }

  void _sendStoppedTyping() {
    if (_otherUserId != null) {
      _realtimeService.sendStoppedTypingIndicator(
        widget.conversation.id,
        _isGroup 
            ? widget.conversation.members
                .where((m) => m.userId != widget.currentUserId)
                .map((m) => m.userId)
                .toList()
            : [_otherUserId!],
      );
    }
    _typingTimer?.cancel();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.leaveConversation(widget.conversation.id);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            if (_otherUserTyping) _buildTypingIndicator(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessageList(isDark),
            ),
            _buildMessageInput(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón atrás
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          // Avatar - Clickeable para ver perfil
          GestureDetector(
            onTap: () => _showUserProfile(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isGroup
                      ? [Colors.blue.shade400, Colors.blue.shade600]
                      : [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isGroup
                    ? const Icon(Icons.group_rounded, color: Colors.white, size: 22)
                    : Text(
                        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre y estado - Clickeable para ver perfil
          Expanded(
            child: GestureDetector(
              onTap: () => _showUserProfile(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _realtimeService.isConnected 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _realtimeService.isConnected ? 'En línea' : 'Desconectado',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // TODO: Menú de opciones
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 16,
            child: _TypingDotsAnimation(),
          ),
          const SizedBox(width: 8),
          Text(
            '${_typingUserName ?? 'Alguien'} está escribiendo...',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(bool isDark) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin mensajes aún',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Envía el primer mensaje!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Mensajes más recientes abajo
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == widget.currentUserId;
        final showAvatar = !isMe && (index == _messages.length - 1 || 
            _messages[index + 1].senderId != message.senderId);
        
        return _buildMessageBubble(message, isMe, showAvatar, isDark);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showAvatar, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del otro usuario (solo si no soy yo y debe mostrarse)
          if (!isMe && showAvatar)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 36),
          
          // Burbuja del mensaje
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe 
                    ? AppTheme.primaryPurple 
                    : (isDark ? AppTheme.darkCard : Colors.grey.shade200),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Mostrar nombre en grupos
                  if (_isGroup && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  
                  // Contenido del mensaje
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Hora y estado
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.sentAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe 
                              ? Colors.white.withOpacity(0.7)
                              : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusIcon(message.status, isMe),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status, bool isMe) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.lightBlueAccent;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBackground : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onChanged: (_) => _onTyping(),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  minLines: 1,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botón enviar
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
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
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    if (_isGroup) {
      // TODO: Mostrar info del grupo
      return;
    }
    
    // Encontrar el otro usuario
    final otherMember = widget.conversation.members.firstWhere(
      (m) => m.userId != widget.currentUserId,
      orElse: () => ConversationMember.empty(),
    );
    
    if (otherMember.userId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: otherMember.userId,
            userName: otherMember.userName,
          ),
        ),
      );
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animación de puntos para "escribiendo..."
class _TypingDotsAnimation extends StatefulWidget {
  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final value = _controller.value;
            final animValue = ((value + delay) % 1.0);
            final scale = 0.5 + (0.5 * (1 - (animValue * 2 - 1).abs()));
            
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withOpacity(scale),
              ),
            );
          }),
        );
      },
    );
  }
}
