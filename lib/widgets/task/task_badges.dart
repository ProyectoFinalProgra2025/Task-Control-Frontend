import 'package:flutter/material.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../config/theme_config.dart';
import 'task_helpers.dart';

/// Badge para mostrar el estado de una tarea
/// Estilo moderno con gradiente y sombra
class TaskStatusBadge extends StatelessWidget {
  final EstadoTarea estado;
  final bool showIcon;
  final bool isCompact;

  const TaskStatusBadge({
    super.key,
    required this.estado,
    this.showIcon = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TaskHelpers.getEstadoColor(estado);
    final label = TaskHelpers.getEstadoLabel(estado);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              TaskHelpers.getEstadoIcon(estado),
              color: Colors.white,
              size: isCompact ? 12 : 14,
            ),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge para mostrar la prioridad de una tarea
/// Estilo moderno con borde y fondo semitransparente
class TaskPriorityBadge extends StatelessWidget {
  final PrioridadTarea prioridad;
  final bool showIcon;
  final bool isCompact;

  const TaskPriorityBadge({
    super.key,
    required this.prioridad,
    this.showIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TaskHelpers.getPrioridadColor(prioridad);
    final label = TaskHelpers.getPrioridadLabel(prioridad);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              TaskHelpers.getPrioridadIcon(prioridad),
              color: color,
              size: isCompact ? 12 : 14,
            ),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip para tags/capacidades requeridas (estilo oscuro inspirado en la imagen)
class TaskSkillChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isCompact;

  const TaskSkillChip({
    super.key,
    required this.label,
    this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Colores estilo "olive green" como en la imagen de referencia
    final chipColor = color ?? (isDark 
        ? const Color(0xFF3D4A2E)  // Verde oliva oscuro
        : const Color(0xFFE8F5E9)); // Verde claro
    final textColor = isDark 
        ? const Color(0xFFC1FF72)  // Verde lima brillante
        : const Color(0xFF2E7D32); // Verde oscuro

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: isCompact ? 12 : 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip para fechas (estilo neutral)
class TaskDateChip extends StatelessWidget {
  final DateTime? dueDate;
  final bool showRelative;
  final bool isCompact;

  const TaskDateChip({
    super.key,
    required this.dueDate,
    this.showRelative = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = TaskHelpers.isOverdue(dueDate);
    
    final color = isOverdue 
        ? AppTheme.dangerRed 
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);
    
    final label = showRelative
        ? TaskHelpers.getRelativeDueDate(dueDate)
        : TaskHelpers.formatDueDateShort(dueDate);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppTheme.dangerRed.withOpacity(0.1)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.calendar_today_rounded,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge para asignación (muestra si está asignada o no)
class TaskAssigneeBadge extends StatelessWidget {
  final String? assigneeName;
  final bool isCompact;
  final bool isRejected;
  final String? rejectionReason;

  const TaskAssigneeBadge({
    super.key,
    required this.assigneeName,
    this.isCompact = false,
    this.isRejected = false,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isRejected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: isCompact ? 14 : 16,
            color: AppTheme.dangerRed,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            'Rechazada',
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.dangerRed,
            ),
          ),
        ],
      );
    }

    if (assigneeName == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: isCompact ? 14 : 16,
            color: AppTheme.warningOrange,
          ),
          SizedBox(width: isCompact ? 4 : 6),
          Text(
            'Sin asignar',
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.warningOrange,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: isCompact ? 14 : 16,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        ),
        SizedBox(width: isCompact ? 4 : 6),
        Flexible(
          child: Text(
            assigneeName!,
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
