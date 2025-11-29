import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

/// Widget para mostrar cuando no hay tareas
class TaskEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  final Color? accentColor;

  const TaskEmptyState({
    super.key,
    this.title = 'No hay tareas',
    this.subtitle = 'Las tareas aparecerán aquí cuando estén disponibles',
    this.icon = Icons.assignment_outlined,
    this.action,
    this.accentColor,
  });

  /// Factory para worker sin tareas
  factory TaskEmptyState.worker() {
    return const TaskEmptyState(
      title: 'Sin tareas asignadas',
      subtitle: 'No tienes tareas asignadas en este momento. ¡Buen trabajo!',
      icon: Icons.task_alt,
      accentColor: AppTheme.primaryBlue,
    );
  }

  /// Factory para manager/admin sin tareas
  factory TaskEmptyState.management() {
    return const TaskEmptyState(
      title: 'Sin tareas',
      subtitle: 'Crea una nueva tarea usando el botón +',
      icon: Icons.add_task,
      accentColor: AppTheme.successGreen,
    );
  }

  /// Factory para filtros sin resultados
  factory TaskEmptyState.noResults() {
    return const TaskEmptyState(
      title: 'Sin resultados',
      subtitle: 'No se encontraron tareas con los filtros aplicados. Intenta cambiar los filtros.',
      icon: Icons.search_off_rounded,
      accentColor: AppTheme.warningOrange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppTheme.primaryBlue;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con fondo circular
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            // Subtítulo
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            // Acción opcional
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar error al cargar tareas
class TaskErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final Color? accentColor;

  const TaskErrorWidget({
    super.key,
    this.title = 'Error al cargar',
    required this.message,
    this.onRetry,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppTheme.dangerRed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de error
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            // Título
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Mensaje de error
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.4,
              ),
            ),
            // Botón de reintentar
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de carga para tareas
class TaskLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const TaskLoadingWidget({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = color ?? AppTheme.primaryBlue;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: accentColor,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
