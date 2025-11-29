import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';
import '../task_progress_indicator.dart';
import 'task_badges.dart';
import 'task_helpers.dart';

/// Estilo visual para las tarjetas de tareas
enum TaskCardStyle {
  standard,    // Tarjeta normal
  compact,     // Tarjeta compacta para listas
  premium,     // Tarjeta con más detalles y barra de progreso
  worker,      // Estilo para workers (con progreso y botón aceptar)
}

/// Tarjeta reutilizable para mostrar una tarea
/// Inspirada en el diseño oscuro moderno de la imagen de referencia
class TaskCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? action;
  final TaskCardStyle style;
  final Color? accentColor;
  final bool showSkills;
  final bool showAssignee;
  final bool showDueDate;
  final bool showProgressIndicator;

  const TaskCard({
    super.key,
    required this.tarea,
    this.onTap,
    this.trailing,
    this.action,
    this.style = TaskCardStyle.standard,
    this.accentColor,
    this.showSkills = true,
    this.showAssignee = true,
    this.showDueDate = true,
    this.showProgressIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showProgress = showProgressIndicator || 
                         style == TaskCardStyle.premium || 
                         style == TaskCardStyle.worker;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(style == TaskCardStyle.compact ? 12 : 16),
          border: Border.all(
            color: isDark 
                ? AppTheme.darkBorder.withOpacity(0.3) 
                : AppTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: style == TaskCardStyle.compact ? 4 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(style == TaskCardStyle.compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de color superior (solo en premium/worker)
              if (style == TaskCardStyle.premium || style == TaskCardStyle.worker)
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor ?? TaskHelpers.getPrioridadColor(tarea.prioridad),
                        (accentColor ?? TaskHelpers.getPrioridadColor(tarea.prioridad)).withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(style == TaskCardStyle.compact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Título + Estado
                    _buildHeader(isDark),
                    
                    // Descripción
                    if (style != TaskCardStyle.compact) ...[
                      const SizedBox(height: 10),
                      _buildDescription(isDark),
                    ],
                    
                    // Barra de progreso
                    if (showProgress && 
                        tarea.estado != EstadoTarea.pendiente &&
                        tarea.estado != EstadoTarea.cancelada) ...[
                      const SizedBox(height: 14),
                      TaskProgressIndicator(
                        estadoActual: tarea.estado,
                        primaryColor: accentColor ?? AppTheme.primaryBlue,
                        showLabels: style == TaskCardStyle.worker || style == TaskCardStyle.premium,
                        height: style == TaskCardStyle.compact ? 50 : 60,
                      ),
                    ],
                    
                    // Skills/Capacidades
                    if (showSkills && tarea.capacidadesRequeridas.isNotEmpty) ...[
                      SizedBox(height: style == TaskCardStyle.compact ? 8 : 12),
                      _buildSkillsRow(),
                    ],
                    
                    // Info Row (asignado, fecha, prioridad)
                    SizedBox(height: style == TaskCardStyle.compact ? 8 : 14),
                    _buildInfoRow(isDark),
                    
                    // Motivo de rechazo si existe
                    if (tarea.delegacionAceptada == false && 
                        tarea.motivoRechazoJefe != null) ...[
                      const SizedBox(height: 12),
                      _buildRejectionBanner(isDark),
                    ],
                    
                    // Acción adicional (ej: botón aceptar)
                    if (action != null) ...[
                      const SizedBox(height: 14),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            tarea.titulo,
            style: TextStyle(
              fontSize: style == TaskCardStyle.compact ? 15 : 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              letterSpacing: -0.3,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        TaskStatusBadge(
          estado: tarea.estado,
          isCompact: style == TaskCardStyle.compact,
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }

  Widget _buildDescription(bool isDark) {
    return Text(
      tarea.descripcion,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        height: 1.4,
      ),
      maxLines: style == TaskCardStyle.premium ? 3 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSkillsRow() {
    final maxSkills = style == TaskCardStyle.compact ? 2 : 3;
    final skills = tarea.capacidadesRequeridas.take(maxSkills).toList();
    final remaining = tarea.capacidadesRequeridas.length - maxSkills;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...skills.map((skill) => TaskSkillChip(
          label: skill,
          isCompact: style == TaskCardStyle.compact,
        )),
        if (remaining > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: style == TaskCardStyle.compact ? 8 : 10,
              vertical: style == TaskCardStyle.compact ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                fontSize: style == TaskCardStyle.compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(bool isDark) {
    return Row(
      children: [
        // Prioridad
        TaskPriorityBadge(
          prioridad: tarea.prioridad,
          isCompact: style == TaskCardStyle.compact,
          showIcon: true,
        ),
        
        const SizedBox(width: 10),
        
        // Fecha
        if (showDueDate && tarea.dueDate != null) ...[
          TaskDateChip(
            dueDate: tarea.dueDate,
            isCompact: style == TaskCardStyle.compact,
          ),
          const SizedBox(width: 10),
        ],
        
        const Spacer(),
        
        // Asignado
        if (showAssignee)
          Flexible(
            child: TaskAssigneeBadge(
              assigneeName: tarea.asignadoANombre,
              isCompact: style == TaskCardStyle.compact,
              isRejected: tarea.delegacionAceptada == false && 
                          tarea.motivoRechazoJefe != null,
            ),
          ),
      ],
    );
  }

  Widget _buildRejectionBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.dangerRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dangerRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppTheme.dangerRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Motivo: ${tarea.motivoRechazoJefe}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.dangerRed,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Versión especial de TaskCard con estilo oscuro moderno
/// Ideal para listas en temas oscuros
class TaskCardDark extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback? onTap;
  final Widget? action;

  const TaskCardDark({
    super.key,
    required this.tarea,
    this.onTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    // Fuerza estilo oscuro para esta tarjeta
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Casi negro
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  tarea.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtítulo/precio (si hay due date)
                if (tarea.dueDate != null)
                  Text(
                    TaskHelpers.getRelativeDueDate(tarea.dueDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                    ),
                  ),
                const SizedBox(height: 10),
                // Descripción
                Text(
                  tarea.descripcion,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Skills en chips oscuros
                if (tarea.capacidadesRequeridas.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tarea.capacidadesRequeridas.take(3).map((skill) => 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D4A2E), // Verde oliva oscuro
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: Color(0xFFC1FF72), // Verde lima
                            ),
                            const SizedBox(width: 6),
                            Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFC1FF72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(),
                  ),
                if (action != null) ...[
                  const SizedBox(height: 14),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
