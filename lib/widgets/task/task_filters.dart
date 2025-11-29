import 'package:flutter/material.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../models/enums/departamento.dart';
import '../../config/theme_config.dart';

/// Clase para manejar los filtros de tareas
class TaskFilters {
  final EstadoTarea? estado;
  final PrioridadTarea? prioridad;
  final Departamento? departamento;
  final String? searchQuery;

  const TaskFilters({
    this.estado,
    this.prioridad,
    this.departamento,
    this.searchQuery,
  });

  TaskFilters copyWith({
    EstadoTarea? estado,
    PrioridadTarea? prioridad,
    Departamento? departamento,
    String? searchQuery,
    bool clearEstado = false,
    bool clearPrioridad = false,
    bool clearDepartamento = false,
    bool clearSearch = false,
  }) {
    return TaskFilters(
      estado: clearEstado ? null : (estado ?? this.estado),
      prioridad: clearPrioridad ? null : (prioridad ?? this.prioridad),
      departamento: clearDepartamento ? null : (departamento ?? this.departamento),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  bool get hasFilters =>
      estado != null || prioridad != null || departamento != null;

  TaskFilters clear() => const TaskFilters();

  int get activeFilterCount {
    int count = 0;
    if (estado != null) count++;
    if (prioridad != null) count++;
    if (departamento != null) count++;
    return count;
  }
}

/// Bottom sheet para seleccionar filtros de tareas
class TaskFiltersSheet extends StatefulWidget {
  final TaskFilters initialFilters;
  final Function(TaskFilters) onApply;
  final bool showDepartmentFilter;
  final Color accentColor;

  const TaskFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
    this.showDepartmentFilter = true,
    this.accentColor = AppTheme.primaryBlue,
  });

  /// Método estático para mostrar el sheet
  static Future<void> show({
    required BuildContext context,
    required TaskFilters initialFilters,
    required Function(TaskFilters) onApply,
    bool showDepartmentFilter = true,
    Color accentColor = AppTheme.primaryBlue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFiltersSheet(
        initialFilters: initialFilters,
        onApply: onApply,
        showDepartmentFilter: showDepartmentFilter,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<TaskFiltersSheet> createState() => _TaskFiltersSheetState();
}

class _TaskFiltersSheetState extends State<TaskFiltersSheet> {
  late EstadoTarea? _tempEstado;
  late PrioridadTarea? _tempPrioridad;
  late Departamento? _tempDepartamento;

  @override
  void initState() {
    super.initState();
    _tempEstado = widget.initialFilters.estado;
    _tempPrioridad = widget.initialFilters.prioridad;
    _tempDepartamento = widget.initialFilters.departamento;
  }

  void _clearFilters() {
    setState(() {
      _tempEstado = null;
      _tempPrioridad = null;
      _tempDepartamento = null;
    });
  }

  void _applyFilters() {
    widget.onApply(TaskFilters(
      estado: _tempEstado,
      prioridad: _tempPrioridad,
      departamento: _tempDepartamento,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return DraggableScrollableSheet(
      initialChildSize: widget.showDepartmentFilter ? 0.75 : 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: widget.accentColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text(
                        'Limpiar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
              ),
              // Filters
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Estado
                    _buildSection('Estado', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EstadoTarea.values.map((estado) => _buildFilterChip(
                        estado.label,
                        _tempEstado == estado,
                        () => setState(() => _tempEstado = _tempEstado == estado ? null : estado),
                        isDark,
                        _getEstadoColor(estado),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Prioridad
                    _buildSection('Prioridad', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PrioridadTarea.values.map((prioridad) => _buildFilterChip(
                        prioridad.label,
                        _tempPrioridad == prioridad,
                        () => setState(() => _tempPrioridad = _tempPrioridad == prioridad ? null : prioridad),
                        isDark,
                        _getPrioridadColor(prioridad),
                      )).toList(),
                    ),
                    // Departamento (opcional)
                    if (widget.showDepartmentFilter) ...[
                      const SizedBox(height: 24),
                      _buildSection('Departamento', isDark),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Departamento.principales.map((dept) => _buildFilterChip(
                          dept.label,
                          _tempDepartamento == dept,
                          () => setState(() => _tempDepartamento = _tempDepartamento == dept ? null : dept),
                          isDark,
                          _getDepartamentoColor(dept),
                        )).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Apply button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildSection(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
    Color? color,
  ) {
    final selectedColor = color ?? widget.accentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? selectedColor 
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? selectedColor 
                : (isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: selectedColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected 
                ? Colors.white 
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(EstadoTarea estado) {
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

  Color _getPrioridadColor(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.low:
        return AppTheme.successGreen;
      case PrioridadTarea.medium:
        return AppTheme.warningOrange;
      case PrioridadTarea.high:
        return AppTheme.dangerRed;
    }
  }

  Color _getDepartamentoColor(Departamento dept) {
    switch (dept) {
      case Departamento.finanzas:
        return const Color(0xFF10B981);
      case Departamento.mantenimiento:
        return const Color(0xFFF59E0B);
      case Departamento.produccion:
        return const Color(0xFF3B82F6);
      case Departamento.marketing:
        return const Color(0xFFEC4899);
      case Departamento.logistica:
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }
}

/// Chips para mostrar filtros activos
class TaskActiveFiltersRow extends StatelessWidget {
  final TaskFilters filters;
  final Function(TaskFilters) onFilterRemoved;
  final Color accentColor;

  const TaskActiveFiltersRow({
    super.key,
    required this.filters,
    required this.onFilterRemoved,
    this.accentColor = AppTheme.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    if (!filters.hasFilters) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (filters.estado != null)
            _buildChip(
              filters.estado!.label,
              () => onFilterRemoved(filters.copyWith(clearEstado: true)),
            ),
          if (filters.prioridad != null)
            _buildChip(
              filters.prioridad!.label,
              () => onFilterRemoved(filters.copyWith(clearPrioridad: true)),
            ),
          if (filters.departamento != null)
            _buildChip(
              filters.departamento!.label,
              () => onFilterRemoved(filters.copyWith(clearDepartamento: true)),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        deleteIcon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
        onDeleted: onRemove,
        backgroundColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
