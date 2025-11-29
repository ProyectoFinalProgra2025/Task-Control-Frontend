import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';

/// Widget de encabezado unificado para listas de tareas
/// Muestra título, conteo de tareas, y estadísticas opcionales
class TaskListHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int taskCount;
  final List<Tarea>? tareas;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showStats;

  const TaskListHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.taskCount = 0,
    this.tareas,
    this.leading,
    this.actions,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calcular estadísticas
    int pendientes = 0;
    int enProgreso = 0;
    int completadas = 0;
    
    if (tareas != null) {
      for (final tarea in tareas!) {
        switch (tarea.estado) {
          case EstadoTarea.pendiente:
            pendientes++;
            break;
          case EstadoTarea.asignada:
          case EstadoTarea.aceptada:
            enProgreso++;
            break;
          case EstadoTarea.finalizada:
            completadas++;
            break;
          case EstadoTarea.cancelada:
            break;
        }
      }
    }

    return Container(
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
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? '$taskCount tareas encontradas',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: action,
                  )).toList(),
                ),
            ],
          ),
          
          // Estadísticas
          if (showStats && tareas != null && tareas!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatBadge('Pendientes', pendientes, AppTheme.warningOrange, isDark),
                const SizedBox(width: 10),
                _buildStatBadge('En Progreso', enProgreso, AppTheme.primaryBlue, isDark),
                const SizedBox(width: 10),
                _buildStatBadge('Completadas', completadas, AppTheme.successGreen, isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de botón de acción circular para usar en headers
class TaskHeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final String? tooltip;

  const TaskHeaderActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue
                : (isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
          ),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: isActive
                ? Colors.white
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Tab bar moderno para filtrar tareas por estado
class TaskTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final VoidCallback? onTap;
  final Color? activeColor;

  const TaskTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? AppTheme.primaryBlue;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap != null ? (_) => onTap!() : null,
        indicator: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}

/// Row horizontal con chips de filtros activos
class TaskActiveFiltersChips extends StatelessWidget {
  final List<TaskFilterChip> filters;

  const TaskActiveFiltersChips({
    super.key,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters,
      ),
    );
  }
}

/// Chip individual de filtro
class TaskFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const TaskFilterChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: AppTheme.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Diálogo de búsqueda de tareas
class TaskSearchDialog extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const TaskSearchDialog({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Buscar Tarea',
        style: TextStyle(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        autofocus: true,
        controller: TextEditingController(text: initialValue),
        decoration: InputDecoration(
          hintText: 'Título de la tarea...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
      actions: [
        TextButton(
          onPressed: () {
            onClear?.call();
            Navigator.of(context).pop();
          },
          child: const Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
