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
import '../../widgets/task_progress_indicator.dart';
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

    Color getEstadoColor(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.asignada:
          return Colors.blue;
        case EstadoTarea.aceptada:
          return Colors.orange;
        case EstadoTarea.finalizada:
          return Colors.green;
        case EstadoTarea.cancelada:
          return Colors.red;
        case EstadoTarea.pendiente:
          return Colors.grey;
      }
    }


    Color getPrioridadColor(PrioridadTarea prioridad) {
      switch (prioridad) {
        case PrioridadTarea.high:
          return Colors.red;
        case PrioridadTarea.medium:
          return Colors.orange;
        case PrioridadTarea.low:
          return Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        isDark: isDark,
        padding: const EdgeInsets.all(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerTaskDetailScreen(tareaId: tarea.id),
            ),
          );
        },
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
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        getEstadoColor(tarea.estado),
                        getEstadoColor(tarea.estado).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: getEstadoColor(tarea.estado).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tarea.estado.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tarea.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TaskProgressIndicator(
              estadoActual: tarea.estado,
              primaryColor: AppTheme.primaryBlue,
              showLabels: true,
              height: 70,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getPrioridadColor(tarea.prioridad).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: getPrioridadColor(tarea.prioridad).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 14,
                        color: getPrioridadColor(tarea.prioridad),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tarea.prioridad.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: getPrioridadColor(tarea.prioridad),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (tarea.dueDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${tarea.dueDate!.day}/${tarea.dueDate!.month}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (tarea.capacidadesRequeridas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tarea.capacidadesRequeridas
                      .take(3)
                      .map(
                        (cap) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF135BEC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cap,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF135BEC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            if (tarea.estado == EstadoTarea.asignada) ...[
              const SizedBox(height: 16),
              PremiumButton(
                text: 'Aceptar Tarea',
                icon: Icons.check_circle_outline,
                onPressed: () => _aceptarTarea(tarea.id),
                gradientColors: const [AppTheme.successGreen, AppTheme.successGreen],
                isFullWidth: true,
              ),
            ],
          ],
        ),
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
