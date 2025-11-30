import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../providers/usuario_provider.dart';
import '../../models/capacidad_nivel_item.dart';
import '../../config/capacidades.dart';
import '../../config/theme_config.dart';
import '../../models/usuario.dart';

/// Tipos de rol para el profile screen
enum ProfileRole { worker, manager, adminEmpresa, superAdmin }

/// Profile Screen unificado para todos los roles
/// Features específicas por rol:
/// - Worker: Gestión de capacidades + estadísticas de tareas
/// - Manager: Estadísticas de equipo
/// - AdminEmpresa: Estadísticas de empresa
/// - SuperAdmin: Sin features específicas adicionales
class ProfileScreen extends StatefulWidget {
  final ProfileRole role;

  const ProfileScreen({super.key, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar perfil completo con estadísticas
      Provider.of<UsuarioProvider>(context, listen: false).cargarPerfilCompleto();
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
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: Consumer<UsuarioProvider>(
        builder: (context, usuarioProvider, child) {
          if (usuarioProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: roleColor));
          }

          final usuario = usuarioProvider.usuario;
          if (usuario == null) {
            return _buildErrorState(isDark, roleColor);
          }

          return RefreshIndicator(
            color: roleColor,
            onRefresh: () => usuarioProvider.cargarPerfilCompleto(),
            child: CustomScrollView(
              slivers: [
                // Header con AppBar simple
                SliverAppBar(
                  pinned: true,
                  backgroundColor: isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightCard,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                  elevation: 0,
                ),

                // Content
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isVerySmallScreen = constraints.maxWidth < 300;
                      final isSmallScreen = constraints.maxWidth < 350;

                      return Padding(
                        padding: EdgeInsets.all(isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
                        child: Column(
                          children: [
                            // Profile Avatar Section responsivo
                            _buildProfileHeader(usuario, isDark, roleColor, isVerySmallScreen, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 24),

                            // Task Stats Section - Solo para Worker/Manager
                            if (widget.role == ProfileRole.worker || 
                                widget.role == ProfileRole.manager) ...[
                              _buildTaskStatsSection(usuarioProvider, isDark, roleColor),
                              const SizedBox(height: 24),
                            ],

                            // Account Section
                            _buildAccountSection(usuario, isDark, roleColor),
                            const SizedBox(height: 24),

                            // Capacidades Section - Solo para Worker
                            if (widget.role == ProfileRole.worker) ...[
                              _buildCapacidadesSection(
                                usuario,
                                usuarioProvider,
                                isDark,
                                roleColor,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Member Since Section
                            _buildMemberSinceSection(usuario, isDark, roleColor),
                            const SizedBox(height: 24),

                            // Logout Button
                            _buildLogoutButton(isDark),

                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Usuario usuario, bool isDark, Color roleColor, bool isVerySmallScreen, bool isSmallScreen) {
    final double avatarSize = isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120);
    final double fontSizeName = isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 24);
    final double fontSizeEmail = isVerySmallScreen ? 12 : 14;
    final double fontSizeBadge = isVerySmallScreen ? 9 : 10;

    return Column(
      children: [
        // Avatar con role badge responsivo
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [roleColor, roleColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: roleColor.withOpacity(0.3),
                    blurRadius: isSmallScreen ? 12 : 20,
                    offset: Offset(0, isSmallScreen ? 4 : 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(usuario.nombreCompleto),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: avatarSize * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Role badge responsivo
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 6 : 8,
                  vertical: isVerySmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: BorderRadius.circular(isVerySmallScreen ? 8 : 12),
                  border: Border.all(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    width: isVerySmallScreen ? 2 : 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withOpacity(0.3),
                      blurRadius: isSmallScreen ? 6 : 10,
                      offset: Offset(0, isSmallScreen ? 2 : 4),
                    ),
                  ],
                ),
                child: Text(
                  usuario.rolDisplayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSizeBadge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        // Name responsivo
        Text(
          usuario.nombreCompleto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSizeName,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            height: 1.2,
          ),
          maxLines: isVerySmallScreen ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isSmallScreen ? 3 : 4),
        // Email responsivo
        Text(
          usuario.email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSizeEmail,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          maxLines: isVerySmallScreen ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Department badge responsivo
        if (usuario.departamento != null) ...[
          SizedBox(height: isSmallScreen ? 6 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen ? 8 : 12,
              vertical: isVerySmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : 20),
              border: Border.all(
                color: roleColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: isVerySmallScreen ? 12 : 14,
                  color: roleColor,
                ),
                SizedBox(width: isVerySmallScreen ? 4 : 6),
                Flexible(
                  child: Text(
                    usuario.departamentoDisplayName ?? usuario.departamento!,
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTaskStatsSection(UsuarioProvider provider, bool isDark, Color roleColor) {
    final stats = provider.dashboardStats;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder,
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics_outlined, color: roleColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'My Task Stats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoadingStats)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (stats != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.task_alt_rounded,
                      label: 'Total',
                      value: stats.total.toString(),
                      color: AppTheme.primaryBlue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Completed',
                      value: stats.finalizadas.toString(),
                      color: AppTheme.successGreen,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'In Progress',
                      value: stats.enProgreso.toString(),
                      color: AppTheme.warningOrange,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.priority_high_rounded,
                      label: 'Urgent',
                      value: stats.urgentes.toString(),
                      color: AppTheme.dangerRed,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completion Rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '${stats.porcentajeCompletado.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats.porcentajeCompletado / 100,
                      backgroundColor: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(roleColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No stats available',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(Usuario usuario, bool isDark, Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder,
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
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_outline_rounded, color: roleColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildAccountItem(
            icon: Icons.person_outline_rounded,
            title: 'Full Name',
            value: usuario.nombreCompleto,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildAccountItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: usuario.email,
            isDark: isDark,
          ),
          if (usuario.telefono != null && usuario.telefono!.isNotEmpty) ...[
            _buildDivider(isDark),
            _buildAccountItem(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: usuario.telefono!,
              isDark: isDark,
            ),
          ],
          _buildDivider(isDark),
          _buildAccountItem(
            icon: Icons.badge_outlined,
            title: 'Role',
            value: usuario.rolDisplayName,
            isDark: isDark,
            valueColor: roleColor,
          ),
          if (usuario.departamento != null) ...[
            _buildDivider(isDark),
            _buildAccountItem(
              icon: Icons.business_outlined,
              title: 'Department',
              value: usuario.departamentoDisplayName ?? usuario.departamento!,
              isDark: isDark,
            ),
          ],
          if (usuario.nivelHabilidad != null) ...[
            _buildDivider(isDark),
            _buildAccountItem(
              icon: Icons.trending_up_rounded,
              title: 'Skill Level',
              value: _getSkillLevelText(usuario.nivelHabilidad!),
              isDark: isDark,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < usuario.nivelHabilidad!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
          ],
          _buildDivider(isDark),
          _buildAccountItem(
            icon: Icons.verified_outlined,
            title: 'Status',
            value: usuario.isActive ? 'Active' : 'Inactive',
            isDark: isDark,
            valueColor: usuario.isActive ? AppTheme.successGreen : AppTheme.dangerRed,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getSkillLevelText(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Basic';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Level $level';
    }
  }

  Widget _buildMemberSinceSection(Usuario usuario, bool isDark, Color roleColor) {
    final createdAt = usuario.createdAt;
    final memberSinceText = createdAt != null
        ? DateFormat('MMMM d, yyyy').format(createdAt)
        : 'Unknown';
    
    final daysSinceJoining = createdAt != null
        ? DateTime.now().difference(createdAt).inDays
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_rounded, color: roleColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Member Since',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memberSinceText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$daysSinceJoining days ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: roleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Padding(
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
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Log out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dangerRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ignore: unused_element - Reservado para uso futuro
  String _getRoleDisplayName() {
    switch (widget.role) {
      case ProfileRole.worker:
        return 'Worker';
      case ProfileRole.manager:
        return 'Manager';
      case ProfileRole.adminEmpresa:
        return 'Company Admin';
      case ProfileRole.superAdmin:
        return 'Super Admin';
    }
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
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<UsuarioProvider>(
                context,
                listen: false,
              ).cargarPerfilCompleto();
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

  Widget _buildCapacidadesSection(
    Usuario usuario,
    UsuarioProvider usuarioProvider,
    bool isDark,
    Color roleColor,
  ) {
    return _buildSettingsSection(
      title: 'My Skills',
      icon: Icons.psychology_outlined,
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
                  color: isDark
                      ? AppTheme.darkTextTertiary
                      : AppTheme.lightTextTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No skills added yet',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _showAddCapacidadDialog(usuarioProvider),
                  icon: Icon(Icons.add_rounded, color: roleColor, size: 18),
                  label: Text(
                    'Add your first skill',
                    style: TextStyle(
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                    ),
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
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < nivel
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
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
    required IconData icon,
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
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: roleColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
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

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 74,
      color: isDark
          ? AppTheme.darkBorder.withOpacity(0.3)
          : AppTheme.lightBorder,
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
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this skill?',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final success = await usuarioProvider.eliminarCapacidad(capacidadId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Skill deleted successfully'
                : usuarioProvider.error ?? 'Error deleting skill',
          ),
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
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.dangerRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Log out',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
  State<_CapacidadesSelectorSheet> createState() =>
      _CapacidadesSelectorSheetState();
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
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
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
                              : (isDark
                                    ? AppTheme.darkTextTertiary
                                    : AppTheme.lightTextTertiary),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCapacidades.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                                (i) => const Icon(
                                  Icons.star,
                                  size: 10,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(
                                () => _selectedCapacidades.remove(entry.key),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
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
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...category.value.map((capacidad) {
                          final isSelected = _selectedCapacidades.containsKey(
                            capacidad,
                          );
                          final alreadyAdded = widget
                              .usuarioProvider
                              .capacidades
                              .any((c) => c.nombre == capacidad);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: alreadyAdded
                                  ? null
                                  : () => _showLevelSelector(capacidad),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? widget.roleColor.withOpacity(0.1)
                                      : (isDark
                                            ? AppTheme.darkBackground
                                            : AppTheme.lightBackground),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.roleColor
                                        : (isDark
                                              ? AppTheme.darkBorder.withOpacity(
                                                  0.3,
                                                )
                                              : AppTheme.lightBorder),
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
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: alreadyAdded
                                              ? (isDark
                                                    ? AppTheme.darkTextTertiary
                                                    : AppTheme
                                                          .lightTextTertiary)
                                              : (isDark
                                                    ? AppTheme.darkTextPrimary
                                                    : AppTheme
                                                          .lightTextPrimary),
                                          decoration: alreadyAdded
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (alreadyAdded)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppTheme.successGreen,
                                        size: 20,
                                      )
                                    else if (isSelected)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ...List.generate(
                                            _selectedCapacidades[capacidad]!,
                                            (i) => const Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Color(0xFFF59E0B),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.check_circle,
                                            color: widget.roleColor,
                                            size: 20,
                                          ),
                                        ],
                                      )
                                    else
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: widget.roleColor,
                                        size: 20,
                                      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            capacidad,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select your skill level',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedLevel
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
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
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
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
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
      case 1:
        return 'Beginner';
      case 2:
        return 'Basic';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return '';
    }
  }

  Future<void> _saveCapacidades() async {
    Navigator.pop(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: widget.roleColor)),
    );

    final capacidades = _selectedCapacidades.entries
        .map((e) => CapacidadNivelItem(nombre: e.key, nivel: e.value))
        .toList();

    final success = await widget.usuarioProvider.agregarCapacidadesMultiples(
      capacidades,
    );

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
