import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../models/enums/estado_tarea.dart';
import '../models/enums/prioridad_tarea.dart';
import '../services/tarea_service.dart';

class TareaDetailWidget extends StatefulWidget {
  final int tareaId;

  const TareaDetailWidget({super.key, required this.tareaId});

  @override
  State<TareaDetailWidget> createState() => _TareaDetailWidgetState();
}

class _TareaDetailWidgetState extends State<TareaDetailWidget> {
  final TareaService _tareaService = TareaService();
  Tarea? _tarea;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTarea();
  }

  Future<void> _loadTarea() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tarea = await _tareaService.getTareaById(widget.tareaId);
      if (mounted) {
        setState(() {
          _tarea = tarea;
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

  Future<void> _asignarManual() async {
    // TODO: Mostrar diálogo para seleccionar usuario
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de asignación manual próximamente')),
    );
  }

  Future<void> _asignarAutomatico() async {
    try {
      await _tareaService.asignarAutomatico(widget.tareaId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea asignada automáticamente'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _loadTarea(); // Recargar datos
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _cancelarTarea() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Tarea'),
        content: const Text('¿Está seguro de que desea cancelar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _tareaService.cancelarTarea(widget.tareaId);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea cancelada exitosamente'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true); // Cerrar detalle
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
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
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFF4F6F8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor = isDark ? const Color(0xFF324467) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: const Text('Detalle de Tarea'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar la tarea',
                        style: TextStyle(fontSize: 18, color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 14, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTarea,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _tarea == null
                  ? Center(child: Text('Tarea no encontrada', style: TextStyle(color: textPrimary)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con estado y prioridad
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                        _tarea!.titulo,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(_tarea!.estado)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _tarea!.estado.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getEstadoColor(_tarea!.estado),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getPrioridadColor(_tarea!.prioridad)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            size: 14,
                                            color: _getPrioridadColor(_tarea!.prioridad),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _tarea!.prioridad.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _getPrioridadColor(_tarea!.prioridad),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Descripción
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tarea!.descripcion,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Detalles
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                Text(
                                  'Detalles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow(
                                  Icons.business,
                                  'Departamento',
                                  _tarea!.departamento?.label ?? 'No especificado',
                                  textSecondary,
                                  textPrimary,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.calendar_today,
                                  'Fecha de vencimiento',
                                  _tarea!.dueDate != null
                                      ? '${_tarea!.dueDate!.day}/${_tarea!.dueDate!.month}/${_tarea!.dueDate!.year}'
                                      : 'No especificada',
                                  textSecondary,
                                  textPrimary,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.person,
                                  'Asignado a',
                                  _tarea!.asignadoANombre ?? 'Sin asignar',
                                  textSecondary,
                                  textPrimary,
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  Icons.person_outline,
                                  'Creado por',
                                  _tarea!.creadoPorNombre ?? 'Desconocido',
                                  textSecondary,
                                  textPrimary,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Capacidades requeridas
                          if (_tarea!.capacidadesRequeridas.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
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
                                  Text(
                                    'Capacidades Requeridas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _tarea!.capacidadesRequeridas
                                        .map((cap) => Chip(
                                              label: Text(
                                                cap,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF005A9C).withOpacity(0.1),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Botones de acción
                          if (_tarea!.estado == EstadoTarea.pendiente) ...[
                            ElevatedButton.icon(
                              onPressed: _asignarAutomatico,
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text('Asignar Automáticamente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005A9C),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _asignarManual,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Asignar Manualmente'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF005A9C),
                                side: const BorderSide(color: Color(0xFF005A9C)),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          if (_tarea!.estado != EstadoTarea.cancelada &&
                              _tarea!.estado != EstadoTarea.finalizada) ...[
                            OutlinedButton.icon(
                              onPressed: _cancelarTarea,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancelar Tarea'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color secondaryColor,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
