import 'package:flutter/material.dart';
import '../../widgets/create_task_modal.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../services/usuario_service.dart';
import '../../services/empresa_service.dart';
import '../../services/tarea_service.dart';
import '../../services/storage_service.dart';
import '../../models/usuario.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import 'team_management_screen.dart';
import '../../config/theme_config.dart';

class AdminHomeTab extends StatefulWidget {
  final VoidCallback? onNavigateToTasks;

  const AdminHomeTab({super.key, this.onNavigateToTasks});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final UsuarioService _usuarioService = UsuarioService();
  final EmpresaService _empresaService = EmpresaService();
  final TareaService _tareaService = TareaService();
  final StorageService _storage = StorageService();

  Usuario? _currentUser;
  Map<String, dynamic>? _estadisticas;
  List<Tarea> _tareasRecientes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _usuarioService.getMe();
      final empresaId = await _storage.getEmpresaId();
      Map<String, dynamic> stats;
      if (empresaId != null) {
        stats = await _empresaService.obtenerEstadisticas(empresaId);
      } else {
        throw Exception('No se encontró el ID de la empresa');
      }

      final todasTareas = await _tareaService.getTareas();
      final tareasOngoing = todasTareas
          .where((t) => t.estado == EstadoTarea.asignada || t.estado == EstadoTarea.aceptada)
          .take(5)
          .toList();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _estadisticas = stats;
          _tareasRecientes = tareasOngoing;
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

  void _showCreateTaskModal() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTaskModal(),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.dangerRed),
              const SizedBox(height: 16),
              Text('Error: $_error', style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final firstName = _currentUser?.nombreCompleto.split(' ').first ?? 'Admin';
    final userInitials = _getInitials(_currentUser?.nombreCompleto ?? '');
    final empresaNombre = _estadisticas?['nombreEmpresa'] ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder, width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                userInitials,
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const ThemeToggleButton(),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.notifications_outlined, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bienvenido, $firstName',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (empresaNombre.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.business_rounded, size: 14, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    empresaNombre,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.add_task_rounded,
                          title: 'Nueva Tarea',
                          subtitle: 'Asignar trabajo',
                          color: AppTheme.primaryBlue,
                          onTap: _showCreateTaskModal,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.groups_rounded,
                          title: 'Ver Equipo',
                          subtitle: '${_estadisticas?['totalTrabajadores'] ?? 0} miembros',
                          color: const Color(0xFF7C3AED),
                          onTap: _navigateToTeamManagement,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Task Metrics
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Métricas de Tareas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildMetricCard(
                        title: 'Total',
                        value: '${_estadisticas?['totalTareas'] ?? 0}',
                        icon: Icons.task_alt_rounded,
                        color: AppTheme.primaryBlue,
                        isDark: isDark,
                      ),
                      _buildMetricCard(
                        title: 'Pendientes',
                        value: '${_estadisticas?['tareasPendientes'] ?? 0}',
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.warningOrange,
                        isDark: isDark,
                      ),
                      _buildMetricCard(
                        title: 'En Progreso',
                        value: '${((_estadisticas?['tareasAsignadas'] ?? 0) + (_estadisticas?['tareasAceptadas'] ?? 0))}',
                        icon: Icons.hourglass_empty_rounded,
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                      ),
                      _buildMetricCard(
                        title: 'Completadas',
                        value: '${_estadisticas?['tareasFinalizadas'] ?? 0}',
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.successGreen,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Recent Tasks
                if (_tareasRecientes.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tareas Recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onNavigateToTasks,
                          child: const Text('Ver todas', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tareasRecientes.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                        itemBuilder: (context, index) => _buildTaskItem(_tareasRecientes[index], isDark),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Tarea tarea, bool isDark) {
    final statusColor = _getStatusColor(tarea.estado);
    final statusText = _getStatusText(tarea.estado);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      title: Text(
        tarea.titulo,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          tarea.asignadoANombre ?? 'No asignado',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return AppTheme.warningOrange;
      case EstadoTarea.asignada:
        return AppTheme.primaryBlue;
      case EstadoTarea.aceptada:
        return const Color(0xFF7C3AED);
      case EstadoTarea.finalizada:
        return AppTheme.successGreen;
      case EstadoTarea.cancelada:
        return AppTheme.dangerRed;
    }
  }

  String _getStatusText(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return 'Pendiente';
      case EstadoTarea.asignada:
        return 'Asignada';
      case EstadoTarea.aceptada:
        return 'Aceptada';
      case EstadoTarea.finalizada:
        return 'Finalizada';
      case EstadoTarea.cancelada:
        return 'Cancelada';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  void _navigateToTeamManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TeamManagementScreen()),
    );
  }
}
