import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/calendar/task_calendar_widget.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../providers/admin_tarea_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../services/usuario_service.dart';
import '../../services/tarea_service.dart';
import '../../config/theme_config.dart';
import 'manager_task_detail_screen.dart';

class ManagerHomeTab extends StatefulWidget {
  const ManagerHomeTab({super.key});

  @override
  State<ManagerHomeTab> createState() => _ManagerHomeTabState();
}

class _ManagerHomeTabState extends State<ManagerHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final adminTareaProvider = Provider.of<AdminTareaProvider>(context, listen: false);
    await Future.wait([
      tareaProvider.cargarMisTareas(),
      usuarioProvider.cargarPerfil(),
      adminTareaProvider.cargarTodasLasTareas(), // Tareas del departamento para el calendario
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer3<TareaProvider, UsuarioProvider, AdminTareaProvider>(
        builder: (context, tareaProvider, usuarioProvider, adminTareaProvider, child) {
          if (tareaProvider.isLoading || usuarioProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: AppTheme.successGreen));
          }

          final tareasPendientes = tareaProvider.tareasPendientes.length;
          final tareaActiva = tareaProvider.tareaActiva ??
              (tareaProvider.tareasPendientes.isNotEmpty ? tareaProvider.tareasPendientes.first : null);
          final nombreUsuario = usuarioProvider.usuario?.nombreCompleto ?? 'Manager';
          final firstName = nombreUsuario.split(' ').first;
          final userInitials = _getInitials(nombreUsuario);
          final tareasDepartamento = adminTareaProvider.todasLasTareas; // Tareas del departamento

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.successGreen,
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
                                  color: AppTheme.successGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.successGreen.withOpacity(0.3), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    userInitials,
                                    style: const TextStyle(
                                      color: AppTheme.successGreen,
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
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.supervisor_account_rounded, size: 14, color: AppTheme.successGreen),
                                SizedBox(width: 6),
                                Text(
                                  'Area Manager',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.warningOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.pending_actions_rounded, color: AppTheme.warningOrange, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tareas Pendientes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$tareasPendientes',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Tarea en Progreso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Task Card or Empty State
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: tareaActiva != null
                          ? _buildTaskCard(tarea: tareaActiva, isDark: isDark)
                          : _buildEmptyState(isDark: isDark),
                    ),

                    // Department Calendar
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TaskCalendarWidget(
                        tareas: tareasDepartamento,
                        title: 'Calendario del Departamento',
                        primaryColor: AppTheme.successGreen,
                        isLoading: adminTareaProvider.isLoading,
                        onTaskTap: (tarea) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManagerTaskDetailScreen(tareaId: tarea.id),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }


  Widget _buildTaskCard({required Tarea tarea, required bool isDark}) {
    String getEstadoText(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.asignada:
          return 'Asignada';
        case EstadoTarea.aceptada:
          return 'En Progreso';
        case EstadoTarea.finalizada:
          return 'Finalizada';
        case EstadoTarea.cancelada:
          return 'Cancelada';
        default:
          return 'Pendiente';
      }
    }

    Color getEstadoColor(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.asignada:
          return AppTheme.primaryBlue;
        case EstadoTarea.aceptada:
          return AppTheme.warningOrange;
        case EstadoTarea.finalizada:
          return AppTheme.successGreen;
        case EstadoTarea.cancelada:
          return AppTheme.dangerRed;
        default:
          return Colors.grey;
      }
    }

    return Container(
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
        children: [
          // Task Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tarea.titulo,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            getEstadoColor(tarea.estado),
                            getEstadoColor(tarea.estado).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: getEstadoColor(tarea.estado).withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        getEstadoText(tarea.estado),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tarea.descripcion,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (tarea.createdByUsuarioNombre.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Creado por: ${tarea.createdByUsuarioNombre}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    if (tarea.dueDate != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${tarea.dueDate!.day}/${tarea.dueDate!.month}/${tarea.dueDate!.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Action Buttons
          if (tarea.estado == EstadoTarea.asignada || tarea.estado == EstadoTarea.aceptada)
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF324467) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Primera fila: Aceptar y Delegar/Rechazar
                  if (tarea.estado == EstadoTarea.asignada)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _aceptarTarea(tarea.id),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text(
                              'Aceptar',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _delegarORechazarTarea(tarea),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text(
                              'Delegar',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Segunda fila: Finalizar (si aceptada)
                  if (tarea.estado == EstadoTarea.aceptada) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _finalizarTarea(tarea),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text(
                              'Finalizar',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _delegarORechazarTarea(tarea),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text(
                              'Reasignar',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas en progreso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Listo para tu próxima asignación',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _aceptarTarea(String tareaId) async {
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final success = await tareaProvider.aceptarTarea(tareaId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tarea aceptada!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tareaProvider.error ?? 'Error al aceptar tarea'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finalizarTarea(Tarea tarea) async {
    final evidenciaController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que deseas marcar "${tarea.titulo}" como finalizada?'),
            const SizedBox(height: 16),
            TextField(
              controller: evidenciaController,
              decoration: const InputDecoration(
                labelText: 'Evidencia (opcional)',
                hintText: 'Describe el trabajo realizado...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final dto = FinalizarTareaDTO(
      evidenciaTexto: evidenciaController.text.isNotEmpty 
          ? evidenciaController.text 
          : null,
    );
    final success = await tareaProvider.finalizarTarea(tarea.id, dto);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tarea finalizada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tareaProvider.error ?? 'Error al finalizar tarea'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _delegarORechazarTarea(Tarea tarea) async {
    // Mostrar diálogo para elegir: Delegar a manager, Asignar a worker, o Rechazar
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Qué deseas hacer?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.supervisor_account, color: Color(0xFF6366F1)),
              title: const Text('Delegar a otro Manager'),
              subtitle: const Text('Pasar la tarea a otro jefe de departamento'),
              onTap: () => Navigator.pop(context, 'delegar_manager'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFF10B981)),
              title: const Text('Asignar a un Worker'),
              subtitle: const Text('Asignar a un trabajador de tu departamento'),
              onTap: () => Navigator.pop(context, 'asignar_worker'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Rechazar tarea'),
              subtitle: const Text('Devolver la tarea al creador'),
              onTap: () => Navigator.pop(context, 'rechazar'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'delegar_manager') {
      await _delegarAOtroManager(tarea);
    } else if (action == 'asignar_worker') {
      await _asignarAWorker(tarea);
    } else if (action == 'rechazar') {
      await _rechazarTarea(tarea);
    }
  }

  Future<void> _asignarAWorker(Tarea tarea) async {
    try {
      // Servicios
      final usuarioService = UsuarioService();
      final tareaService = TareaService();
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final miDepartamento = usuarioProvider.usuario?.departamento;
      
      // Cargar SOLO workers (Usuario) del MISMO departamento
      final usuarios = await usuarioService.getUsuarios();
      final trabajadores = usuarios
          .where((u) => 
              u.rol == 'Usuario' &&  // SOLO workers, NO managers
              u.isActive &&
              u.departamento == miDepartamento) // Solo mismo departamento
          .toList();

      if (trabajadores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay workers disponibles en tu departamento'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar selector de usuario
      final usuarioSeleccionado = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar worker'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: trabajadores.length,
              itemBuilder: (context, index) {
                final usuario = trabajadores[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(usuario.nombreCompleto[0]),
                  ),
                  title: Text(usuario.nombreCompleto),
                  subtitle: Text(usuario.rol),
                  onTap: () => Navigator.pop(context, usuario.id),
                );
              },
            ),
          ),
        ),
      );

      if (usuarioSeleccionado == null || !mounted) return;

      // Reasignar la tarea
      final dto = AsignarManualTareaDTO(usuarioId: usuarioSeleccionado);
      await tareaService.asignarManual(tarea.id, dto);

      // Recargar tareas
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      await tareaProvider.cargarMisTareas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea asignada exitosamente al worker'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar tarea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _delegarAOtroManager(Tarea tarea) async {
    try {
      // Servicios
      final usuarioService = UsuarioService();
      final tareaService = TareaService();
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final miId = usuarioProvider.usuario?.id;
      
      // Cargar TODOS los managers (sin filtro de departamento)
      final usuarios = await usuarioService.getUsuarios();
      final managers = usuarios
          .where((u) => 
              u.rol == 'ManagerDepartamento' &&  // SOLO managers
              u.isActive &&
              u.id != miId)  // Excluir a sí mismo
          .toList();

      if (managers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay otros managers disponibles'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar selector de manager
      final managerSeleccionado = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delegar a otro Manager'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: managers.length,
              itemBuilder: (context, index) {
                final manager = managers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(manager.nombreCompleto[0]),
                  ),
                  title: Text(manager.nombreCompleto),
                  subtitle: Text('Departamento: ${manager.departamento ?? "Sin departamento"}'),
                  onTap: () => Navigator.pop(context, manager.id),
                );
              },
            ),
          ),
        ),
      );

      if (managerSeleccionado == null || !mounted) return;

      // Reasignar la tarea
      final dto = AsignarManualTareaDTO(usuarioId: managerSeleccionado);
      await tareaService.asignarManual(tarea.id, dto);

      // Recargar tareas
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      await tareaProvider.cargarMisTareas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea delegada exitosamente al manager'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al delegar tarea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rechazarTarea(Tarea tarea) async {
    final motivoController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que deseas rechazar "${tarea.titulo}"?'),
            const SizedBox(height: 8),
            const Text(
              'La tarea volverá al creador como "Sin asignar" con tu justificación.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo (obligatorio)',
                hintText: 'Explica por qué rechazas esta tarea...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes proporcionar un motivo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Servicio
      final tareaService = TareaService();
      
      // Cancelar la tarea con el motivo
      await tareaService.cancelarTarea(tarea.id, motivo: motivoController.text);

      // Recargar tareas
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      await tareaProvider.cargarMisTareas();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea rechazada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar tarea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
