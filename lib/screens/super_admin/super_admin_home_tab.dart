import 'package:flutter/material.dart';
import '../../services/empresa_service.dart';
import '../../models/empresa_model.dart';
import '../../widgets/theme_toggle_button.dart';

class SuperAdminHomeTab extends StatefulWidget {
  const SuperAdminHomeTab({super.key});

  @override
  State<SuperAdminHomeTab> createState() => _SuperAdminHomeTabState();
}

class _SuperAdminHomeTabState extends State<SuperAdminHomeTab> {
  final EmpresaService _empresaService = EmpresaService();
  SystemStatsModel? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _empresaService.obtenerEstadisticasGenerales();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                            child: const Icon(Icons.admin_panel_settings, color: Color(0xFF7C3AED)),
                          ),
                          const Spacer(),
                          const ThemeToggleButton(),
                          IconButton(
                            icon: Icon(Icons.notifications_outlined, color: textPrimary),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dashboard Admin',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Panel de control general del sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // Stats Grid
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          icon: Icons.business,
                          title: 'Total Empresas',
                          value: '${_stats?.totalEmpresas ?? 0}',
                          color: const Color(0xFF7C3AED),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                        _buildStatCard(
                          icon: Icons.pending,
                          title: 'Pendientes',
                          value: '${_stats?.empresasPendientes ?? 0}',
                          color: const Color(0xFFF59E0B),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                        _buildStatCard(
                          icon: Icons.check_circle,
                          title: 'Aprobadas',
                          value: '${_stats?.empresasAprobadas ?? 0}',
                          color: const Color(0xFF10B981),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                        _buildStatCard(
                          icon: Icons.cancel,
                          title: 'Rechazadas',
                          value: '${_stats?.empresasRechazadas ?? 0}',
                          color: const Color(0xFFEF4444),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                      ],
                    ),
                  ),

                  // System Overview Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Resumen del Sistema',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),

                  // Overview Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildOverviewCard(
                          icon: Icons.groups,
                          title: 'Total Trabajadores',
                          value: '${_stats?.totalTrabajadores ?? 0}',
                          subtitle: 'Usuarios activos en el sistema',
                          color: const Color(0xFF135bec),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                        const SizedBox(height: 12),
                        _buildOverviewCard(
                          icon: Icons.assignment,
                          title: 'Tareas Activas',
                          value: '${_stats?.tareasActivas ?? 0}',
                          subtitle: 'Tareas en progreso',
                          color: const Color(0xFF7C3AED),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                        const SizedBox(height: 12),
                        _buildOverviewCard(
                          icon: Icons.task_alt,
                          title: 'Tareas Completadas',
                          value: '${_stats?.tareasCompletadas ?? 0}',
                          subtitle: 'Tareas finalizadas exitosamente',
                          color: const Color(0xFF10B981),
                          cardColor: cardColor,
                          textColor: textPrimary,
                          descColor: textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 100), // Extra space for bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color descColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF324467)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: descColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color descColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF324467)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: descColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
