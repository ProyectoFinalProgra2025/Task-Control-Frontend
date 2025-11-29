import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/tarea_provider.dart';
import '../../providers/admin_tarea_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';
import '../../services/tarea_service.dart';
import '../../services/usuario_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/task/task_widgets.dart';
import '../common/chat_detail_screen.dart';

class AdminTaskDetailScreen extends StatefulWidget {
  final String tareaId;

  const AdminTaskDetailScreen({super.key, required this.tareaId});

  @override
  State<AdminTaskDetailScreen> createState() => _AdminTaskDetailScreenState();
}

class _AdminTaskDetailScreenState extends State<AdminTaskDetailScreen> {
  final StorageService _storage = StorageService();
  final TareaService _tareaService = TareaService();
  final UsuarioService _usuarioService = UsuarioService();
  
  Tarea? _tarea;
  List<Usuario> _trabajadores = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _hasChanges = false; // Track if any changes were made
  String? _loadingChatUserId;
  StreamSubscription? _tareaEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectRealtime();
      _subscribeToRealtimeEvents();
    });
  }

  @override
  void dispose() {
    _tareaEventSubscription?.cancel();
    super.dispose();
  }
  
  Future<void> _connectRealtime() async {
    try {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      final empresaId = await _storage.getEmpresaId();
      if (empresaId != null) {
        await realtimeProvider.connect(empresaId: empresaId);
      }
    } catch (e) {
      debugPrint('Error connecting to realtime: $e');
    }
  }
  
  void _subscribeToRealtimeEvents() {
    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    
    _tareaEventSubscription = realtimeProvider.tareaEventStream.listen((event) {
      final eventTareaId = event['tareaId']?.toString();
      if (eventTareaId == widget.tareaId) {
        debugPrint('📝 Admin Task Detail: Task event for this task - reloading');
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      
      // Cargar tarea y trabajadores en paralelo
      final results = await Future.wait([
        tareaProvider.obtenerTareaDetalle(widget.tareaId),
        _usuarioService.getUsuarios(),
      ]);

      if (mounted) {
        setState(() {
          _tarea = results[0] as Tarea?;
          _trabajadores = results[1] as List<Usuario>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _asignarTarea(String trabajadorId) async {
    setState(() => _isProcessing = true);

    try {
      await _tareaService.asignarManual(
        widget.tareaId, 
        AsignarManualTareaDTO(usuarioId: trabajadorId),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea asignada exitosamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        _hasChanges = true;
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _asignarAutomatico() async {
    setState(() => _isProcessing = true);

    try {
      await _tareaService.asignarAutomatico(widget.tareaId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea asignada automáticamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        _hasChanges = true;
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelarTarea() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motivoController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed),
            const SizedBox(width: 8),
            Text(
              'Cancelar Tarea',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas cancelar esta tarea?',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Motivo de cancelación',
                hintText: 'Explica por qué se cancela...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dangerRed, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, mantener', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sí, cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final motivo = motivoController.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes proporcionar un motivo de cancelación'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _tareaService.cancelarTarea(widget.tareaId, motivo: motivo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea cancelada'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        
        _hasChanges = true;
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _chatWithUser(String recipientId, String recipientName) async {
    if (recipientId.isEmpty) return;

    setState(() => _loadingChatUserId = recipientId);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chat = await chatProvider.createOneToOneChat(recipientId);

      if (!mounted) return;

      setState(() => _loadingChatUserId = null);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chat.id,
            recipientName: recipientName.isNotEmpty ? recipientName : 'Usuario',
            isGroup: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loadingChatUserId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir chat: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAsignar() {
    // Filtrar trabajadores con capacidades requeridas
    final trabajadoresCompatibles = _trabajadores.where((t) {
      if (_tarea?.capacidadesRequeridas.isEmpty ?? true) return true;

      final capacidadesUsuario = t.capacidades.map((c) => c.nombre.toLowerCase()).toSet();
      final capacidadesRequeridas = _tarea!.capacidadesRequeridas.map((c) => c.toLowerCase()).toSet();

      return capacidadesRequeridas.every(capacidadesUsuario.contains);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asignar Trabajador',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${trabajadoresCompatibles.length} trabajadores compatibles',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              Expanded(
                child: trabajadoresCompatibles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay trabajadores con las\ncapacidades requeridas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trabajadoresCompatibles.length,
                        itemBuilder: (context, index) {
                          final trabajador = trabajadoresCompatibles[index];
                          return _WorkerListItem(
                            trabajador: trabajador,
                            capacidadesRequeridas: _tarea?.capacidadesRequeridas ?? [],
                            onAssign: () {
                              Navigator.pop(context);
                              _asignarTarea(trabajador.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TaskContactButton> _buildContactButtons() {
    final contacts = <TaskContactButton>[];

    if (_tarea == null) return contacts;

    // Trabajador asignado
    if (_tarea!.asignadoAUsuarioId != null && _tarea!.asignadoANombre != null) {
      contacts.add(TaskContactButton(
        name: _tarea!.asignadoANombre!,
        role: 'Trabajador asignado',
        color: Colors.teal,
        isLoading: _loadingChatUserId == _tarea!.asignadoAUsuarioId,
        onTap: () => _chatWithUser(
          _tarea!.asignadoAUsuarioId!,
          _tarea!.asignadoANombre!,
        ),
      ));
    }

    // Si fue delegada - jefe que la delegó
    if (_tarea!.estaDelegada && _tarea!.delegadoPorUsuarioId != null) {
      contacts.add(TaskContactButton(
        name: 'Jefe delegador',
        role: 'Delegó esta tarea',
        color: AppTheme.warningOrange,
        isLoading: _loadingChatUserId == _tarea!.delegadoPorUsuarioId,
        onTap: () => _chatWithUser(
          _tarea!.delegadoPorUsuarioId!,
          'Jefe',
        ),
      ));
    }

    // Si hay un jefe asignado (delegadoA)
    if (_tarea!.delegadoAUsuarioId != null) {
      contacts.add(TaskContactButton(
        name: 'Jefe asignado',
        role: _tarea!.delegacionAceptada == true 
            ? 'Aceptó la delegación'
            : _tarea!.delegacionAceptada == false
                ? 'Rechazó la delegación'
                : 'Pendiente de respuesta',
        color: _tarea!.delegacionAceptada == true 
            ? AppTheme.successGreen
            : _tarea!.delegacionAceptada == false
                ? AppTheme.dangerRed
                : AppTheme.warningOrange,
        isLoading: _loadingChatUserId == _tarea!.delegadoAUsuarioId,
        onTap: () => _chatWithUser(
          _tarea!.delegadoAUsuarioId!,
          'Jefe',
        ),
      ));
    }

    return contacts;
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
          actions: [
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
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
        onRetry: _loadData,
      );
    }

    final contacts = _buildContactButtons();

    return RefreshIndicator(
      onRefresh: _loadData,
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
                  icon: Icons.person_outline_rounded,
                  label: 'Creado por',
                  value: _tarea!.createdByUsuarioNombre,
                  color: AppTheme.primaryBlue,
                ),
                if (_tarea!.asignadoANombre != null)
                  TaskInfoItem(
                    icon: Icons.assignment_ind_rounded,
                    label: 'Asignado a',
                    value: _tarea!.asignadoANombre!,
                    color: Colors.teal,
                  ),
                if (_tarea!.estaDelegada)
                  TaskInfoItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Delegación',
                    value: _tarea!.delegacionAceptada == true
                        ? 'Aceptada'
                        : _tarea!.delegacionAceptada == false
                            ? 'Rechazada'
                            : 'Pendiente',
                    color: _tarea!.delegacionAceptada == true
                        ? AppTheme.successGreen
                        : _tarea!.delegacionAceptada == false
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
            if (contacts.isNotEmpty) ...[
              const SizedBox(height: 16),
              TaskContactsSection(
                title: 'Comunicación',
                contacts: contacts,
              ),
            ],

            // Botones de acción
            const SizedBox(height: 24),
            _buildActionButtons(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = <Widget>[];
    final canManage = _tarea!.estado != EstadoTarea.finalizada && 
                      _tarea!.estado != EstadoTarea.cancelada;

    // Si es pendiente, puede asignar
    if (_tarea!.estado.value == 0) { // pendiente
      actions.add(
        TaskActionButton(
          label: 'Asignación Automática',
          icon: Icons.auto_fix_high_rounded,
          color: AppTheme.successGreen,
          isLoading: _isProcessing,
          onPressed: _asignarAutomatico,
        ),
      );

      actions.add(const SizedBox(height: 12));

      actions.add(
        TaskActionButton(
          label: 'Asignar Manualmente',
          icon: Icons.person_add_rounded,
          color: AppTheme.primaryBlue,
          isLoading: _isProcessing,
          isOutlined: true,
          onPressed: _mostrarDialogoAsignar,
        ),
      );
    }

    // Botón de cancelar (siempre visible si no está finalizada/cancelada)
    if (canManage) {
      actions.add(const SizedBox(height: 20));

      actions.add(
        TaskActionButton(
          label: 'Cancelar Tarea',
          icon: Icons.cancel_outlined,
          color: AppTheme.dangerRed,
          isLoading: _isProcessing,
          isOutlined: true,
          onPressed: _cancelarTarea,
        ),
      );
    }

    // Si no hay acciones disponibles
    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black45,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getNoActionsMessage(),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: actions);
  }

  String _getNoActionsMessage() {
    if (_tarea!.estado == EstadoTarea.finalizada) {
      return 'Esta tarea ha sido completada exitosamente';
    }
    if (_tarea!.estado == EstadoTarea.cancelada) {
      return 'Esta tarea fue cancelada';
    }
    return 'No hay acciones disponibles';
  }
}

// Item de lista de trabajadores
class _WorkerListItem extends StatelessWidget {
  final Usuario trabajador;
  final List<String> capacidadesRequeridas;
  final VoidCallback onAssign;

  const _WorkerListItem({
    required this.trabajador,
    required this.capacidadesRequeridas,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAssign,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      trabajador.nombreCompleto.isNotEmpty
                          ? trabajador.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trabajador.nombreCompleto,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (trabajador.capacidades.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: trabajador.capacidades.take(3).map((cap) {
                            final isRequired = capacidadesRequeridas
                                .map((c) => c.toLowerCase())
                                .contains(cap.nombre.toLowerCase());
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isRequired
                                    ? AppTheme.successGreen.withOpacity(0.2)
                                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(8),
                                border: isRequired
                                    ? Border.all(color: AppTheme.successGreen.withOpacity(0.5))
                                    : null,
                              ),
                              child: Text(
                                cap.nombre,
                                style: TextStyle(
                                  color: isRequired
                                      ? AppTheme.successGreen
                                      : (isDark ? Colors.white70 : Colors.black54),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
