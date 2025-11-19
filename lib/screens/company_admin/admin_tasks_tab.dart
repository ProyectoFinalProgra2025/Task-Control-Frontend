import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../models/enums/departamento.dart';
import '../../services/tarea_service.dart';
import '../../widgets/tarea_detail_widget.dart';

class AdminTasksTab extends StatefulWidget {
  const AdminTasksTab({super.key});

  @override
  State<AdminTasksTab> createState() => _AdminTasksTabState();
}

class _AdminTasksTabState extends State<AdminTasksTab> {
  final TareaService _tareaService = TareaService();
  List<Tarea> _tareas = [];
  bool _isLoading = true;
  String? _error;

  // Filtros
  EstadoTarea? _selectedEstado;
  PrioridadTarea? _selectedPrioridad;
  Departamento? _selectedDepartamento;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTareas();
  }

  Future<void> _loadTareas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tareas = await _tareaService.getTareas(
        estado: _selectedEstado,
        prioridad: _selectedPrioridad,
        departamento: _selectedDepartamento,
      );
      
      if (mounted) {
        setState(() {
          _tareas = tareas;
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

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FiltersSheet(
        selectedEstado: _selectedEstado,
        selectedPrioridad: _selectedPrioridad,
        selectedDepartamento: _selectedDepartamento,
        onApply: (estado, prioridad, departamento) {
          setState(() {
            _selectedEstado = estado;
            _selectedPrioridad = prioridad;
            _selectedDepartamento = departamento;
          });
          _loadTareas();
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Tarea'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ingrese título de la tarea...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              Navigator.of(context).pop();
            },
            child: const Text('Limpiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  List<Tarea> get _filteredTareas {
    if (_searchQuery.isEmpty) return _tareas;
    
    final query = _searchQuery.toLowerCase();
    return _tareas.where((tarea) {
      return tarea.titulo.toLowerCase().contains(query) ||
          tarea.descripcion.toLowerCase().contains(query);
    }).toList();
  }

  Color _getEstadoColor(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return const Color(0xFFF59E0B);
      case EstadoTarea.asignada:
        return const Color(0xFF3B82F6);
      case EstadoTarea.aceptada:
        return const Color(0xFF8B5CF6);
      case EstadoTarea.finalizada:
        return const Color(0xFF10B981);
      case EstadoTarea.cancelada:
        return const Color(0xFFEF4444);
    }
  }

  Color _getPrioridadColor(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.low:
        return const Color(0xFF10B981);
      case PrioridadTarea.medium:
        return const Color(0xFFF59E0B);
      case PrioridadTarea.high:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.menu, color: textPrimary, size: 28),
                  const Spacer(),
                  Text(
                    'Tareas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.search, color: textPrimary, size: 28),
                    onPressed: _showSearchDialog,
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: textPrimary, size: 28),
                    onPressed: _showFiltersDialog,
                  ),
                ],
              ),
            ),

            // Filter Chips - Mostrar filtros activos
            if (_selectedEstado != null ||
                _selectedPrioridad != null ||
                _selectedDepartamento != null)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (_selectedEstado != null)
                            _buildActiveFilterChip(
                              '${_selectedEstado!.label}',
                              () {
                                setState(() => _selectedEstado = null);
                                _loadTareas();
                              },
                              textPrimary,
                            ),
                          if (_selectedPrioridad != null)
                            _buildActiveFilterChip(
                              '${_selectedPrioridad!.label}',
                              () {
                                setState(() => _selectedPrioridad = null);
                                _loadTareas();
                              },
                              textPrimary,
                            ),
                          if (_selectedDepartamento != null)
                            _buildActiveFilterChip(
                              '${_selectedDepartamento!.label}',
                              () {
                                setState(() => _selectedDepartamento = null);
                                _loadTareas();
                              },
                              textPrimary,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Task List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar tareas',
                                style:
                                    TextStyle(fontSize: 18, color: textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(
                                    fontSize: 14, color: textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTareas,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : _filteredTareas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_outlined,
                                      size: 64, color: textSecondary),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay tareas',
                                    style: TextStyle(
                                        fontSize: 18, color: textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Crea una nueva tarea usando el botón +',
                                    style: TextStyle(
                                        fontSize: 14, color: textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTareas,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredTareas.length,
                                itemBuilder: (context, index) {
                                  final tarea = _filteredTareas[index];
                                  return _buildTaskCard(
                                    tarea: tarea,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(
      String label, VoidCallback onRemove, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
        onDeleted: onRemove,
        backgroundColor: const Color(0xFF135bec),
      ),
    );
  }

  Widget _buildTaskCard({
    required Tarea tarea,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TareaDetailWidget(tareaId: tarea.id),
          ),
        );
        
        // Si se modificó algo, recargar la lista
        if (result == true) {
          _loadTareas();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF192233) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
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
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPrioridadColor(tarea.prioridad).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tarea.prioridad.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getPrioridadColor(tarea.prioridad),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tarea.descripcion,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (tarea.asignadoANombre != null) ...[
                  Icon(Icons.person_outline, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      tarea.asignadoANombre!,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Icon(Icons.person_off_outlined, size: 16, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Sin asignar',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Text(
                  tarea.dueDate != null
                      ? '${tarea.dueDate!.day}/${tarea.dueDate!.month}/${tarea.dueDate!.year}'
                      : 'Sin fecha',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(tarea.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tarea.estado.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getEstadoColor(tarea.estado),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Sheet para filtros
class _FiltersSheet extends StatefulWidget {
  final EstadoTarea? selectedEstado;
  final PrioridadTarea? selectedPrioridad;
  final Departamento? selectedDepartamento;
  final Function(EstadoTarea?, PrioridadTarea?, Departamento?) onApply;

  const _FiltersSheet({
    this.selectedEstado,
    this.selectedPrioridad,
    this.selectedDepartamento,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late EstadoTarea? _tempEstado;
  late PrioridadTarea? _tempPrioridad;
  late Departamento? _tempDepartamento;

  @override
  void initState() {
    super.initState();
    _tempEstado = widget.selectedEstado;
    _tempPrioridad = widget.selectedPrioridad;
    _tempDepartamento = widget.selectedDepartamento;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF101622) : const Color(0xFFF4F6F8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary =
        isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor =
        isDark ? const Color(0xFF324467) : const Color(0xFFE0E0E0);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Filtros',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempEstado = null;
                          _tempPrioridad = null;
                          _tempDepartamento = null;
                        });
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
              ),

              // Filters
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Estado
                    Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...EstadoTarea.values.map((estado) {
                      return RadioListTile<EstadoTarea?>(
                        title: Text(estado.label,
                            style: TextStyle(color: textPrimary)),
                        value: estado,
                        groupValue: _tempEstado,
                        onChanged: (value) {
                          setState(() => _tempEstado = value);
                        },
                        activeColor: const Color(0xFF005A9C),
                        tileColor: cardColor,
                      );
                    }),

                    const SizedBox(height: 16),

                    // Prioridad
                    Text(
                      'Prioridad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...PrioridadTarea.values.map((prioridad) {
                      return RadioListTile<PrioridadTarea?>(
                        title: Text(prioridad.label,
                            style: TextStyle(color: textPrimary)),
                        value: prioridad,
                        groupValue: _tempPrioridad,
                        onChanged: (value) {
                          setState(() => _tempPrioridad = value);
                        },
                        activeColor: const Color(0xFF005A9C),
                        tileColor: cardColor,
                      );
                    }),

                    const SizedBox(height: 16),

                    // Departamento
                    Text(
                      'Departamento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...Departamento.principales.map((dept) {
                      return RadioListTile<Departamento?>(
                        title: Text(dept.label,
                            style: TextStyle(color: textPrimary)),
                        value: dept,
                        groupValue: _tempDepartamento,
                        onChanged: (value) {
                          setState(() => _tempDepartamento = value);
                        },
                        activeColor: const Color(0xFF005A9C),
                        tileColor: cardColor,
                      );
                    }),
                  ],
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                        _tempEstado, _tempPrioridad, _tempDepartamento);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005A9C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
