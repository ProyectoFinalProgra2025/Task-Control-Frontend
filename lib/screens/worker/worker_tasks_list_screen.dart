import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/tarea_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../config/theme_config.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/task/task_widgets.dart';
import '../../services/storage_service.dart';
import 'worker_task_detail_screen.dart';

class WorkerTasksListScreen extends StatefulWidget {
  const WorkerTasksListScreen({super.key});

  @override
  State<WorkerTasksListScreen> createState() => _WorkerTasksListScreenState();
}

class _WorkerTasksListScreenState extends State<WorkerTasksListScreen> {
  final StorageService _storage = StorageService();
  EstadoTarea? _filtroEstado;
  PrioridadTarea? _filtroPrioridad;
  StreamSubscription? _tareaEventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
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
      debugPrint('📋 Worker Tasks List: Tarea event received: ${event['action']}');
      Provider.of<TareaProvider>(context, listen: false).cargarMisTareas(
        estado: _filtroEstado,
        prioridad: _filtroPrioridad,
      );
      
      if (mounted) {
        final action = event['action'] ?? '';
        String message = '';
        if (action == 'tarea:assigned') {
          message = 'Nueva tarea asignada';
        } else if (action == 'tarea:accepted') {
          message = 'Tarea aceptada';
        } else if (action == 'tarea:completed') {
          message = 'Tarea completada';
        }
        
        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _aplicarFiltros() async {
    await Provider.of<TareaProvider>(context, listen: false).cargarMisTareas(
      estado: _filtroEstado,
      prioridad: _filtroPrioridad,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mis Tareas',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list_rounded, color: AppTheme.primaryBlue),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
      body: Consumer<TareaProvider>(
        builder: (context, tareaProvider, child) {
          if (tareaProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (tareaProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: PremiumEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar tareas',
                  subtitle: tareaProvider.error!,
                  isDark: isDark,
                  action: PremiumButton(
                    text: 'Reintentar',
                    onPressed: () => tareaProvider.cargarMisTareas(),
                    icon: Icons.refresh_rounded,
                  ),
                ),
              ),
            );
          }

          final tareas = tareaProvider.misTareas;

          if (tareas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: PremiumEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'Sin Tareas',
                  subtitle: 'No tienes tareas asignadas en este momento',
                  isDark: isDark,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => tareaProvider.cargarMisTareas(),
            color: AppTheme.primaryBlue,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tareas.length,
              itemBuilder: (context, index) {
                final tarea = tareas[index];
                return _buildTareaCard(tarea, isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTareaCard(Tarea tarea, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TaskCard(
        tarea: tarea,
        style: TaskCardStyle.worker,
        showSkills: true,
        showAssignee: false, // Worker no necesita ver su propio nombre
        showDueDate: true,
        showProgressIndicator: true,
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerTaskDetailScreen(tareaId: tarea.id),
            ),
          );
          if (result == true) {
            Provider.of<TareaProvider>(context, listen: false).cargarMisTareas(
              estado: _filtroEstado,
              prioridad: _filtroPrioridad,
            );
          }
        },
        action: tarea.estado == EstadoTarea.asignada
            ? PremiumButton(
                text: 'Aceptar Tarea',
                icon: Icons.check_circle_outline,
                onPressed: () => _aceptarTarea(tarea.id),
                gradientColors: const [AppTheme.successGreen, AppTheme.successGreen],
                isFullWidth: true,
              )
            : null,
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
          content: Text('¡Tarea aceptada exitosamente!'),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Tareas'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<EstadoTarea>(
                value: _filtroEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...EstadoTarea.values.map(
                    (estado) => DropdownMenuItem(
                      value: estado,
                      child: Text(estado.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _filtroEstado = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrioridadTarea>(
                value: _filtroPrioridad,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...PrioridadTarea.values.map(
                    (prioridad) => DropdownMenuItem(
                      value: prioridad,
                      child: Text(prioridad.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _filtroPrioridad = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroEstado = null;
                _filtroPrioridad = null;
              });
              Navigator.pop(context);
              _aplicarFiltros();
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _aplicarFiltros();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
