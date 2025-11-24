import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/chat_model.dart';
import '../../widgets/premium_widgets.dart';
import '../../config/theme_config.dart';
import '../../services/storage_service.dart';
import 'worker_chat_detail_screen.dart';
import '../common/create_chat_screen.dart';

class WorkerChatsTab extends StatefulWidget {
  const WorkerChatsTab({super.key});

  @override
  State<WorkerChatsTab> createState() => _WorkerChatsTabState();
}

class _WorkerChatsTabState extends State<WorkerChatsTab> {
  final StorageService _storage = StorageService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  List<ChatModel> get _filteredChats {
    final chatProvider = Provider.of<ChatProvider>(context);
    final chats = chatProvider.chats;
    
    if (_searchQuery.isEmpty) return chats;
    
    return chats.where((chat) {
      final name = chat.displayName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();
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
            // Premium Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryBlue, Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Mensajes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue, size: 22),
                          onPressed: _loadChats,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar chats...',
                      hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  ),
                ],
              ),
            ),
            // Chat List
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
                    return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                  }

                  if (chatProvider.error != null && chatProvider.chats.isEmpty) {
                    return _buildErrorState(chatProvider.error!, isDark);
                  }

                  final filteredChats = _filteredChats;

                  if (filteredChats.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: _loadChats,
                    color: AppTheme.primaryBlue,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        return _buildChatCard(chat, isDark);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.primaryBlue, Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateChatScreen()),
              );
            },
            borderRadius: BorderRadius.circular(30),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        isDark: isDark,
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerChatDetailScreen(
                chatId: chat.id,
                chatName: chat.displayName,
                chatType: chat.type == ChatType.oneToOne ? '1:1' : 'group',
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  chat.type == ChatType.group ? Icons.group_rounded : Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (chat.lastMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      chat.lastMessage!.body,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time and Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.lastMessage != null)
                  Text(
                    chat.lastMessage!.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                const SizedBox(height: 4),
                if (chat.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
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
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: PremiumEmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'Sin Conversaciones',
          subtitle: 'Toca el botón + para iniciar un nuevo chat',
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: PremiumEmptyState(
          icon: Icons.error_outline,
          title: 'Error al cargar chats',
          subtitle: error,
          isDark: isDark,
          action: PremiumButton(
            text: 'Reintentar',
            onPressed: _loadChats,
            icon: Icons.refresh_rounded,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
