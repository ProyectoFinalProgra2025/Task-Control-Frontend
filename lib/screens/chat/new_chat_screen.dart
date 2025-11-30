import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat_service.dart';

/// Pantalla para iniciar una nueva conversación
class NewChatScreen extends StatefulWidget {
  final String currentUserId;

  const NewChatScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ChatUserSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Cargar usuarios iniciales (sin filtro)
    _searchUsers('');
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    final results = await _chatService.searchUsers(query);
    
    if (mounted && _searchQuery == query) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _startConversation(ChatUserSearchResult user) async {
    setState(() => _isCreating = true);

    final conversation = await _chatService.getOrCreateDirectConversation(user.id);
    
    if (mounted) {
      setState(() => _isCreating = false);
      if (conversation != null) {
        Navigator.pop(context, conversation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al crear la conversación'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            _buildSearchField(isDark),
            Expanded(
              child: _isCreating
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUserList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Nueva conversación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _searchUsers(value),
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o email...',
            hintStyle: TextStyle(
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchUsers('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Intenta con otro término de búsqueda',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildUserTile(_searchResults[index], isDark);
      },
    );
  }

  Widget _buildUserTile(ChatUserSearchResult user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _startConversation(user),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple,
                        AppTheme.primaryPurple.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user.rolDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (user.departamento != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                user.departamento!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Icono de mensaje
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.primaryPurple,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
