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

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

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
      // Cargar usuario actual
      final user = await _usuarioService.getMe();

      // Cargar estadísticas de la empresa
      final empresaId = await _storage.getEmpresaId();
      Map<String, dynamic> stats;
      if (empresaId != null) {
        stats = await _empresaService.obtenerEstadisticas(empresaId);
      } else {
        throw Exception('No se encontró el ID de la empresa');
      }

      // Cargar tareas recientes (ongoing = asignadas + aceptadas)
      final todasTareas = await _tareaService.getTareas();
      final tareasOngoing = todasTareas
          .where(
            (t) =>
                t.estado == EstadoTarea.asignada ||
                t.estado == EstadoTarea.aceptada,
          )
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

    // Si se creó una tarea, recargar datos
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF101622)
        : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark
        ? const Color(0xFF92a4c9)
        : const Color(0xFF64748b);

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
                onPressed: _loadData,
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
          child: SingleChildScrollView(
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
                            backgroundColor: const Color(
                              0xFF135bec,
                            ).withOpacity(0.1),
                            child: Text(
                              userInitials,
                              style: const TextStyle(
                                color: Color(0xFF135bec),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const ThemeToggleButton(),
                          IconButton(
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: textPrimary,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bienvenido, $firstName',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      if (empresaNombre.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          empresaNombre,
                          style: TextStyle(fontSize: 16, color: textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),

                // Quick Action Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildQuickActionCard(
                        icon: Icons.add_task,
                        title: 'Create Task',
                        description: 'Assign new tasks',
                        color: const Color(0xFF135bec),
                        cardColor: cardColor,
                        textColor: textPrimary,
                        descColor: textSecondary,
                        onTap: _showCreateTaskModal,
                      ),
                      _buildQuickActionCard(
                        icon: Icons.group,
                        title: 'View Team',
                        description:
                            '${_estadisticas?['totalTrabajadores'] ?? 0} miembros',
                        color: const Color(0xFF7C3AED),
                        cardColor: cardColor,
                        textColor: textPrimary,
                        descColor: textSecondary,
                        onTap: _navigateToTeamManagement,
                      ),
                    ],
                  ),
                ),

                // Task Summary Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Task Summary',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),

                // Task Statistics Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        title: 'Total',
                        count: _estadisticas?['totalTareas'] ?? 0,
                        icon: Icons.task_alt,
                        color: const Color(0xFF135bec),
                        cardColor: cardColor,
                        textColor: textPrimary,
                        isDark: isDark,
                      ),
                      _buildStatCard(
                        title: 'Pendientes',
                        count: _estadisticas?['tareasPendientes'] ?? 0,
                        icon: Icons.pending_actions,
                        color: const Color(0xFFF59E0B),
                        cardColor: cardColor,
                        textColor: textPrimary,
                        isDark: isDark,
                      ),
                      _buildStatCard(
                        title: 'En Progreso',
                        count:
                            ((_estadisticas?['tareasAsignadas'] ?? 0) +
                            (_estadisticas?['tareasAceptadas'] ?? 0)),
                        icon: Icons.hourglass_empty,
                        color: const Color(0xFF7C3AED),
                        cardColor: cardColor,
                        textColor: textPrimary,
                        isDark: isDark,
                      ),
                      _buildStatCard(
                        title: 'Finalizadas',
                        count: _estadisticas?['tareasFinalizadas'] ?? 0,
                        icon: Icons.check_circle,
                        color: const Color(0xFF10B981),
                        cardColor: cardColor,
                        textColor: textPrimary,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Recent Tasks
                if (_tareasRecientes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Tareas Recientes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF324467)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tareasRecientes.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF324467)
                              : const Color(0xFFE5E7EB),
                        ),
                        itemBuilder: (context, index) {
                          final tarea = _tareasRecientes[index];
                          return _buildTaskItem(
                            tarea: tarea,
                            textColor: textPrimary,
                            descColor: textSecondary,
                          );
                        },
                      ),
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color descColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: descColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required Tarea tarea,
    required Color textColor,
    required Color descColor,
  }) {
    final statusColor = _getStatusColor(tarea.estado);
    final statusText = _getStatusText(tarea.estado);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        tarea.titulo,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        tarea.asignadoANombre ?? 'No asignado',
        style: TextStyle(fontSize: 14, color: descColor),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return const Color(0xFFF59E0B);
      case EstadoTarea.asignada:
        return const Color(0xFF135bec);
      case EstadoTarea.aceptada:
        return const Color(0xFF7C3AED);
      case EstadoTarea.finalizada:
        return const Color(0xFF10B981);
      case EstadoTarea.cancelada:
        return const Color(0xFFEF4444);
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
