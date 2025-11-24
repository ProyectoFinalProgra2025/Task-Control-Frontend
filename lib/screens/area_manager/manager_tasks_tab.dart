import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/tarea_provider.dart';
import '../../providers/admin_tarea_provider.dart';
import '../../providers/realtime_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../config/theme_config.dart';
import '../../services/storage_service.dart';
import 'manager_task_detail_screen.dart';

class ManagerTasksTab extends StatefulWidget {
  const ManagerTasksTab({super.key});

  @override
  State<ManagerTasksTab> createState() => _ManagerTasksTabState();
}

class _ManagerTasksTabState extends State<ManagerTasksTab> with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late TabController _tabController;
  EstadoTarea? _filtroEstado;
  PrioridadTarea? _filtroPrioridad;
  StreamSubscription? _tareaEventSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar MIS tareas (asignadas a mí)
      Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
      // Cargar TODAS las tareas del departamento
      Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
      _connectRealtime();
      _subscribeToRealtimeEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      debugPrint('📋 Manager Tasks: Tarea event received: ${event['action']}');
      Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
      Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
      
      if (mounted) {
        final action = event['action'] ?? '';
        String message = '';
        if (action == 'tarea:created') {
          message = 'Nueva tarea creada';
        } else if (action == 'tarea:assigned') {
          message = 'Tarea asignada';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestión de Tareas',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Supervisa y administra el trabajo',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.filter_list_rounded, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                          onPressed: _showFilterDialog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Premium Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.grey[100])?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.successGreen, Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Mis Tareas'),
                        Tab(text: 'Todas'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMisTareasTab(),
                  _buildTodasTareasTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 1: Mis Tareas (asignadas a mí como manager)
  Widget _buildMisTareasTab() {
    return Consumer<TareaProvider>(
      builder: (context, tareaProvider, child) {
        if (tareaProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tareaProvider.error != null) {
          return _buildErrorWidget(
            tareaProvider.error!,
            () => tareaProvider.cargarMisTareas(),
          );
        }

        final tareas = tareaProvider.misTareas;

        if (tareas.isEmpty) {
          return _buildEmptyWidget('No tienes tareas asignadas');
        }

        return RefreshIndicator(
          onRefresh: () => tareaProvider.cargarMisTareas(
            estado: _filtroEstado,
            prioridad: _filtroPrioridad,
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tareas.length,
            itemBuilder: (context, index) => _buildTaskCard(tareas[index]),
          ),
        );
      },
    );
  }

  // Tab 2: Todas las tareas del departamento
  Widget _buildTodasTareasTab() {
    return Consumer<AdminTareaProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminProvider.error != null) {
          return _buildErrorWidget(
            adminProvider.error!,
            () => adminProvider.cargarTodasLasTareas(),
          );
        }

        final tareas = adminProvider.todasLasTareas;

        if (tareas.isEmpty) {
          return _buildEmptyWidget('No hay tareas en el departamento');
        }

        return RefreshIndicator(
          onRefresh: () => adminProvider.cargarTodasLasTareas(
            estado: _filtroEstado,
            prioridad: _filtroPrioridad,
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tareas.length,
            itemBuilder: (context, index) => _buildTaskCard(tareas[index]),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Tarea tarea) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getPriorityColor(PrioridadTarea prioridad) {
      switch (prioridad) {
        case PrioridadTarea.low:
          return AppTheme.successGreen;
        case PrioridadTarea.medium:
          return AppTheme.warningOrange;
        case PrioridadTarea.high:
          return AppTheme.dangerRed;
      }
    }

    Color getStatusColor(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.pendiente:
          return Colors.grey;
        case EstadoTarea.asignada:
          return AppTheme.primaryBlue;
        case EstadoTarea.aceptada:
          return AppTheme.warningOrange;
        case EstadoTarea.finalizada:
          return AppTheme.successGreen;
        case EstadoTarea.cancelada:
          return AppTheme.dangerRed;
      }
    }

    String getStatusText(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.pendiente:
          return 'Pendiente';
        case EstadoTarea.asignada:
          return 'Asignada';
        case EstadoTarea.aceptada:
          return 'En Progreso';
        case EstadoTarea.finalizada:
          return 'Finalizada';
        case EstadoTarea.cancelada:
          return 'Cancelada';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManagerTaskDetailScreen(tareaId: tarea.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
          ),
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
              children: [
                Expanded(
                  child: Text(
                    tarea.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        getStatusColor(tarea.estado),
                        getStatusColor(tarea.estado).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    getStatusText(tarea.estado),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getPriorityColor(tarea.prioridad),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tarea.prioridad == PrioridadTarea.low
                      ? 'Baja'
                      : tarea.prioridad == PrioridadTarea.medium
                          ? 'Media'
                          : 'Alta',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Mostrar rechazo si existe
                if (tarea.delegacionAceptada == false && 
                    tarea.motivoRechazoJefe != null) ...[
                  Icon(Icons.block, size: 14, color: AppTheme.dangerRed),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Rechazada',
                      style: TextStyle(fontSize: 12, color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
                else if (tarea.asignadoANombre != null) ...[
                  Icon(Icons.person_outline, size: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tarea.asignadoANombre!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
                else ...[
                  Icon(Icons.person_off_outlined, size: 14, color: AppTheme.warningOrange),
                  const SizedBox(width: 4),
                  Text(
                    'Sin asignar',
                    style: TextStyle(fontSize: 12, color: AppTheme.warningOrange, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            if (tarea.dueDate != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${tarea.dueDate!.day}/${tarea.dueDate!.month}/${tarea.dueDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            // Mostrar motivo de rechazo si existe
            if (tarea.delegacionAceptada == false && 
                tarea.motivoRechazoJefe != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppTheme.dangerRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Motivo: ${tarea.motivoRechazoJefe}',
                        style: TextStyle(fontSize: 11, color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt,
                size: 40,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las tareas aparecerán aquí cuando estén disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: AppTheme.dangerRed),
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Tareas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<EstadoTarea?>(
              value: _filtroEstado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...EstadoTarea.values.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    )),
              ],
              onChanged: (value) => setState(() => _filtroEstado = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PrioridadTarea?>(
              value: _filtroPrioridad,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...PrioridadTarea.values.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    )),
              ],
              onChanged: (value) => setState(() => _filtroPrioridad = value),
            ),
          ],
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

  Future<void> _aplicarFiltros() async {
    if (_tabController.index == 0) {
      // Mis Tareas
      await Provider.of<TareaProvider>(context, listen: false).cargarMisTareas(
        estado: _filtroEstado,
        prioridad: _filtroPrioridad,
      );
    } else {
      // Todas las tareas
      await Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas(
        estado: _filtroEstado,
        prioridad: _filtroPrioridad,
      );
    }
  }
}
