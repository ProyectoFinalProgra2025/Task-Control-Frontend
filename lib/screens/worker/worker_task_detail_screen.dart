import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';
import '../../widgets/task/task_widgets.dart';

class WorkerTaskDetailScreen extends StatefulWidget {
  final String tareaId;

  const WorkerTaskDetailScreen({super.key, required this.tareaId});

  @override
  State<WorkerTaskDetailScreen> createState() => _WorkerTaskDetailScreenState();
}

class _WorkerTaskDetailScreenState extends State<WorkerTaskDetailScreen> {
  Tarea? _tarea;
  bool _isLoading = true;
  bool _hasChanges = false; // Track if any changes were made

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _isLoading = true);
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final tarea = await tareaProvider.obtenerTareaDetalle(widget.tareaId);
    
    if (mounted) {
      setState(() {
        _tarea = tarea;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Parent will receive true if changes were made
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          title: const Text(
            'Detalle de Tarea',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const TaskLoadingWidget(message: 'Cargando tarea...');
    }

    if (_tarea == null) {
      return TaskErrorWidget(
        message: 'No se pudo cargar la tarea',
        onRetry: _cargarDetalle,
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDetalle,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            TaskDetailHeader(
              title: _tarea!.titulo,
              description: _tarea!.descripcion,
              statusBadge: TaskStatusBadge(
                estado: _tarea!.estado,
                showIcon: true,
              ),
            ),
            const SizedBox(height: 16),

            // Información de la Tarea
            TaskInfoSection(
              title: 'Detalles',
              items: [
                TaskInfoItem(
                  icon: Icons.flag_outlined,
                  label: 'Prioridad',
                  value: TaskHelpers.getPrioridadLabel(_tarea!.prioridad),
                  color: TaskHelpers.getPrioridadColor(_tarea!.prioridad),
                ),
                if (_tarea!.departamento != null)
                  TaskInfoItem(
                    icon: TaskHelpers.getDepartamentoIcon(_tarea!.departamento),
                    label: 'Departamento',
                    value: _tarea!.departamento!.label,
                    color: TaskHelpers.getDepartamentoColor(_tarea!.departamento),
                  ),
                if (_tarea!.dueDate != null)
                  TaskInfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha Límite',
                    value: TaskHelpers.getRelativeDueDate(_tarea!.dueDate),
                    color: TaskHelpers.isOverdue(_tarea!.dueDate)
                        ? AppTheme.dangerRed
                        : AppTheme.warningOrange,
                  ),
                TaskInfoItem(
                  icon: Icons.history_rounded,
                  label: 'Creada el',
                  value: TaskHelpers.formatDueDate(_tarea!.createdAt),
                ),
              ],
            ),

            // Capacidades Requeridas
            if (_tarea!.capacidadesRequeridas.isNotEmpty) ...[
              const SizedBox(height: 16),
              TaskSkillsSection(
                skills: _tarea!.capacidadesRequeridas,
                color: AppTheme.primaryBlue,
              ),
            ],

            // Banner de rechazo si aplica
            if (_tarea!.delegacionAceptada == false && 
                _tarea!.motivoRechazoJefe != null) ...[
              const SizedBox(height: 16),
              TaskRejectionBanner(
                reason: _tarea!.motivoRechazoJefe!,
              ),
            ],

            // Sección de Contactos
            const SizedBox(height: 16),
            TaskContactsSection(
              title: 'Comunicación',
              contacts: _buildContactButtons(),
            ),

            // Botones de acción según estado
            const SizedBox(height: 24),
            _buildActionButtons(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<TaskContactButton> _buildContactButtons() {
    final contacts = <TaskContactButton>[];

    // Creador de la tarea
    if (_tarea!.createdByUsuarioId.isNotEmpty) {
      contacts.add(TaskContactButton(
        name: _tarea!.createdByUsuarioNombre,
        role: 'Creó esta tarea',
        color: AppTheme.primaryBlue,
        icon: Icons.chat_bubble_outline_rounded,
        isLoading: false, // TODO: Implementar estado de loading con nuevo chat
        onTap: () => _chatWithUser(
          _tarea!.createdByUsuarioId,
          _tarea!.createdByUsuarioNombre,
        ),
      ));
    }

    // Si fue delegada - quien la delegó
    if (_tarea!.estaDelegada && _tarea!.delegadoPorUsuarioId != null) {
      // Solo mostrar si es diferente al creador
      if (_tarea!.delegadoPorUsuarioId != _tarea!.createdByUsuarioId) {
        contacts.add(TaskContactButton(
          name: 'Manager que delegó', // El backend no retorna el nombre
          role: 'Delegó esta tarea',
          color: AppTheme.warningOrange,
          icon: Icons.swap_horiz_rounded,
          isLoading: false,
          onTap: () => _chatWithUser(
            _tarea!.delegadoPorUsuarioId!,
            'Manager',
          ),
        ));
      }
    }

    // Si hay un manager asignado (delegadoA)
    if (_tarea!.delegadoAUsuarioId != null && 
        _tarea!.delegacionAceptada == true) {
      contacts.add(TaskContactButton(
        name: 'Manager asignado',
        role: 'Aceptó la delegación',
        color: AppTheme.successGreen,
        icon: Icons.person_outline_rounded,
        isLoading: false,
        onTap: () => _chatWithUser(
          _tarea!.delegadoAUsuarioId!,
          'Manager',
        ),
      ));
    }

    return contacts;
  }

  Widget _buildActionButtons() {
    final actions = <Widget>[];

    if (_tarea!.estado == EstadoTarea.asignada) {
      actions.add(TaskActionButton(
        label: 'Aceptar Tarea',
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.successGreen,
        onPressed: _aceptarTarea,
      ));
    }

    if (_tarea!.estado == EstadoTarea.aceptada) {
      actions.add(TaskActionButton(
        label: 'Finalizar Tarea',
        icon: Icons.task_alt_rounded,
        color: AppTheme.primaryBlue,
        onPressed: _finalizarTarea,
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: actions.map((action) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: action,
      )).toList(),
    );
  }

  Future<void> _aceptarTarea() async {
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final success = await tareaProvider.aceptarTarea(widget.tareaId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success 
            ? '¡Tarea aceptada exitosamente!' 
            : tareaProvider.error ?? 'Error al aceptar tarea'),
        backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      _hasChanges = true;
      await _cargarDetalle();
    }
  }

  Future<void> _finalizarTarea() async {
    final evidenciaController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task_alt, color: AppTheme.successGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Finalizar Tarea', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas finalizar esta tarea?',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: evidenciaController,
              decoration: InputDecoration(
                labelText: 'Evidencia del trabajo',
                hintText: 'Describe lo que realizaste...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.successGreen, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      final dto = FinalizarTareaDTO(
        evidenciaTexto: evidenciaController.text.isNotEmpty
            ? evidenciaController.text
            : null,
      );

      final success = await tareaProvider.finalizarTarea(widget.tareaId, dto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
              ? '¡Tarea finalizada exitosamente!' 
              : tareaProvider.error ?? 'Error al finalizar tarea'),
          backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        _hasChanges = true;
        await _cargarDetalle();
      }
    }
  }

  Future<void> _chatWithUser(String userId, String userName) async {
    if (userId.isEmpty) return;

    // TODO: Implementar chat con nuevo backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('El sistema de chat estará disponible pronto'),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
