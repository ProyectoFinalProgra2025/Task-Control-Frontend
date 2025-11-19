import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import 'worker_task_detail_screen.dart';

class WorkerTasksListScreen extends StatefulWidget {
  const WorkerTasksListScreen({super.key});

  @override
  State<WorkerTasksListScreen> createState() => _WorkerTasksListScreenState();
}

class _WorkerTasksListScreenState extends State<WorkerTasksListScreen> {
  EstadoTarea? _filtroEstado;
  PrioridadTarea? _filtroPrioridad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
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
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        backgroundColor: isDark ? const Color(0xFF192233) : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<TareaProvider>(
        builder: (context, tareaProvider, child) {
          if (tareaProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tareaProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    tareaProvider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tareaProvider.cargarMisTareas(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final tareas = tareaProvider.misTareas;

          if (tareas.isEmpty) {
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
                    'No tienes tareas asignadas',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => tareaProvider.cargarMisTareas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

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

    Color getPrioridadColor(PrioridadTarea prioridad) {
      switch (prioridad) {
        case PrioridadTarea.high:
          return Colors.red;
        case PrioridadTarea.medium:
          return Colors.orange;
        case PrioridadTarea.low:
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF324467) : const Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerTaskDetailScreen(tareaId: tarea.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tarea.titulo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: getEstadoColor(tarea.estado).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getEstadoText(tarea.estado),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: getEstadoColor(tarea.estado),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tarea.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: getPrioridadColor(tarea.prioridad),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tarea.prioridad.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: getPrioridadColor(tarea.prioridad),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (tarea.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tarea.dueDate!.day}/${tarea.dueDate!.month}/${tarea.dueDate!.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _aceptarTarea(tarea.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Aceptar Tarea'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _aceptarTarea(int tareaId) async {
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
