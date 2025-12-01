/// Utilidades para manejo de fechas y zonas horarias
/// Bolivia está en UTC-4 (sin horario de verano)

class AppDateUtils {
  /// Offset de Bolivia en horas (UTC-4)
  static const int boliviaOffsetHours = -4;

  /// Convierte una fecha UTC a hora local de Bolivia
  static DateTime utcToBolivia(DateTime utcDate) {
    // Si ya es local, convertir a UTC primero
    final utc = utcDate.isUtc ? utcDate : utcDate.toUtc();
    return utc.add(const Duration(hours: boliviaOffsetHours));
  }

  /// Convierte una fecha local de Bolivia a UTC
  static DateTime boliviaToUtc(DateTime localDate) {
    return localDate.subtract(const Duration(hours: boliviaOffsetHours));
  }

  /// Formatea una fecha UTC para mostrar en hora Bolivia
  static String formatTime(DateTime? utcDate) {
    if (utcDate == null) return '';
    final local = utcToBolivia(utcDate);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formatea fecha relativa (Hoy, Ayer, Lun, Mar, etc.) en hora Bolivia
  static String formatRelativeDate(DateTime? utcDate) {
    if (utcDate == null) return '';
    
    final local = utcToBolivia(utcDate);
    final now = utcToBolivia(DateTime.now().toUtc());
    final diff = now.difference(local);
    
    if (diff.inDays == 0 && local.day == now.day) {
      // Hoy - mostrar hora
      return formatTime(utcDate);
    } else if (diff.inDays == 1 || (diff.inDays == 0 && local.day != now.day)) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[local.weekday - 1];
    } else {
      return '${local.day}/${local.month}';
    }
  }

  /// Formatea fecha completa en hora Bolivia
  static String formatFullDate(DateTime? utcDate) {
    if (utcDate == null) return '';
    final local = utcToBolivia(utcDate);
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  /// Formatea fecha y hora completa en hora Bolivia
  static String formatFullDateTime(DateTime? utcDate) {
    if (utcDate == null) return '';
    return '${formatFullDate(utcDate)} ${formatTime(utcDate)}';
  }
}
