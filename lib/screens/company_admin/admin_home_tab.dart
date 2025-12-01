import 'package:flutter/material.dart';
import '../../widgets/create_task_modal.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/calendar/task_calendar_widget.dart';
import '../../services/usuario_service.dart';
import '../../services/empresa_service.dart';
import '../../services/tarea_service.dart';
import '../../services/storage_service.dart';
import '../../models/usuario.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../mixins/tarea_realtime_mixin.dart';
import '../../services/tarea_realtime_service.dart';
import 'team_management_screen.dart';
import 'admin_task_detail_screen.dart';
import 'importar_usuarios_csv_screen.dart';
import '../../config/theme_config.dart';

class AdminHomeTab extends StatefulWidget {
  final VoidCallback? onNavigateToTasks;

  const AdminHomeTab({super.key, this.onNavigateToTasks});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> with TareaRealtimeMixin {
  final UsuarioService _usuarioService = UsuarioService();
  final EmpresaService _empresaService = EmpresaService();
  final TareaService _tareaService = TareaService();
  final StorageService _storage = StorageService();

  Usuario? _currentUser;
  Map<String, dynamic>? _estadisticas;
  List<Tarea> _tareasRecientes = [];
  List<Tarea> _todasLasTareas = []; // Para el calendario
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    initRealtime(); // Conectar realtime
    _loadData();
  }

