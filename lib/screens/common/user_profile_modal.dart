import 'package:flutter/material.dart';
import '../../services/usuario_service.dart';
import '../../models/usuario.dart';
import '../../config/theme_config.dart';

class UserProfileModal extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileModal({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileModal> createState() => _UserProfileModalState();
}

class _UserProfileModalState extends State<UserProfileModal> {
  final UsuarioService _usuarioService = UsuarioService();
  Usuario? _usuario;
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
      final usuario = await _usuarioService.getUsuarioById(widget.userId);
      setState(() {
        _usuario = usuario;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Perfil de Usuario',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppTheme.dangerRed,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar perfil',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildProfileContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isDark) {
    if (_usuario == null) return const SizedBox();

    final initials = _getInitials(_usuario!.nombreCompleto);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  const Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Name
          Text(
            _usuario!.nombreCompleto,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getRoleColor().withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(),
                  size: 16,
                  color: _getRoleColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  _getRoleText(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Cards
          _buildInfoCard(
            isDark: isDark,
            icon: Icons.email_outlined,
            label: 'Email',
            value: _usuario!.email,
          ),

          if (_usuario!.telefono != null && _usuario!.telefono!.isNotEmpty)
            _buildInfoCard(
              isDark: isDark,
              icon: Icons.phone_outlined,
              label: 'Teléfono',
              value: _usuario!.telefono!,
            ),

          if (_usuario!.departamento != null && _usuario!.departamento!.isNotEmpty)
            _buildInfoCard(
              isDark: isDark,
              icon: Icons.apartment_outlined,
              label: 'Departamento',
              value: _usuario!.departamento!,
            ),

          if (_usuario!.nivelHabilidad != null)
            _buildInfoCard(
              isDark: isDark,
              icon: Icons.star_outline,
              label: 'Nivel de Habilidad',
              value: 'Nivel ${_usuario!.nivelHabilidad}',
            ),

          // Capacidades Section
          if (_usuario!.capacidades.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Capacidades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _usuario!.capacidades.map((capacidad) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        capacidad.nombre,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackground.withOpacity(0.5)
            : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getRoleColor() {
    if (_usuario!.rol == 'AdminGeneral') return const Color(0xFF9F7AEA);
    if (_usuario!.rol == 'AdminEmpresa') return AppTheme.primaryBlue;
    if (_usuario!.rol == 'ManagerDepartamento') return AppTheme.successGreen;
    return const Color(0xFF10B981);
  }

  IconData _getRoleIcon() {
    if (_usuario!.rol == 'AdminGeneral') return Icons.admin_panel_settings;
    if (_usuario!.rol == 'AdminEmpresa') return Icons.business_center;
    if (_usuario!.rol == 'ManagerDepartamento') return Icons.manage_accounts;
    return Icons.person;
  }

  String _getRoleText() {
    if (_usuario!.rol == 'AdminGeneral') return 'Administrador General';
    if (_usuario!.rol == 'AdminEmpresa') return 'Administrador de Empresa';
    if (_usuario!.rol == 'ManagerDepartamento') return 'Manager de Departamento';
    return 'Trabajador';
  }
}
