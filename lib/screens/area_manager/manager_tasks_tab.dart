import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/admin_tarea_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../widgets/tarea_detail_widget.dart';

class ManagerTasksTab extends StatefulWidget {
  const ManagerTasksTab({super.key});

  @override
  State<ManagerTasksTab> createState() => _ManagerTasksTabState();
}

class _ManagerTasksTabState extends State<ManagerTasksTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EstadoTarea? _filtroEstado;
  PrioridadTarea? _filtroPrioridad;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cargar MIS tareas (asignadas a mí)
      Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
      // Cargar TODAS las tareas del departamento
      Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Tareas'),
        backgroundColor: cardColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Tareas'),
            Tab(text: 'Todas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMisTareasTab(),
          _buildTodasTareasTab(),
        ],
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
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    Color getPriorityColor(PrioridadTarea prioridad) {
      switch (prioridad) {
        case PrioridadTarea.low:
          return const Color(0xFF10b981);
        case PrioridadTarea.medium:
          return const Color(0xFFf59e0b);
        case PrioridadTarea.high:
          return const Color(0xFFef4444);
      }
    }

    Color getStatusColor(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.pendiente:
          return const Color(0xFF9CA3AF);
        case EstadoTarea.asignada:
          return const Color(0xFF3B82F6);
        case EstadoTarea.aceptada:
          return const Color(0xFFF59E0B);
        case EstadoTarea.finalizada:
          return const Color(0xFF10B981);
        case EstadoTarea.cancelada:
          return const Color(0xFFEF4444);
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
            builder: (context) => TareaDetailWidget(tareaId: tarea.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
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
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(tarea.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: getStatusColor(tarea.estado),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    getStatusText(tarea.estado),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(tarea.estado),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tarea.descripcion,
              style: TextStyle(fontSize: 14, color: textSecondary),
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
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const Spacer(),
                // Mostrar rechazo si existe
                if (tarea.delegacionAceptada == false && 
                    tarea.motivoRechazoJefe != null) ...[
                  Icon(Icons.block, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Rechazada',
                      style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
                else if (tarea.asignadoANombre != null) ...[
                  Icon(Icons.person_outline, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tarea.asignadoANombre!,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
                else ...[
                  Icon(Icons.person_off_outlined, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Sin asignar',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
            if (tarea.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${tarea.dueDate!.day}/${tarea.dueDate!.month}/${tarea.dueDate!.year}',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ],
            // Mostrar motivo de rechazo si existe
            if (tarea.delegacionAceptada == false && 
                tarea.motivoRechazoJefe != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Motivo: ${tarea.motivoRechazoJefe}',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
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
