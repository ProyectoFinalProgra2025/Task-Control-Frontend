import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../worker/worker_chat_detail_screen.dart';
import '../common/create_chat_screen.dart';
import '../../config/theme_config.dart';
import '../../widgets/premium_widgets.dart';

class SuperAdminChatsTab extends StatefulWidget {
  const SuperAdminChatsTab({super.key});

  @override
  State<SuperAdminChatsTab> createState() => _SuperAdminChatsTabState();
}

class _SuperAdminChatsTabState extends State<SuperAdminChatsTab> {
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.connectSignalR();
    await chatProvider.loadChats();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Corporate Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceRegular),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversaciones',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comunicación empresarial centralizada',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons - corporate style
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.refresh_rounded, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      onPressed: _loadChats,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.25),
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

            const SizedBox(height: 8),

            // Chat List - Corporate Design
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryPurple,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando conversaciones...',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
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
                          gradientColors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
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
                    color: AppTheme.primaryPurple,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar - corporate style
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isGroup ? Icons.groups_rounded : Icons.person_rounded,
                  color: AppTheme.primaryPurple,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chat.lastMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        chat.lastMessage!.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Time badge
              if (chat.lastMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
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
