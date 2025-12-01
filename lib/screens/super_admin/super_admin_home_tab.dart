import 'package:flutter/material.dart';
import 'dart:math' as math;
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primaryPurple,
        strokeWidth: 3,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Header elegante con avatar
            SliverToBoxAdapter(
              child: _buildHeader(isDark, size),
            ),

            // Stats Grid moderno
            if (_isLoading)
              SliverFillRemaining(
                child: _buildLoadingState(isDark),
              ),

            if (!_isLoading) ...[
              // Grid de métricas principales
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMetricCard(
                        icon: Icons.business_rounded,
                        label: 'Total Empresas',
                        value: '${_stats?.totalEmpresas ?? 0}',
                        gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                        iconBgColor: Colors.white.withOpacity(0.2),
                        isDark: isDark,
                      ),
                    ),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMetricCard(
                        icon: Icons.schedule_rounded,
                        label: 'Pendientes',
                        value: '${_stats?.empresasPendientes ?? 0}',
                        gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
                        iconBgColor: Colors.white.withOpacity(0.2),
                        isDark: isDark,
                      ),
                    ),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMetricCard(
                        icon: Icons.verified_rounded,
                        label: 'Aprobadas',
                        value: '${_stats?.empresasAprobadas ?? 0}',
                        gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                        iconBgColor: Colors.white.withOpacity(0.2),
                        isDark: isDark,
                      ),
                    ),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildMetricCard(
                        icon: Icons.block_rounded,
                        label: 'Rechazadas',
                        value: '${_stats?.empresasRechazadas ?? 0}',
                        gradient: const [Color(0xFFEB3349), Color(0xFFF45C43)],
                        iconBgColor: Colors.white.withOpacity(0.2),
                        isDark: isDark,
                      ),
                    ),
                  ]),
                ),
              ),

              // Sección de resumen del sistema
              SliverToBoxAdapter(
                child: _buildSystemSummarySection(isDark),
              ),

              // Cards de resumen
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummaryCard(
                      icon: Icons.groups_rounded,
                      title: 'Total Trabajadores',
                      value: '${_stats?.totalTrabajadores ?? 0}',
                      subtitle: 'Usuarios activos en el sistema',
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      icon: Icons.task_alt_rounded,
                      title: 'Tareas Activas',
                      value: '${_stats?.tareasActivas ?? 0}',
                      subtitle: 'Tareas en progreso',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      icon: Icons.check_circle_rounded,
                      title: 'Tareas Completadas',
                      value: '${_stats?.tareasCompletadas ?? 0}',
                      subtitle: 'Tareas finalizadas exitosamente',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Size size) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar con avatar y acciones
          Row(
            children: [
              // Avatar con gradiente
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF667EEA),
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
              // Theme toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08) 
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ThemeToggleButton(),
              ),
              const SizedBox(width: 12),
              // Notificaciones
              Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withOpacity(0.08) 
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Título y subtítulo
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Dashboard Admin',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        RealtimeConnectionIndicator(
                          isConnected: isRealtimeConnected,
                          onReconnect: reconnectRealtime,
                          connectedColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Panel de control general del sistema',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
    required Color iconBgColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración de fondo
          Positioned(
            right: -20,
            top: -20,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // Valor y label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSummarySection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Resumen del Sistema',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1F2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.08) 
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono con fondo gradiente suave
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Valor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
