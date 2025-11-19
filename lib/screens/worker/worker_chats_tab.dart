import 'package:flutter/material.dart';
import 'worker_chat_detail_screen.dart';

class WorkerChatsTab extends StatefulWidget {
  const WorkerChatsTab({super.key});

  @override
  State<WorkerChatsTab> createState() => _WorkerChatsTabState();
}

class _WorkerChatsTabState extends State<WorkerChatsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data - Replace with actual API calls
  final List<Map<String, dynamic>> _chats = [
    {
      'id': '1',
      'name': 'Jane Doe',
      'subtitle': 'Task #12345',
      'lastMessage': 'Sounds good, I\'ll get on it right away.',
      'time': '10:42 AM',
      'unreadCount': 2,
      'isRead': false,
      'avatarUrl': 'https://i.pravatar.cc/150?img=1',
      'type': '1:1',
    },
    {
      'id': '2',
      'name': 'John Smith',
      'subtitle': 'Project Phoenix',
      'lastMessage': 'Can you please provide an update on the...',
      'time': 'Yesterday',
      'unreadCount': 0,
      'isRead': true,
      'avatarUrl': 'https://i.pravatar.cc/150?img=2',
      'type': '1:1',
    },
    {
      'id': '3',
      'name': 'HR Admin',
      'subtitle': 'Onboarding Docs',
      'lastMessage': 'Welcome to the team! Please review the...',
      'time': '3d ago',
      'unreadCount': 0,
      'isRead': true,
      'avatarUrl': null,
      'icon': Icons.corporate_fare,
      'type': 'group',
    },
    {
      'id': '4',
      'name': 'Maintenance Request',
      'subtitle': null,
      'lastMessage': 'The issue with the printer has been resolved.',
      'time': '1w ago',
      'unreadCount': 0,
      'isRead': true,
      'avatarUrl': null,
      'icon': Icons.build,
      'iconColor': Colors.orange,
      'type': 'group',
    },
  ];

  List<Map<String, dynamic>> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    return _chats.where((chat) {
      final name = chat['name'].toString().toLowerCase();
      final subtitle = chat['subtitle']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || subtitle.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            color: backgroundColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chats',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                          ),
                          onPressed: () {
                            // TODO: Expand search
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or task...',
                        hintStyle: TextStyle(
                          color: textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textSecondary,
                        ),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF135bec),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: TextStyle(
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: _filteredChats.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredChats[index];
                      return _buildChatItem(chat, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new chat
        },
        backgroundColor: const Color(0xFF135BEC),
        child: const Icon(Icons.add_comment, size: 28),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, bool isDark) {
    final isUnread = chat['unreadCount'] > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerChatDetailScreen(
              chatId: chat['id'],
              chatName: chat['name'],
              chatType: chat['type'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(chat, isDark),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['subtitle'] != null
                        ? '${chat['name']} - ${chat['subtitle']}'
                        : chat['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                      color: isUnread
                          ? const Color(0xFF135BEC)
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time and Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread
                        ? const Color(0xFF135BEC)
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF135BEC),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${chat['unreadCount']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildAvatar(Map<String, dynamic> chat, bool isDark) {
    if (chat['avatarUrl'] != null) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(chat['avatarUrl']),
      );
    } else if (chat['icon'] != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: (chat['iconColor'] ?? const Color(0xFF135BEC)).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          chat['icon'],
          color: chat['iconColor'] ?? const Color(0xFF135BEC),
          size: 28,
        ),
      );
    } else {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF135BEC),
        child: Text(
          chat['name'][0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat,
                size: 48,
                color: Color(0xFF135BEC),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your chats about tasks with admins\nand assigners will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
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
