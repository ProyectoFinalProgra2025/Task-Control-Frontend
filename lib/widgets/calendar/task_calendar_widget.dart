import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';

/// Widget de calendario de tareas modular
/// Se adapta al rol: CompanyAdmin ve toda la empresa, AreaManager ve su departamento
class TaskCalendarWidget extends StatefulWidget {
  /// Lista de tareas a mostrar en el calendario
  final List<Tarea> tareas;
  
  /// Título del calendario
  final String title;
  
  /// Color primario del calendario
  final Color primaryColor;
  
  /// Callback cuando se selecciona una tarea
  final Function(Tarea)? onTaskTap;
  
  /// Callback cuando se selecciona un día
  final Function(DateTime, List<Tarea>)? onDayTap;
  
  /// Si está cargando
  final bool isLoading;
  
  /// Altura máxima del widget
  final double? maxHeight;

  const TaskCalendarWidget({
    super.key,
    required this.tareas,
    this.title = 'Calendario de Tareas',
    this.primaryColor = AppTheme.primaryBlue,
    this.onTaskTap,
    this.onDayTap,
    this.isLoading = false,
    this.maxHeight,
  });

  @override
  State<TaskCalendarWidget> createState() => _TaskCalendarWidgetState();
}

class _TaskCalendarWidgetState extends State<TaskCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  /// Agrupa las tareas por fecha (usando dueDate)
  Map<DateTime, List<Tarea>> get _tareasAgrupadas {
    final Map<DateTime, List<Tarea>> result = {};
    for (final tarea in widget.tareas) {
      if (tarea.dueDate != null) {
        final date = DateTime(
          tarea.dueDate!.year,
          tarea.dueDate!.month,
          tarea.dueDate!.day,
        );
        if (result[date] == null) {
          result[date] = [];
        }
        result[date]!.add(tarea);
      }
    }
    return result;
  }

  List<Tarea> _getTareasForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _tareasAgrupadas[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tareasDelDia = _selectedDay != null ? _getTareasForDay(_selectedDay!) : <Tarea>[];

    return Container(
      constraints: widget.maxHeight != null
          ? BoxConstraints(maxHeight: widget.maxHeight!)
          : null,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.darkBorder.withOpacity(0.3)
              : AppTheme.lightBorder,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: widget.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                // Format toggle
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildFormatButton('Mes', CalendarFormat.month, isDark),
                      _buildFormatButton('2 Sem', CalendarFormat.twoWeeks, isDark),
                      _buildFormatButton('Sem', CalendarFormat.week, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: widget.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            // Calendar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TableCalendar<Tarea>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getTareasForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'es_ES',
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextTertiary
                        : AppTheme.lightTextTertiary,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  defaultTextStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  todayDecoration: BoxDecoration(
                    color: widget.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: widget.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  markerDecoration: BoxDecoration(
                    color: widget.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  markerSize: 6,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    return _buildMarkers(events, isDark);
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  final tareas = _getTareasForDay(selectedDay);
                  if (widget.onDayTap != null) {
                    widget.onDayTap!(selectedDay, tareas);
                  }
                  if (tareas.isNotEmpty) {
                    _showDayTasksSheet(context, selectedDay, tareas, isDark);
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),

            // Selected day info
            if (_selectedDay != null && tareasDelDia.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      color: widget.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tareasDelDia.length} tarea${tareasDelDia.length != 1 ? 's' : ''} para el ${DateFormat('d MMM', 'es').format(_selectedDay!)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showDayTasksSheet(
                        context,
                        _selectedDay!,
                        tareasDelDia,
                        isDark,
                      ),
                      child: Text(
                        'Ver todas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatButton(String label, CalendarFormat format, bool isDark) {
    final isSelected = _calendarFormat == format;
    return InkWell(
      onTap: () => setState(() => _calendarFormat = format),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildMarkers(List<Tarea> tareas, bool isDark) {
    // Agrupar por estado para mostrar diferentes colores
    final pendientes = tareas.where((t) => t.estado == EstadoTarea.pendiente).length;
    final asignadas = tareas.where((t) => t.estado == EstadoTarea.asignada).length;
    final aceptadas = tareas.where((t) => t.estado == EstadoTarea.aceptada).length;
    final finalizadas = tareas.where((t) => t.estado == EstadoTarea.finalizada).length;

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendientes > 0) _buildMarkerDot(AppTheme.warningOrange),
          if (asignadas > 0) _buildMarkerDot(AppTheme.primaryBlue),
          if (aceptadas > 0) _buildMarkerDot(const Color(0xFF7C3AED)),
          if (finalizadas > 0) _buildMarkerDot(AppTheme.successGreen),
        ],
      ),
    );
  }

  Widget _buildMarkerDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _showDayTasksSheet(
    BuildContext context,
    DateTime day,
    List<Tarea> tareas,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayTasksSheet(
        day: day,
        tareas: tareas,
        primaryColor: widget.primaryColor,
        onTaskTap: widget.onTaskTap,
      ),
    );
  }
}

/// Bottom sheet que muestra las tareas de un día específico
class DayTasksSheet extends StatelessWidget {
  final DateTime day;
  final List<Tarea> tareas;
  final Color primaryColor;
  final Function(Tarea)? onTaskTap;

  const DayTasksSheet({
    super.key,
    required this.day,
    required this.tareas,
    required this.primaryColor,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkBorder
                  : AppTheme.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM', 'es').format(day),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${tareas.length} tarea${tareas.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark
                ? AppTheme.darkBorder.withOpacity(0.3)
                : AppTheme.lightBorder,
          ),

          // Task list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: tareas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tarea = tareas[index];
                return _buildTaskItem(context, tarea, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Tarea tarea, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTaskTap?.call(tarea);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBackground
              : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorder.withOpacity(0.3)
                : AppTheme.lightBorder,
          ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildEstadoBadge(tarea.estado),
              ],
            ),
            if (tarea.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tarea.descripcion,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (tarea.asignadoANombre != null) ...[
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tarea.asignadoANombre!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark
                      ? AppTheme.darkTextTertiary
                      : AppTheme.lightTextTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(EstadoTarea estado) {
    Color color;
    String text;

    switch (estado) {
      case EstadoTarea.pendiente:
        color = AppTheme.warningOrange;
        text = 'Pendiente';
        break;
      case EstadoTarea.asignada:
        color = AppTheme.primaryBlue;
        text = 'Asignada';
        break;
      case EstadoTarea.aceptada:
        color = const Color(0xFF7C3AED);
        text = 'En progreso';
        break;
      case EstadoTarea.finalizada:
        color = AppTheme.successGreen;
        text = 'Finalizada';
        break;
      case EstadoTarea.cancelada:
        color = AppTheme.dangerRed;
        text = 'Cancelada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
