import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_model.dart';
import '../worker/worker_chat_detail_screen.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  
  List<UserSearchResult> _searchResults = [];
  final Set<int> _selectedUsers = {};
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final results = await chatProvider.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $e')),
      );
    }
  }

  Future<void> _createOneToOneChat() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chat = await chatProvider.createOneToOneChat(_selectedUsers.first);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WorkerChatDetailScreen(
              chatId: chat.id,
              chatName: chat.displayName,
              chatType: '1:1',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create chat: $e')),
      );
    }
  }

  Future<void> _createGroupChat() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chat = await chatProvider.createGroupChat(
        _groupNameController.text.trim(),
        _selectedUsers.toList(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WorkerChatDetailScreen(
              chatId: chat.id,
              chatName: chat.displayName,
              chatType: 'group',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF135BEC),
        title: const Text('New Chat', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '1:1 Chat'),
            Tab(text: 'Group Chat'),
          ],
          onTap: (index) {
            setState(() {
              _selectedUsers.clear();
              _searchResults.clear();
              _searchController.clear();
              _groupNameController.clear();
            });
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOneToOneTab(isDark),
          _buildGroupTab(isDark),
        ],
      ),
    );
  }

  Widget _buildOneToOneTab(bool isDark) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? const Color(0xFF192233) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Results
        Expanded(
          child: _buildUserList(isDark, singleSelect: true),
        ),
        // Create button
        if (_selectedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createOneToOneChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Start Chat', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupTab(bool isDark) {
    return Column(
      children: [
        // Group name input
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: 'Group name',
              prefixIcon: const Icon(Icons.group),
              filled: true,
              fillColor: isDark ? const Color(0xFF192233) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search users to add...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? const Color(0xFF192233) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Selected count
        if (_selectedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_selectedUsers.length} member(s) selected',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Results
        Expanded(
          child: _buildUserList(isDark, singleSelect: false),
        ),
        // Create button
        if (_selectedUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroupChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Group', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserList(bool isDark, {required bool singleSelect}) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF135BEC)),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Search for users to start a chat',
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _selectedUsers.contains(user.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF135BEC),
            child: Text(
              user.nombreCompleto.isNotEmpty 
                  ? user.nombreCompleto[0].toUpperCase() 
                  : 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            user.nombreCompleto,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.grey[900],
            ),
          ),
          subtitle: Text(
            user.email,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          trailing: Checkbox(
            value: isSelected,
            activeColor: const Color(0xFF135BEC),
            onChanged: (value) {
              setState(() {
                if (singleSelect) {
                  _selectedUsers.clear();
                  if (value == true) {
                    _selectedUsers.add(user.id);
                  }
                } else {
                  if (value == true) {
                    _selectedUsers.add(user.id);
                  } else {
                    _selectedUsers.remove(user.id);
                  }
                }
              });
            },
          ),
          onTap: () {
            setState(() {
              if (singleSelect) {
                _selectedUsers.clear();
                _selectedUsers.add(user.id);
              } else {
                if (isSelected) {
                  _selectedUsers.remove(user.id);
                } else {
                  _selectedUsers.add(user.id);
                }
              }
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }
}
