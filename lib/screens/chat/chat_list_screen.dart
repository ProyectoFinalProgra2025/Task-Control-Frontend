import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/chat/chat_models.dart';
import '../../providers/usuario_provider.dart';
import '../../services/chat_service.dart';
import '../../services/chat_realtime_service.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

/// Pantalla de lista de chats - Diseño moderno con realtime
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final ChatRealtimeService _realtimeService = ChatRealtimeService.instance;
  
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _isConnected = false;
  StreamSubscription<ChatRealtimeEvent>? _realtimeSubscription;
  
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Obtener ID del usuario actual
    final usuarioProvider = context.read<UsuarioProvider>();
    _currentUserId = usuarioProvider.usuario?.id;
    
    // Conectar al realtime
    await _connectRealtime();
    
    // Cargar conversaciones
    await _loadConversations();
  }

  Future<void> _connectRealtime() async {
    final connected = await _realtimeService.connect();
    if (mounted) {
      setState(() => _isConnected = connected);
    }
    
    // Suscribirse a eventos
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(ChatRealtimeEvent event) {
    switch (event.type) {
      case ChatEventType.connected:
        setState(() => _isConnected = true);
        break;
      case ChatEventType.connectionLost:
        setState(() => _isConnected = false);
        break;
      case ChatEventType.newMessage:
        // Recargar conversaciones para actualizar último mensaje y orden
        _loadConversations();
        break;
      case ChatEventType.messageRead:
      case ChatEventType.messageDelivered:
        // Actualizar estado si es necesario
        _loadConversations();
        break;
      default:
        break;
    }
  }

  Future<void> _loadConversations() async {
    final conversations = await _chatService.getConversations();
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
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
            _buildConnectionIndicator(),
            const SizedBox(height: 8),
            _buildMessagesLabel(isDark),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _conversations.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildChatList(isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildNewChatFAB(),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple,
            AppTheme.primaryPurple.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  // Indicador de conexión pequeño
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? Colors.greenAccent : Colors.redAccent)
                              .withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _navigateToNewChat(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Bar
          GestureDetector(
            onTap: () => _navigateToNewChat(),
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search, 
                    color: isDark 
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Buscar conversación o usuario...',
                    style: TextStyle(
                      color: isDark 
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.lightTextTertiary,
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

  Widget _buildConnectionIndicator() {
    if (_isConnected) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Conectando...',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesLabel(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mensajes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          if (_conversations.isNotEmpty)
            Text(
              '${_conversations.length} chat${_conversations.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple.withOpacity(0.2),
                        AppTheme.primaryPurple.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No tienes conversaciones',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Toca el botón + para iniciar una nueva conversación con tu equipo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToNewChat(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva conversación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return _buildChatTile(_conversations[index], isDark);
        },
      ),
    );
  }

  Widget _buildChatTile(Conversation conversation, bool isDark) {
    final displayName = conversation.getDisplayName(_currentUserId ?? '');
    final lastMessage = conversation.lastMessage;
    final unreadCount = conversation.unreadCount;
    final isGroup = conversation.type == ConversationType.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToChatDetail(conversation),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isGroup
                              ? [Colors.blue.shade400, Colors.blue.shade600]
                              : [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isGroup
                            ? const Icon(Icons.group_rounded, color: Colors.white, size: 28)
                            : Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    // Badge de no leídos
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessage != null)
                            Text(
                              _formatTime(lastMessage.sentAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0
                                    ? AppTheme.primaryPurple
                                    : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Indicador de estado del mensaje (solo si es mío)
                          if (lastMessage != null && lastMessage.senderId == _currentUserId)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _buildMessageStatusIcon(lastMessage.status),
                            ),
                          Expanded(
                            child: Text(
                              lastMessage?.content ?? 'Sin mensajes',
                              style: TextStyle(
                                fontSize: 14,
                                color: unreadCount > 0
                                    ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.check, size: 16, color: Colors.grey.shade500);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: Colors.grey.shade500);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 16, color: Colors.blue.shade400);
    }
  }

  Widget _buildNewChatFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToNewChat(),
          borderRadius: BorderRadius.circular(30),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _navigateToChatDetail(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversation: conversation,
          currentUserId: _currentUserId ?? '',
        ),
      ),
    ).then((_) {
      // Recargar conversaciones al volver
      _loadConversations();
    });
  }

  void _navigateToNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewChatScreen(
          currentUserId: _currentUserId ?? '',
        ),
      ),
    ).then((result) {
      if (result != null && result is Conversation) {
        _navigateToChatDetail(result);
      }
      _loadConversations();
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays == 0) {
      // Hoy - mostrar hora
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
