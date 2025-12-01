import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme_config.dart';
import '../../models/chat/chat_models.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/profile_photo_widget.dart';
import '../../utils/date_utils.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

/// Pantalla de lista de chats - Usa ChatProvider para estado y realtime
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? _currentUserId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    if (_initialized) return;
    
    // Obtener ID del usuario actual
    final usuarioProvider = context.read<UsuarioProvider>();
    
    // Si el usuario no está cargado, cargarlo primero
    if (usuarioProvider.usuario == null) {
      await usuarioProvider.cargarPerfil();
    }
    
    _currentUserId = usuarioProvider.usuario?.id;
    
    print('[ChatListScreen] _currentUserId = $_currentUserId');
    print('[ChatListScreen] usuario = ${usuarioProvider.usuario?.nombreCompleto}, rol = ${usuarioProvider.usuario?.rol}');
    
    // Inicializar el ChatProvider (conecta SignalR y carga conversaciones)
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.initialize();
    
    _initialized = true;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshConversations() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            final conversations = chatProvider.conversations;
            final isLoading = chatProvider.loading;
            final isConnected = chatProvider.connected;

            return Column(
              children: [
                _buildHeader(isDark, isConnected),
                _buildConnectionIndicator(isConnected),
                const SizedBox(height: 8),
                _buildMessagesLabel(isDark, conversations.length),
                Expanded(
                  child: isLoading && conversations.isEmpty
                      ? _buildLoadingState()
                      : conversations.isEmpty
                          ? _buildEmptyState(isDark)
                          : _buildChatList(isDark, conversations),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildNewChatFAB(),
    );
  }

  Widget _buildHeader(bool isDark, bool isConnected) {
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
                      color: isConnected ? Colors.greenAccent : Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (isConnected ? Colors.greenAccent : Colors.redAccent)
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

  Widget _buildConnectionIndicator(bool isConnected) {
    if (isConnected) return const SizedBox.shrink();
    
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

  Widget _buildMessagesLabel(bool isDark, int count) {
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
          if (count > 0)
            Text(
              '$count chat${count == 1 ? '' : 's'}',
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

  Widget _buildChatList(bool isDark, List<Conversation> conversations) {
    return RefreshIndicator(
      onRefresh: _refreshConversations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return _buildChatTile(conversations[index], isDark);
        },
      ),
    );
  }

  Widget _buildChatTile(Conversation conversation, bool isDark) {
    final displayName = conversation.getDisplayName(_currentUserId ?? '');
    final lastMessage = conversation.lastMessage;
    final unreadCount = conversation.unreadCount;
    final isGroup = conversation.type == ConversationType.group;
    final otherUserPhoto = isGroup ? null : conversation.getOtherUserPhoto(_currentUserId ?? '');

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
                    if (isGroup)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.group_rounded, color: Colors.white, size: 28),
                        ),
                      )
                    else
                      UserAvatarWidget(
                        fotoUrl: otherUserPhoto,
                        nombreCompleto: displayName,
                        size: 56,
                        backgroundColor: AppTheme.primaryPurple,
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
      _refreshConversations();
    });
  }

  void _navigateToNewChat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewChatScreen(
          currentUserId: _currentUserId ?? '',
        ),
      ),
    );
    
    // Recargar conversaciones primero
    await _refreshConversations();
    
    // Si se creó/seleccionó una conversación, navegar a ella
    if (result != null && result is String) {
      final chatProvider = context.read<ChatProvider>();
      final conversations = chatProvider.conversations;
      
      // result es el conversationId
      try {
        final conversation = conversations.firstWhere((c) => c.id == result);
        _navigateToChatDetail(conversation);
      } catch (_) {
        // No se encontró la conversación
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    // Usar utilidad de fecha que ajusta a Bolivia (UTC-4)
    return AppDateUtils.formatRelativeDate(dateTime);
  }
}
