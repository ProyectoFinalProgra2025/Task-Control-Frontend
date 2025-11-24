import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/chat_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/chat_model.dart';
import '../worker/worker_chat_detail_screen.dart';
import '../common/create_chat_screen.dart';
import '../../config/theme_config.dart';
import '../../widgets/premium_widgets.dart';
import '../../services/storage_service.dart';

class ManagerChatsTab extends StatefulWidget {
  const ManagerChatsTab({super.key});

  @override
  State<ManagerChatsTab> createState() => _ManagerChatsTabState();
}

class _ManagerChatsTabState extends State<ManagerChatsTab> {
  final StorageService _storage = StorageService();
  
  @override
  void initState() {
    super.initState();
    _loadChats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectRealtime();
    });
  }

  Future<void> _loadChats() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // SignalR already connected globally on app start/login
    await chatProvider.loadChats();
  }
  
  Future<void> _connectRealtime() async {
    try {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      final empresaId = await _storage.getEmpresaId();
      if (empresaId != null) {
        await realtimeProvider.connect(empresaId: empresaId);
      }
    } catch (e) {
      debugPrint('Error connecting to realtime: $e');
    }
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
            // Premium Header - Estilo Company Admin
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mensajes',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comunicación con tu equipo',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.refresh_rounded, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      onPressed: _loadChats,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateChatScreen())),
                    ),
                  ),
                ],
              ),
            ),

            // Chat List - Premium Design
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
                    return Center(child: CircularProgressIndicator(color: AppTheme.successGreen));
                  }

                  if (chatProvider.error != null && chatProvider.chats.isEmpty) {
                    return Center(
                      child: PremiumEmptyState(
                        icon: Icons.error_outline,
                        title: 'Error al cargar chats',
                        subtitle: chatProvider.error!,
                        isDark: isDark,
                        action: PremiumButton(
                          text: 'Reintentar',
                          onPressed: _loadChats,
                          gradientColors: [AppTheme.successGreen, const Color(0xFF059669)],
                          icon: Icons.refresh_rounded,
                        ),
                      ),
                    );
                  }

                  if (chatProvider.chats.isEmpty) {
                    return Center(
                      child: PremiumEmptyState(
                        icon: Icons.forum_outlined,
                        title: 'No hay conversaciones',
                        subtitle: 'Inicia una nueva conversación con el botón +',
                        isDark: isDark,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadChats,
                    color: AppTheme.successGreen,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: chatProvider.chats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildChatCard(chatProvider.chats[index], isDark),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat, bool isDark) {
    final isGroup = chat.type == ChatType.group;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerChatDetailScreen(
              chatId: chat.id,
              chatName: chat.displayName,
              chatType: isGroup ? 'group' : '1:1',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.2), width: 2),
                ),
                child: Icon(
                  isGroup ? Icons.groups_rounded : Icons.person_rounded,
                  color: AppTheme.successGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (chat.lastMessage != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        chat.lastMessage!.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (chat.lastMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    chat.lastMessage!.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
