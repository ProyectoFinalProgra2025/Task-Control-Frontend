import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';

class WorkerTaskDetailScreen extends StatefulWidget {
  final int tareaId;

  const WorkerTaskDetailScreen({super.key, required this.tareaId});

  @override
  State<WorkerTaskDetailScreen> createState() => _WorkerTaskDetailScreenState();
}

class _WorkerTaskDetailScreenState extends State<WorkerTaskDetailScreen> {
  Tarea? _tarea;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _isLoading = true);
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final tarea = await tareaProvider.obtenerTareaDetalle(widget.tareaId);
    
    if (mounted) {
      setState(() {
        _tarea = tarea;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFf6f6f8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F2937);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF64748b);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de Tarea'),
        backgroundColor: isDark ? const Color(0xFF192233) : Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tarea == null
              ? const Center(child: Text('Error al cargar la tarea'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y Estado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF324467)
                                : const Color(0xFFE5E7EB),
                          ),
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
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getEstadoColor(_tarea!.estado)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getEstadoText(_tarea!.estado),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _getEstadoColor(_tarea!.estado),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _tarea!.descripcion,
                              style: TextStyle(
                                fontSize: 16,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Información de la Tarea
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF324467)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Prioridad',
                              _tarea!.prioridad.name.toUpperCase(),
                              textSecondary,
                            ),
                            if (_tarea!.departamento != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Departamento',
                                _tarea!.departamento!.name,
                                textSecondary,
                              ),
                            ],
                            if (_tarea!.dueDate != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Fecha Límite',
                                '${_tarea!.dueDate!.day}/${_tarea!.dueDate!.month}/${_tarea!.dueDate!.year}',
                                textSecondary,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Creada el',
                              '${_tarea!.createdAt.day}/${_tarea!.createdAt.month}/${_tarea!.createdAt.year}',
                              textSecondary,
                            ),
                          ],
                        ),
                      ),

                      // Capacidades Requeridas
                      if (_tarea!.capacidadesRequeridas.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF324467)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Capacidades Requeridas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _tarea!.capacidadesRequeridas
                                    .map(
                                      (cap) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF135BEC)
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          cap,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF135BEC),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Botones de acción
                      const SizedBox(height: 24),
                      if (_tarea!.estado == EstadoTarea.asignada)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _aceptarTarea(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Aceptar Tarea',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_tarea!.estado == EstadoTarea.aceptada)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _finalizarTarea(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135BEC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Finalizar Tarea',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.asignada:
        return Colors.blue;
      case EstadoTarea.aceptada:
        return Colors.orange;
      case EstadoTarea.finalizada:
        return Colors.green;
      case EstadoTarea.cancelada:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.asignada:
        return 'Asignada';
      case EstadoTarea.aceptada:
        return 'En Progreso';
      case EstadoTarea.finalizada:
        return 'Finalizada';
      case EstadoTarea.cancelada:
        return 'Cancelada';
      default:
        return 'Pendiente';
    }
  }

  Future<void> _aceptarTarea() async {
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final success = await tareaProvider.aceptarTarea(widget.tareaId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tarea aceptada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      await _cargarDetalle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tareaProvider.error ?? 'Error al aceptar tarea'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finalizarTarea() async {
    final evidenciaController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de que deseas finalizar esta tarea?'),
            const SizedBox(height: 16),
            TextField(
              controller: evidenciaController,
              decoration: const InputDecoration(
                labelText: 'Evidencia (opcional)',
                hintText: 'Describe el trabajo realizado...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      final dto = FinalizarTareaDTO(
        evidenciaTexto: evidenciaController.text.isNotEmpty
            ? evidenciaController.text
            : null,
      );

      final success = await tareaProvider.finalizarTarea(widget.tareaId, dto);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tarea finalizada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDetalle();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tareaProvider.error ?? 'Error al finalizar tarea'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
