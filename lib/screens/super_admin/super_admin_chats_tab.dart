import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../worker/worker_chat_detail_screen.dart';
import '../common/create_chat_screen.dart';

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
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1a2233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF333333);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF808080);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              color: cardColor,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: textPrimary),
                    onPressed: _loadChats,
                  ),
                  const Spacer(),
                  Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF7C3AED), size: 32),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateChatScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Chat List
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading && chatProvider.chats.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                    );
                  }

                  if (chatProvider.error != null && chatProvider.chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading chats',
                            style: TextStyle(color: textPrimary, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chatProvider.error!,
                            style: TextStyle(color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadChats,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (chatProvider.chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'No chats yet',
                            style: TextStyle(color: textPrimary, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to contact company owners',
                            style: TextStyle(color: textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadChats,
                    color: const Color(0xFF7C3AED),
                    child: ListView.builder(
                      itemCount: chatProvider.chats.length,
                      itemBuilder: (context, index) {
                        final chat = chatProvider.chats[index];
                        return _buildChatItem(
                          chat: chat,
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        );
                      },
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

  Widget _buildChatItem({
    required ChatModel chat,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
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
      child: Container(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: 1),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
            child: Icon(
              isGroup ? Icons.group : Icons.person,
              color: const Color(0xFF7C3AED),
            ),
          ),
          title: Text(
            chat.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: chat.lastMessage != null
              ? Text(
                  chat.lastMessage!.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                )
              : null,
          trailing: chat.lastMessage != null
              ? Text(
                  chat.lastMessage!.formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
