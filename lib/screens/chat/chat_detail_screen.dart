import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat_service.dart';
import '../../services/chat_hub_service.dart';
import '../../widgets/profile_photo_widget.dart';
import 'user_profile_screen.dart';

/// Pantalla de detalle de chat - Conversación individual
/// Usa ChatProvider y ChatHubService para tiempo real
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
  final ChatHubService _hubService = ChatHubService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherUserTyping = false;
  String? _typingUserName;
  
  // Subscriptions
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliveredSubscription;
  StreamSubscription<Map<String, dynamic>>? _readSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  
  Timer? _typingTimer;

  String get _displayName => widget.conversation.getDisplayName(widget.currentUserId);
  bool get _isGroup => widget.conversation.type == ConversationType.group;
  
  /// Comparar IDs case-insensitive (GUIDs pueden variar en mayúsculas/minúsculas)
  bool _isMyMessage(String senderId) {
    final result = senderId.toLowerCase() == widget.currentUserId.toLowerCase();
    print('[ChatDetailScreen] _isMyMessage: senderId=$senderId, currentUserId=${widget.currentUserId}, result=$result');
    return result;
  }

  @override
  void initState() {
    super.initState();
    print('[ChatDetailScreen] initState - currentUserId: ${widget.currentUserId}');
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Unirse a la conversación para recibir eventos de grupo
    await _hubService.joinConversation(widget.conversation.id);
    
    // Suscribirse a eventos de SignalR
    _setupSignalRListeners();
    
    // Cargar mensajes
    await _loadMessages();
    
    // Marcar todos como leídos
    _chatService.markAllMessagesRead(widget.conversation.id);
  }

  void _setupSignalRListeners() {
    // Escuchar nuevos mensajes
    _messageSubscription = _hubService.onMessage.listen((data) {
      final conversationId = data['conversationId']?.toString();
      if (conversationId != widget.conversation.id) return;
      
      print('[ChatDetailScreen] 📨 Nuevo mensaje recibido: $data');
      
      final message = ChatMessage.fromJson(data);
      if (!_messages.any((m) => m.id == message.id)) {
        setState(() {
          _messages.insert(0, message);
        });
        _scrollToBottom();
        
        // Marcar como leído si no es mío
        if (!_isMyMessage(message.senderId)) {
          _chatService.markMessageRead(message.id);
        }
      }
    });
    
    // Escuchar mensajes entregados
    _deliveredSubscription = _hubService.onMessageDelivered.listen((data) {
      final messageId = data['messageId']?.toString();
      if (messageId == null) return;
      
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWithStatus(MessageStatus.delivered);
        });
      }
    });
    
    // Escuchar mensajes leídos
    _readSubscription = _hubService.onMessageRead.listen((data) {
      final messageId = data['messageId']?.toString();
      if (messageId == null) return;
      
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWithStatus(MessageStatus.read);
        });
      }
    });
    
    // Escuchar indicadores de escritura
    _typingSubscription = _hubService.onTyping.listen((data) {
      final conversationId = data['conversationId']?.toString();
      if (conversationId != widget.conversation.id) return;
      
      final senderId = data['senderId']?.toString();
      if (senderId != null && _isMyMessage(senderId)) return; // Ignorar propios eventos
      
      setState(() {
        _otherUserTyping = data['isTyping'] == true;
        _typingUserName = data['senderName']?.toString() ?? 'Alguien';
      });
      
      // Auto-limpiar después de 5 segundos
      if (_otherUserTyping) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _otherUserTyping = false;
            });
          }
        });
      }
    });
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

    // Cancelar indicador de escritura
    _typingTimer?.cancel();

    final message = await _chatService.sendMessage(
      widget.conversation.id,
      content,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (message != null) {
        // Agregar mensaje inmediatamente a la UI (evita esperar realtime)
        if (!_messages.any((m) => m.id == message.id)) {
          setState(() {
            _messages.insert(0, message);
          });
        }
        _scrollToBottom();
      }
    }
  }

  void _onTyping() {
    // Cancelar timer anterior
    _typingTimer?.cancel();
    
    // Enviar indicador de "escribiendo"
    _hubService.sendTypingIndicator(widget.conversation.id);
    
    // Configurar timer para dejar de enviar indicadores
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _typingTimer?.cancel();
    });
  }

  void _showUserProfile() {
    if (_isGroup) {
      // TODO: Mostrar info del grupo
      return;
    }
    
    final otherUserId = widget.conversation.getOtherUserId(widget.currentUserId);
    final otherUserPhoto = widget.conversation.getOtherUserPhoto(widget.currentUserId);
    if (otherUserId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: otherUserId,
            userName: _displayName,
            fotoUrl: otherUserPhoto,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _deliveredSubscription?.cancel();
    _readSubscription?.cancel();
    _typingSubscription?.cancel();
    _hubService.leaveConversation(widget.conversation.id);
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
    final otherUserPhoto = _isGroup ? null : widget.conversation.getOtherUserPhoto(widget.currentUserId);
    
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
            child: _isGroup
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.group_rounded, color: Colors.white, size: 22),
                    ),
                  )
                : UserAvatarWidget(
                    fotoUrl: otherUserPhoto,
                    nombreCompleto: _displayName,
                    size: 44,
                    backgroundColor: AppTheme.primaryPurple,
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
                          color: _hubService.isConnected 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hubService.isConnected ? 'En línea' : 'Desconectado',
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
          // Menú de opciones
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
        final isMe = _isMyMessage(message.senderId);
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
                        _buildMessageStatusIcon(message.status, isMe),
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

  Widget _buildMessageStatusIcon(MessageStatus status, bool isMe) {
    final color = isMe ? Colors.white.withOpacity(0.7) : Colors.grey;
    
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: color);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: color);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: Colors.blue.shade300);
    }
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Botón de adjuntar
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            onPressed: () {
              // TODO: Implementar adjuntar archivos
            },
          ),
          
          // Campo de texto
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                onChanged: (_) => _onTyping(),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón de enviar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(22),
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
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animación de puntos para indicador de escritura
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
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
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (value < 0.5 ? value * 2 : 2 - value * 2).clamp(0.3, 1.0);
            
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
