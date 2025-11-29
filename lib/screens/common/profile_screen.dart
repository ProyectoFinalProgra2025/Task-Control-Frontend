import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/usuario_provider.dart';
import '../../models/capacidad_nivel_item.dart';
import '../../config/capacidades.dart';
import '../../config/theme_config.dart';
import '../../models/usuario.dart';

/// Tipos de rol para el profile screen
enum ProfileRole {
  worker,
  manager,
  adminEmpresa,
  superAdmin,
}

/// Profile Screen unificado para todos los roles
/// Features específicas por rol:
/// - Worker: Gestión de capacidades
/// - Manager: Sin features específicas adicionales
/// - AdminEmpresa: Sin features específicas adicionales  
/// - SuperAdmin: Sin features específicas adicionales
class ProfileScreen extends StatefulWidget {
  final ProfileRole role;
  
  const ProfileScreen({
    super.key,
    required this.role,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsuarioProvider>(context, listen: false).cargarPerfil();
    });
  }

  Color _getRoleColor() {
    switch (widget.role) {
      case ProfileRole.worker:
        return AppTheme.primaryBlue;
      case ProfileRole.manager:
        return AppTheme.successGreen;
      case ProfileRole.adminEmpresa:
        return AppTheme.primaryBlue;
      case ProfileRole.superAdmin:
        return AppTheme.primaryPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: Consumer<UsuarioProvider>(
        builder: (context, usuarioProvider, child) {
          if (usuarioProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: roleColor),
            );
          }

          final usuario = usuarioProvider.usuario;
          if (usuario == null) {
            return _buildErrorState(isDark, roleColor);
          }

          return CustomScrollView(
            slivers: [
              // Header con AppBar
              _buildHeader(context, usuario, isDark, roleColor),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Capacidades Section - Solo para Worker
                      if (widget.role == ProfileRole.worker) ...[
                        _buildCapacidadesSection(usuario, usuarioProvider, isDark, roleColor),
                        const SizedBox(height: 20),
                      ],
                      
                      // General Settings
                      _buildSettingsSection(
                        title: 'General settings',
                        isDark: isDark,
                        roleColor: roleColor,
                        children: [
                          _buildSettingItem(
                            icon: Icons.language_rounded,
                            title: 'Language',
                            trailing: Text(
                              'English',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            isDark: isDark,
                            onTap: () {
                              // TODO: Language selector
                            },
                          ),
                          _buildDivider(isDark),
                          _buildSettingItem(
                            icon: Icons.dark_mode_rounded,
                            title: 'Theme',
                            trailing: Text(
                              isDark ? 'Dark' : 'Light',
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            isDark: isDark,
                            onTap: () {
                              // TODO: Theme selector
                            },
                          ),
                          _buildDivider(isDark),
                          _buildSwitchItem(
                            icon: Icons.notifications_rounded,
                            title: 'Push notifications',
                            value: _notificationsEnabled,
                            isDark: isDark,
                            roleColor: roleColor,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Account Settings
                      _buildSettingsSection(
                        title: 'Account settings',
                        isDark: isDark,
                        roleColor: roleColor,
                        children: [
                          _buildSettingItem(
                            icon: Icons.lock_rounded,
                            title: 'Change password',
                            isDark: isDark,
                            onTap: () {
                              // TODO: Change password
                            },
                          ),
                          _buildDivider(isDark),
                          _buildSettingItem(
                            icon: Icons.security_rounded,
                            title: 'Privacy & Security',
                            isDark: isDark,
                            onTap: () {
                              // TODO: Privacy settings
                            },
                          ),
                          _buildDivider(isDark),
                          _buildSettingItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            isDark: isDark,
                            onTap: () {
                              // TODO: Help screen
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text(
                            'Log out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.dangerRed,
                            side: const BorderSide(color: AppTheme.dangerRed, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Usuario usuario, bool isDark, Color roleColor) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Profile',
        style: TextStyle(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.edit_rounded,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          onPressed: () {
            // TODO: Edit profile
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 60),
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        roleColor,
                        roleColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(usuario.nombreCompleto),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  usuario.nombreCompleto,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  usuario.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color roleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.dangerRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<UsuarioProvider>(context, listen: false).cargarPerfil();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacidadesSection(Usuario usuario, UsuarioProvider usuarioProvider, bool isDark, Color roleColor) {
    return _buildSettingsSection(
      title: 'My Skills',
      isDark: isDark,
      roleColor: roleColor,
      trailing: IconButton(
        icon: Icon(Icons.add_circle_outline_rounded, color: roleColor),
        onPressed: () => _showAddCapacidadDialog(usuarioProvider),
      ),
      children: [
        if (usuario.capacidades.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.star_outline_rounded,
                  size: 48,
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No skills added yet',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showAddCapacidadDialog(usuarioProvider),
                  icon: Icon(Icons.add_rounded, color: roleColor, size: 18),
                  label: Text(
                    'Add your first skill',
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
          ...usuario.capacidades.asMap().entries.map((entry) {
            final index = entry.key;
            final cap = entry.value;
            return Column(
              children: [
                _buildCapacidadItem(
                  nombre: cap.nombre,
                  nivel: cap.nivel,
                  capacidadId: cap.capacidadId,
                  isDark: isDark,
                  roleColor: roleColor,
                ),
                if (index < usuario.capacidades.length - 1)
                  _buildDivider(isDark),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildCapacidadItem({
    required String nombre,
    required int nivel,
    required String? capacidadId,
    required bool isDark,
    required Color roleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.star_rounded, color: roleColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < nivel ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (capacidadId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppTheme.dangerRed,
              onPressed: () => _deleteCapacidad(capacidadId),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required bool isDark,
    required Color roleColor,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkBackground
                    : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required Color roleColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: roleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 74,
      color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
    );
  }

  void _showAddCapacidadDialog(UsuarioProvider usuarioProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CapacidadesSelectorSheet(
        usuarioProvider: usuarioProvider,
        roleColor: _getRoleColor(),
      ),
    );
  }

  Future<void> _deleteCapacidad(String capacidadId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Skill',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this skill?',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final success = await usuarioProvider.eliminarCapacidad(capacidadId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Skill deleted successfully' : usuarioProvider.error ?? 'Error deleting skill'),
          backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.dangerRed, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Log out',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// =====================================================================
// Bottom Sheet para seleccionar capacidades
// =====================================================================
class _CapacidadesSelectorSheet extends StatefulWidget {
  final UsuarioProvider usuarioProvider;
  final Color roleColor;

  const _CapacidadesSelectorSheet({
    required this.usuarioProvider,
    required this.roleColor,
  });

  @override
  State<_CapacidadesSelectorSheet> createState() => _CapacidadesSelectorSheetState();
}

class _CapacidadesSelectorSheetState extends State<_CapacidadesSelectorSheet> {
  final Map<String, int> _selectedCapacidades = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Skills',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedCapacidades.isNotEmpty
                          ? () => _saveCapacidades()
                          : null,
                      child: Text(
                        'Save (${_selectedCapacidades.length})',
                        style: TextStyle(
                          color: _selectedCapacidades.isNotEmpty
                              ? widget.roleColor
                              : (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selected preview
              if (_selectedCapacidades.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCapacidades.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.roleColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                entry.value,
                                (i) => const Icon(Icons.star, size: 10, color: Color(0xFFF59E0B)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _selectedCapacidades.remove(entry.key)),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              // Capacidades list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: Capacidades.porCategoria.entries.map((category) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Text(
                            category.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...category.value.map((capacidad) {
                          final isSelected = _selectedCapacidades.containsKey(capacidad);
                          final alreadyAdded = widget.usuarioProvider.capacidades
                              .any((c) => c.nombre == capacidad);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: alreadyAdded ? null : () => _showLevelSelector(capacidad),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? widget.roleColor.withOpacity(0.1)
                                      : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.roleColor
                                        : (isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        capacidad,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: alreadyAdded
                                              ? (isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary)
                                              : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                          decoration: alreadyAdded ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    if (alreadyAdded)
                                      Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20)
                                    else if (isSelected)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ...List.generate(
                                            _selectedCapacidades[capacidad]!,
                                            (i) => const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.check_circle, color: widget.roleColor, size: 20),
                                        ],
                                      )
                                    else
                                      Icon(Icons.add_circle_outline, color: widget.roleColor, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLevelSelector(String capacidad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selectedLevel = _selectedCapacidades[capacidad] ?? 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            capacidad,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select your skill level',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedLevel ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => selectedLevel = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getLevelText(selectedLevel),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedCapacidades[capacidad] = selectedLevel);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.roleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelText(int level) {
    switch (level) {
      case 1: return 'Beginner';
      case 2: return 'Basic';
      case 3: return 'Intermediate';
      case 4: return 'Advanced';
      case 5: return 'Expert';
      default: return '';
    }
  }

  Future<void> _saveCapacidades() async {
    Navigator.pop(context);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: widget.roleColor),
      ),
    );

    final capacidades = _selectedCapacidades.entries
        .map((e) => CapacidadNivelItem(nombre: e.key, nivel: e.value))
        .toList();

    final success = await widget.usuarioProvider.agregarCapacidadesMultiples(capacidades);

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${capacidades.length} skill${capacidades.length > 1 ? 's' : ''} added successfully'
              : widget.usuarioProvider.error ?? 'Error adding skills',
        ),
        backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
