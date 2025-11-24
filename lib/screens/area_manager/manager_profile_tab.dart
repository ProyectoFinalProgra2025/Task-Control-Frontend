import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/theme_toggle_button.dart';

/// Profile tab for Area Managers
class ManagerProfileTab extends StatefulWidget {
  const ManagerProfileTab({super.key});

  @override
  State<ManagerProfileTab> createState() => _ManagerProfileTabState();
}

class _ManagerProfileTabState extends State<ManagerProfileTab> {
  final UsuarioService _usuarioService = UsuarioService();
  final AuthService _authService = AuthService();
  Usuario? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _usuarioService.getMe();
      if (mounted) {
        setState(() {
          _currentUser = user;
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _getDepartmentName(String? departamento) {
    if (departamento == null) return 'Sin departamento';
    switch (departamento.toLowerCase()) {
      case 'finanzas':
        return 'Finanzas';
      case 'mantenimiento':
        return 'Mantenimiento';
      case 'produccion':
        return 'Producción';
      case 'marketing':
        return 'Marketing';
      case 'logistica':
        return 'Logística';
      case 'recursoshumanos':
        return 'Recursos Humanos';
      default:
        return departamento;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error', style: TextStyle(color: textPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final userInitials = _getInitials(_currentUser?.nombreCompleto ?? '');
    final departamento = _getDepartmentName(_currentUser?.departamento);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
              ),

              // Profile Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF135bec).withOpacity(0.1),
                        child: Text(
                          userInitials,
                          style: const TextStyle(
                            color: Color(0xFF135bec),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentUser?.nombreCompleto ?? 'N/A',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? 'N/A',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF135bec).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Jefe de Área - $departamento',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF135bec),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Capabilities Section
              if (_currentUser != null && _currentUser!.capacidades.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Capacidades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentUser!.capacidades.map((cap) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF135bec).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cap.nombre,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF135bec),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              // Settings Section
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notificaciones',
                        subtitle: 'Gestiona tus notificaciones',
                        onTap: () {},
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      Divider(height: 1, color: textSecondary.withOpacity(0.1)),
                      _buildSettingsTile(
                        icon: Icons.security_outlined,
                        title: 'Privacidad y Seguridad',
                        subtitle: 'Configuración de seguridad',
                        onTap: () {},
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      Divider(height: 1, color: textSecondary.withOpacity(0.1)),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Ayuda y Soporte',
                        subtitle: 'Obtén ayuda',
                        onTap: () {},
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // Logout Button
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFef4444)),
                    title: Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: _handleLogout,
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF135bec)),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textSecondary),
      onTap: onTap,
    );
  }
}