  @override
  void dispose() {
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
      final empresaId = await _storage.getEmpresaId();
      if (empresaId != null) {
        final stats = await _empresaService.obtenerEstadisticas(empresaId);
        final todasTareas = await _tareaService.getTareas();
        final tareasOngoing = todasTareas
            .where((t) => t.estado == EstadoTarea.asignada || t.estado == EstadoTarea.aceptada)
            .take(5)
            .toList();

        if (mounted) {
          setState(() {
            _estadisticas = stats;
            _todasLasTareas = todasTareas;
            _tareasRecientes = tareasOngoing;
          });
        }
      }
    } catch (_) {
      // Silencioso
    }
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
          _todasLasTareas = todasTareas;
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;
    final isVerySmallScreen = size.width < 300;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A6CFF).withOpacity(0.4),
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
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerRed),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final firstName = _currentUser?.nombreCompleto.split(' ').first ?? 'Admin';
    final userInitials = _getInitials(_currentUser?.nombreCompleto ?? '');
    final empresaNombre = _estadisticas?['nombreEmpresa'] ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryBlue,
        strokeWidth: 3,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Header moderno
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isVerySmallScreen ? 12 : 20,
                  MediaQuery.of(context).padding.top + (isVerySmallScreen ? 12 : 16),
                  isVerySmallScreen ? 12 : 20,
                  isVerySmallScreen ? 12 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row con avatar y acciones
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A6CFF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            width: isSmallScreen ? 44 : 50,
                            height: isSmallScreen ? 44 : 50,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitials,
                                style: TextStyle(
                                  color: const Color(0xFF0A6CFF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: isSmallScreen ? 16 : 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!isVerySmallScreen) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.08) 
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const ThemeToggleButton(),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                        ],
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
                                  size: isSmallScreen ? 20 : 22,
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
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    // Título
                    Text(
                      isVerySmallScreen ? 'Hola, $firstName' : 'Bienvenido, $firstName',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 22 : (isSmallScreen ? 24 : 28),
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (empresaNombre.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A6CFF).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_rounded,
                                    size: isSmallScreen ? 12 : 14,
                                    color: const Color(0xFF0A6CFF),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      empresaNombre,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0A6CFF),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isVerySmallScreen) ...[
                            const SizedBox(width: 8),
                            RealtimeConnectionIndicator(
                              isConnected: isRealtimeConnected,
                              onReconnect: reconnectRealtime,
                              connectedColor: const Color(0xFF10B981),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Acciones rápidas
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isVerySmallScreen ? 12 : 20,
                0,
                isVerySmallScreen ? 12 : 20,
                isSmallScreen ? 16 : 20,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.add_task_rounded,
                            label: isVerySmallScreen ? 'Nueva' : 'Nueva Tarea',
                            subtitle: isVerySmallScreen ? '' : 'Asignar',
                            gradient: const [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                            onTap: _showCreateTaskModal,
                            isDark: isDark,
                            isCompact: isVerySmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.groups_rounded,
                            label: isVerySmallScreen ? 'Equipo' : 'Ver Equipo',
                            subtitle: isVerySmallScreen ? '' : '${_estadisticas?['totalTrabajadores'] ?? 0} ',
                            gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            onTap: _navigateToTeamManagement,
                            isDark: isDark,
                            isCompact: isVerySmallScreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    _buildQuickAction(
                      icon: Icons.file_upload_outlined,
                      label: 'Importar Usuarios',
                      subtitle: isVerySmallScreen ? 'CSV' : 'Carga desde CSV',
                      gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                      onTap: _navigateToImportCsv,
                      isDark: isDark,
                      isCompact: false,
                    ),
                  ],
                ),
              ),
            ),

            // Métricas
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isVerySmallScreen ? 12 : 20,
                0,
                isVerySmallScreen ? 12 : 20,
                isSmallScreen ? 16 : 20,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Métricas de Tareas',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: isSmallScreen ? 8 : 12,
                      crossAxisSpacing: isSmallScreen ? 8 : 12,
                      childAspectRatio: isVerySmallScreen ? 1.1 : 1.2,
                      children: [
                        _buildMetricCard(
                          title: 'Total',
                          value: '${_estadisticas?['totalTareas'] ?? 0}',
                          icon: Icons.task_alt_rounded,
                          color: const Color(0xFF0A6CFF),
                          isDark: isDark,
                          isCompact: isSmallScreen,
                        ),
                        _buildMetricCard(
                          title: 'Pendientes',
                          value: '${_estadisticas?['tareasPendientes'] ?? 0}',
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                          isCompact: isSmallScreen,
                        ),
                        _buildMetricCard(
                          title: isVerySmallScreen ? 'Progreso' : 'En Progreso',
                          value: '${((_estadisticas?['tareasAsignadas'] ?? 0) + (_estadisticas?['tareasAceptadas'] ?? 0))}',
                          icon: Icons.hourglass_empty_rounded,
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                          isCompact: isSmallScreen,
                        ),
                        _buildMetricCard(
                          title: isVerySmallScreen ? 'Hechas' : 'Completadas',
                          value: '${_estadisticas?['tareasFinalizadas'] ?? 0}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          isCompact: isSmallScreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Calendario
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isVerySmallScreen ? 12 : 20,
                0,
                isVerySmallScreen ? 12 : 20,
                isSmallScreen ? 16 : 20,
              ),
              sliver: SliverToBoxAdapter(
                child: TaskCalendarWidget(
                  tareas: _todasLasTareas,
                  title: isVerySmallScreen ? 'Calendario' : 'Calendario de la Empresa',
                  primaryColor: const Color(0xFF0A6CFF),
                  isLoading: _isLoading,
                  onTaskTap: (tarea) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminTaskDetailScreen(tareaId: tarea.id),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
              ),
            ),

            // Tareas recientes
            if (_tareasRecientes.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isVerySmallScreen ? 12 : 20,
                  0,
                  isVerySmallScreen ? 12 : 20,
                  100,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isVerySmallScreen ? 'Recientes' : 'Tareas Recientes',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onNavigateToTasks,
                            child: Text(
                              isVerySmallScreen ? 'Ver' : 'Ver todas',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withOpacity(0.08) 
                                : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tareasRecientes.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark 
                                ? Colors.white.withOpacity(0.08) 
                                : Colors.black.withOpacity(0.05),
                          ),
                          itemBuilder: (context, index) => _buildTaskItem(
                            _tareasRecientes[index],
                            isDark,
                            isSmallScreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isDark,
    required bool isCompact,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.1),
              gradient[1].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient[0].withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: isCompact ? 18 : 22),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 13 : 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1F2E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isCompact ? 18 : 22),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 22 : 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1A1F2E),
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Tarea tarea, bool isDark, bool isSmall) {
    final statusColor = _getStatusColor(tarea.estado);
    final statusText = _getStatusText(tarea.estado);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 8 : 10,
      ),
      title: Text(
        tarea.titulo,
        style: TextStyle(
          fontSize: isSmall ? 14 : 15,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1A1F2E),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          tarea.asignadoANombre ?? 'No asignado',
          style: TextStyle(
            fontSize: isSmall ? 12 : 13,
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 10,
          vertical: isSmall ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            fontSize: isSmall ? 10 : 11,
            fontWeight: FontWeight.w700,
            color: statusColor,
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminTaskDetailScreen(tareaId: tarea.id),
          ),
        ).then((_) => _loadData());
      },
    );
  }

  Color _getStatusColor(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return const Color(0xFFF59E0B);
      case EstadoTarea.asignada:
        return const Color(0xFF0A6CFF);
      case EstadoTarea.aceptada:
        return const Color(0xFF8B5CF6);
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

  void _navigateToImportCsv() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportarUsuariosCsvScreen()),
    );
    
    // Si se importaron usuarios, refrescar datos
    if (result == true || result == null) {
      _loadData();
    }
  }
}
