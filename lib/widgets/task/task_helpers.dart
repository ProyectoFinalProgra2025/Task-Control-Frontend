import 'package:flutter/material.dart';
import '../../models/enums/estado_tarea.dart';
import '../../models/enums/prioridad_tarea.dart';
import '../../models/enums/departamento.dart';
import '../../config/theme_config.dart';

/// Clase con helpers estáticos para tareas
class TaskHelpers {
  TaskHelpers._();

  // ============== ESTADO COLORES ==============
  
  static Color getEstadoColor(EstadoTarea estado) {
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

  static Color getEstadoBackgroundColor(EstadoTarea estado, {bool isDark = false}) {
    return getEstadoColor(estado).withOpacity(isDark ? 0.2 : 0.1);
  }

  // ============== PRIORIDAD COLORES ==============

  static Color getPrioridadColor(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.low:
        return AppTheme.successGreen;
      case PrioridadTarea.medium:
        return AppTheme.warningOrange;
      case PrioridadTarea.high:
        return AppTheme.dangerRed;
    }
  }

  static IconData getPrioridadIcon(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.low:
        return Icons.arrow_downward_rounded;
      case PrioridadTarea.medium:
        return Icons.remove_rounded;
      case PrioridadTarea.high:
        return Icons.arrow_upward_rounded;
    }
  }

  // ============== DEPARTAMENTO ==============

  static IconData getDepartamentoIcon(Departamento? departamento) {
    switch (departamento) {
      case Departamento.finanzas:
        return Icons.attach_money_rounded;
      case Departamento.mantenimiento:
        return Icons.build_rounded;
      case Departamento.produccion:
        return Icons.factory_rounded;
      case Departamento.marketing:
        return Icons.campaign_rounded;
      case Departamento.logistica:
        return Icons.local_shipping_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  static Color getDepartamentoColor(Departamento? departamento) {
    switch (departamento) {
      case Departamento.finanzas:
        return const Color(0xFF10B981); // Emerald
      case Departamento.mantenimiento:
        return const Color(0xFFF59E0B); // Amber
      case Departamento.produccion:
        return const Color(0xFF3B82F6); // Blue
      case Departamento.marketing:
        return const Color(0xFFEC4899); // Pink
      case Departamento.logistica:
        return const Color(0xFF8B5CF6); // Violet
      default:
        return Colors.grey;
    }
  }

  // ============== ESTADO ICONOS ==============

  static IconData getEstadoIcon(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return Icons.hourglass_empty_rounded;
      case EstadoTarea.asignada:
        return Icons.person_add_rounded;
      case EstadoTarea.aceptada:
        return Icons.play_circle_rounded;
      case EstadoTarea.finalizada:
        return Icons.check_circle_rounded;
      case EstadoTarea.cancelada:
        return Icons.cancel_rounded;
    }
  }

  // ============== FECHA HELPERS ==============

  static String formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Sin fecha';
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  static String formatDueDateShort(DateTime? dueDate) {
    if (dueDate == null) return '--/--';
    return '${dueDate.day}/${dueDate.month}';
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  static String getRelativeDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Sin fecha';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference < 0) {
      return 'Vencida hace ${-difference} días';
    } else if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Mañana';
    } else if (difference < 7) {
      return 'En $difference días';
    } else {
      return formatDueDate(dueDate);
    }
  }

  // ============== PRIORIDAD LABELS ==============

  static String getPrioridadLabel(PrioridadTarea prioridad) {
    switch (prioridad) {
      case PrioridadTarea.low:
        return 'Baja';
      case PrioridadTarea.medium:
        return 'Media';
      case PrioridadTarea.high:
        return 'Alta';
    }
  }

  // ============== ESTADO LABELS ==============

  static String getEstadoLabel(EstadoTarea estado) {
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
}
