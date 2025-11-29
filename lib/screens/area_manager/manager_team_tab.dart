import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../providers/chat_provider.dart';
import '../common/chat_detail_screen.dart';
import '../../config/theme_config.dart';

/// Team tab for Area Managers
/// Shows workers from the same department
class ManagerTeamTab extends StatefulWidget {
  const ManagerTeamTab({super.key});

  @override
  State<ManagerTeamTab> createState() => _ManagerTeamTabState();
}

class _ManagerTeamTabState extends State<ManagerTeamTab> {
  final UsuarioService _usuarioService = UsuarioService();
  List<Usuario> _teamMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _usuarioService.getUsuarios();
      final currentUser = await _usuarioService.getMe();
      if (mounted) {
        setState(() {
          // Show workers and other managers, but exclude self
          _teamMembers = users.where((u) => 
            (u.rol == 'Usuario' || u.rol == 'ManagerDepartamento') &&
            u.id != currentUser.id
          ).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.successGreen)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 40, color: AppTheme.dangerRed),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error al cargar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadTeamMembers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTeamMembers,
          color: AppTheme.successGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.successGreen, Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mi Equipo',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.successGreen.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: AppTheme.successGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_teamMembers.length} miembros',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.successGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
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
              Expanded(
                child: _teamMembers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people_outline,
                                  size: 40,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No hay trabajadores en tu equipo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Los miembros de tu equipo aparecerán aquí',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: _teamMembers.length,
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          return _buildMemberCard(member, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(Usuario member, bool isDark) {
    final initials = _getInitials(member.nombreCompleto);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nombreCompleto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (member.capacidades.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: member.capacidades.take(3).map((cap) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cap.nombre,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Disponible',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.message_rounded),
                    color: AppTheme.successGreen,
                    onPressed: () async {
                      try {
                        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                        await chatProvider.connectSignalR();
                        final chat = await chatProvider.createOneToOneChat(member.id);
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatId: chat.id,
                                recipientName: member.nombreCompleto,
                                isGroup: false,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.dangerRed,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
