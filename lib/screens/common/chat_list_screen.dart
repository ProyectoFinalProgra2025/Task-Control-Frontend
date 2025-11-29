import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/chat_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/chat_model.dart';
import '../../config/theme_config.dart';
import '../../widgets/premium_widgets.dart';
import '../../services/storage_service.dart';
import 'create_chat_screen.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final userData = await _storage.getUserData();
    setState(() {
      _currentUserId = userData?['id']?.toString();
    });

    // Solo recargar chats - SignalR ya está conectado desde el inicio de la app
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadChats();
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

  String _getRecipientName(ChatModel chat) {
    if (chat.type == ChatType.group) {
      return chat.name ?? 'Group Chat';
    }

    // For 1:1 chats, find the other person (not current user)
    if (_currentUserId == null) return 'Chat';

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

    return otherMember.userName.isNotEmpty ? otherMember.userName : otherMember.email;
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
            // Premium Header - Purple Theme based on Image #1
            Container(
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
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                            onPressed: () {
                              // TODO: Show notifications
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () {
                              // TODO: Show menu
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search message',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Messages Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Messages',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            // Chat List
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                    );
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
                    color: AppTheme.primaryPurple,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filteredChats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final recipientName = _getRecipientName(chat);
    final isGroup = chat.type == ChatType.group;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chat.id,
              recipientName: recipientName,
              isGroup: isGroup,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Online indicator (green dot)
                if (!isGroup)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipientName,
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
                        fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time and unread count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (chat.lastMessage != null)
                  Text(
                    chat.lastMessage!.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: chat.unreadCount > 0
                          ? AppTheme.primaryPurple
                          : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                    ),
                  ),
                if (chat.unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                    ),
                    child: Text(
                      chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
          title: 'No Conversations',
          subtitle: 'Tap the + button to start a new chat',
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
          title: 'Error loading chats',
          subtitle: error,
          isDark: isDark,
          action: PremiumButton(
            text: 'Retry',
            onPressed: _loadChats,
            icon: Icons.refresh_rounded,
            gradientColors: [AppTheme.primaryPurple, AppTheme.primaryPurple.withOpacity(0.8)],
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
