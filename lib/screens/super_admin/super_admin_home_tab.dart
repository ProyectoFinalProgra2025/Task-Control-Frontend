import 'package:flutter/material.dart';
import '../../services/empresa_service.dart';
import '../../models/empresa_model.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../config/theme_config.dart';

class SuperAdminHomeTab extends StatefulWidget {
  const SuperAdminHomeTab({super.key});

  @override
  State<SuperAdminHomeTab> createState() => _SuperAdminHomeTabState();
}

class _SuperAdminHomeTabState extends State<SuperAdminHomeTab> with SingleTickerProviderStateMixin {
  final EmpresaService _empresaService = EmpresaService();
  SystemStatsModel? _stats;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _empresaService.obtenerEstadisticasGenerales();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.primaryPurple,
          strokeWidth: 3,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Premium App Bar con animación
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppTheme.spaceRegular,
                    AppTheme.spaceRegular,
                    AppTheme.spaceRegular,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con avatar y acciones
                      Row(
                        children: [
                          // Avatar con gradiente animado
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: AppTheme.gradientPurple,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Theme toggle con estilo
                          Container(
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.darkCard : AppTheme.lightCard)
                                  .withOpacity(0.6),
                              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                              border: Border.all(
                                color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                                    .withOpacity(0.5),
                              ),
                            ),
                            child: const ThemeToggleButton(),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          // Notification badge
                          Container(
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.darkCard : AppTheme.lightCard)
                                  .withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                                    .withOpacity(0.5),
                              ),
                            ),
                            child: IconButton(
                              icon: Badge(
                                backgroundColor: AppTheme.dangerRed,
                                smallSize: 8,
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXLarge),
                      // Título con gradiente
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppTheme.gradientPurple,
                        ).createShader(bounds),
                        child: Text(
                          'Dashboard Admin',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeHuge,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        'Panel de control general del sistema',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Grid con animación
              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppTheme.gradientPurple,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceRegular),
                        Text(
                          'Cargando estadísticas...',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceRegular),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppTheme.spaceMedium,
                      crossAxisSpacing: AppTheme.spaceMedium,
                      childAspectRatio: 1.35,
                    ),
                    delegate: SliverChildListDelegate([
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAnimatedStatCard(
                          icon: Icons.business_center_rounded,
                          title: 'Total Empresas',
                          value: '${_stats?.totalEmpresas ?? 0}',
                          gradientColors: AppTheme.gradientPurple,
                          isDark: isDark,
                          delay: 0,
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAnimatedStatCard(
                          icon: Icons.pending_actions_rounded,
                          title: 'Pendientes',
                          value: '${_stats?.empresasPendientes ?? 0}',
                          gradientColors: AppTheme.gradientOrange,
                          isDark: isDark,
                          delay: 100,
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAnimatedStatCard(
                          icon: Icons.check_circle_rounded,
                          title: 'Aprobadas',
                          value: '${_stats?.empresasAprobadas ?? 0}',
                          gradientColors: [AppTheme.successGreen, const Color(0xFF059669)],
                          isDark: isDark,
                          delay: 200,
                        ),
                      ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAnimatedStatCard(
                          icon: Icons.cancel_rounded,
                          title: 'Rechazadas',
                          value: '${_stats?.empresasRechazadas ?? 0}',
                          gradientColors: [AppTheme.dangerRed, const Color(0xFFDC2626)],
                          isDark: isDark,
                          delay: 300,
                        ),
                      ),
                    ]),
                  ),
                ),

              // System Overview Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceRegular,
                    AppTheme.spaceXLarge,
                    AppTheme.spaceRegular,
                    AppTheme.spaceMedium,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppTheme.gradientPurple,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMedium),
                      Text(
                        'Resumen del Sistema',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overview Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceRegular),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPremiumOverviewCard(
                      icon: Icons.groups_rounded,
                      title: 'Total Trabajadores',
                      value: '${_stats?.totalTrabajadores ?? 0}',
                      subtitle: 'Usuarios activos en el sistema',
                      color: AppTheme.primaryBlue,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    _buildPremiumOverviewCard(
                      icon: Icons.assignment_rounded,
                      title: 'Tareas Activas',
                      value: '${_stats?.tareasActivas ?? 0}',
                      subtitle: 'Tareas en progreso',
                      color: AppTheme.primaryPurple,
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    _buildPremiumOverviewCard(
                      icon: Icons.task_alt_rounded,
                      title: 'Tareas Completadas',
                      value: '${_stats?.tareasCompletadas ?? 0}',
                      subtitle: 'Tareas finalizadas exitosamente',
                      color: AppTheme.successGreen,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 100), // Extra space for bottom nav
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
    required bool isDark,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Patrón de fondo sutil
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: AppTheme.iconRegular),
                  ),
                  // Value and title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.5)
              : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceRegular),
        child: Row(
          children: [
            // Icon container con gradiente
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: AppTheme.iconMedium),
            ),
            const SizedBox(width: AppTheme.spaceRegular),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            // Value con efecto
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXXLarge,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
