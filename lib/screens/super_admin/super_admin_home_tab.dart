import 'package:flutter/material.dart';
import '../../services/empresa_service.dart';
import '../../models/empresa_model.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../config/theme_config.dart';
import '../../mixins/tarea_realtime_mixin.dart';
import '../../services/tarea_realtime_service.dart';

class SuperAdminHomeTab extends StatefulWidget {
  const SuperAdminHomeTab({super.key});

  @override
  State<SuperAdminHomeTab> createState() => _SuperAdminHomeTabState();
}

class _SuperAdminHomeTabState extends State<SuperAdminHomeTab> with SingleTickerProviderStateMixin, TareaRealtimeMixin {
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
    initRealtime(); // Conectar realtime
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    disposeRealtime();
    super.dispose();
  }

  @override
  void onTareaEvent(TareaEvent event) {
    // Cuando llega un evento de tarea, refrescar silenciosamente
    if (event.isTareaEvent && mounted) {
      _silentRefresh();
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final stats = await _empresaService.obtenerEstadisticasGenerales();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (_) {
      // Silencioso
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _empresaService.obtenerEstadisticasGenerales();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
              // Premium App Bar con animación mejorada
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 350;
                    final isVerySmallScreen = constraints.maxWidth < 300;

                    return Container(
                      margin: EdgeInsets.fromLTRB(
                        isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                        isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                        isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con avatar y acciones responsive
                          Row(
                            children: [
                              // Avatar con gradiente animado responsive
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
                                      blurRadius: isSmallScreen ? 12 : 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: isSmallScreen ? 22 : 28,
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Colors.white,
                                    size: isSmallScreen ? 26 : 32,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Theme toggle con estilo responsive
                              if (!isVerySmallScreen) ...[
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
                                SizedBox(width: isSmallScreen ? 8 : AppTheme.spaceSmall),
                              ],
                              // Notification badge responsive
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
                                    smallSize: isSmallScreen ? 6 : 8,
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary,
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                  ),
                                  onPressed: () {},
                                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 16 : AppTheme.spaceXLarge),
                          // Título responsive con gradiente
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: AppTheme.gradientPurple,
                                      ).createShader(bounds),
                                      child: Text(
                                        isVerySmallScreen ? 'Panel' : 'Dashboard Admin',
                                        style: TextStyle(
                                          fontSize: isVerySmallScreen ? 24 : isSmallScreen ? 28 : AppTheme.fontSizeHuge,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.1,
                                          letterSpacing: isSmallScreen ? -0.3 : -0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!isVerySmallScreen) ...[
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    RealtimeConnectionIndicator(
                                      isConnected: isRealtimeConnected,
                                      onReconnect: reconnectRealtime,
                                      connectedColor: AppTheme.primaryPurple,
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 6 : AppTheme.spaceXSmall),
                              Text(
                                isVerySmallScreen
                                    ? 'Control del sistema'
                                    : 'Panel de control general del sistema',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : AppTheme.fontSizeMedium,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Stats Grid con animación responsive
              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isVerySmallScreen = constraints.maxWidth < 300;
                        final isSmallScreen = constraints.maxWidth < 350;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isVerySmallScreen ? 50 : 60,
                              height: isVerySmallScreen ? 50 : 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppTheme.gradientPurple,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(0.4),
                                    blurRadius: isSmallScreen ? 12 : 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: isSmallScreen ? 2.5 : 3,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : AppTheme.spaceRegular),
                            Text(
                              isVerySmallScreen ? 'Cargando...' : 'Cargando estadísticas...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 14 : AppTheme.fontSizeMedium,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // Stats Grid (when not loading)
              if (!_isLoading)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceRegular),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final isVerySmallScreen = constraints.crossAxisExtent < 300;
                      final isSmallScreen = constraints.crossAxisExtent < 350;
                      final isMediumScreen = constraints.crossAxisExtent < 600;

                      int crossAxisCount = isVerySmallScreen ? 1 : (isSmallScreen ? 1 : 2);
                      double childAspectRatio = isVerySmallScreen ? 1.8 : (isSmallScreen ? 2.0 : 1.35);
                      double mainAxisSpacing = isVerySmallScreen ? 8 : (isSmallScreen ? 12 : AppTheme.spaceMedium);
                      double crossAxisSpacing = isVerySmallScreen ? 8 : (isSmallScreen ? 12 : AppTheme.spaceMedium);

                      if (isMediumScreen && !isSmallScreen) {
                        crossAxisCount = 2;
                        childAspectRatio = 1.4;
                      }

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: mainAxisSpacing,
                          crossAxisSpacing: crossAxisSpacing,
                          childAspectRatio: childAspectRatio,
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
                      );
                    },
                  ),
                ),

              // System Overview Section responsive
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isVerySmallScreen = constraints.maxWidth < 300;
                    final isSmallScreen = constraints.maxWidth < 350;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                        isVerySmallScreen ? 16 : AppTheme.spaceXLarge,
                        isVerySmallScreen ? 8 : AppTheme.spaceRegular,
                        isVerySmallScreen ? 12 : AppTheme.spaceMedium,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isVerySmallScreen ? 3 : 4,
                            height: isSmallScreen ? 20 : 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppTheme.gradientPurple,
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(isVerySmallScreen ? 2 : 3),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : AppTheme.spaceMedium),
                          Flexible(
                            child: Text(
                              isVerySmallScreen ? 'Sistema' : 'Resumen del Sistema',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : AppTheme.fontSizeXLarge),
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Overview Cards responsive
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceRegular),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isVerySmallScreen = constraints.maxWidth < 300;
                        final isSmallScreen = constraints.maxWidth < 350;

                        return Column(
                          children: [
                            _buildPremiumOverviewCard(
                              icon: Icons.groups_rounded,
                              title: isVerySmallScreen ? 'Trabajadores' : 'Total Trabajadores',
                              value: '${_stats?.totalTrabajadores ?? 0}',
                              subtitle: isVerySmallScreen ? 'Activos' : 'Usuarios activos en el sistema',
                              color: AppTheme.primaryBlue,
                              isDark: isDark,
                              isCompact: isVerySmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : AppTheme.spaceMedium),
                            _buildPremiumOverviewCard(
                              icon: Icons.assignment_rounded,
                              title: isVerySmallScreen ? 'Activas' : 'Tareas Activas',
                              value: '${_stats?.tareasActivas ?? 0}',
                              subtitle: isVerySmallScreen ? 'En progreso' : 'Tareas en progreso',
                              color: AppTheme.primaryPurple,
                              isDark: isDark,
                              isCompact: isVerySmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : AppTheme.spaceMedium),
                            _buildPremiumOverviewCard(
                              icon: Icons.task_alt_rounded,
                              title: isVerySmallScreen ? 'Completadas' : 'Tareas Completadas',
                              value: '${_stats?.tareasCompletadas ?? 0}',
                              subtitle: isVerySmallScreen ? 'Finalizadas' : 'Tareas finalizadas exitosamente',
                              color: AppTheme.successGreen,
                              isDark: isDark,
                              isCompact: isVerySmallScreen,
                            ),
                            SizedBox(height: isVerySmallScreen ? 60 : 100), // Extra space for bottom nav
                          ],
                        );
                      },
                    ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmallScreen = constraints.maxWidth < 300;
        final isSmallScreen = constraints.maxWidth < 350;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + delay),
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
              borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : AppTheme.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: isSmallScreen ? 12 : 20,
                  offset: Offset(0, isSmallScreen ? 4 : 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Patrón de fondo responsivo
                Positioned(
                  right: isVerySmallScreen ? -15 : -20,
                  top: isVerySmallScreen ? -15 : -20,
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      icon,
                      size: isSmallScreen ? 80 : (isVerySmallScreen ? 60 : 120),
                      color: Colors.white,
                    ),
                  ),
                ),
                // Contenido responsivo
                Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : AppTheme.spaceRegular),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon container responsivo
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : AppTheme.radiusMedium),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : AppTheme.iconRegular,
                        ),
                      ),
                      // Value and title responsivos
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 28 : (isSmallScreen ? 32 : 36),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                              letterSpacing: isSmallScreen ? -0.8 : -1,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : AppTheme.spaceXSmall),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : AppTheme.fontSizeSmall),
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                            maxLines: isVerySmallScreen ? 2 : 1,
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
      },
    );
  }

  Widget _buildPremiumOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
    bool isCompact = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmallScreen = constraints.maxWidth < 300;
        final isSmallScreen = constraints.maxWidth < 350;
        final useCompactLayout = isCompact || isVerySmallScreen;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : AppTheme.radiusXLarge),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder.withOpacity(0.5)
                  : AppTheme.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: isSmallScreen ? 6 : 10,
                offset: Offset(0, isSmallScreen ? 2 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(useCompactLayout ? 12 : AppTheme.spaceRegular),
            child: useCompactLayout
                ? // Compact layout for very small screens
                Row(
                    children: [
                      // Icon container compact
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : AppTheme.radiusLarge),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      // Textos compact
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      // Value compact
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 6,
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
                          borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  )
                : // Normal layout for larger screens
                Row(
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
      },
    );
  }
}
