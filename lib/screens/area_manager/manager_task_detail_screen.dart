import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';
import '../worker/worker_chat_detail_screen.dart';

class ManagerTaskDetailScreen extends StatefulWidget {
  final String tareaId;

  const ManagerTaskDetailScreen({super.key, required this.tareaId});

  @override
  State<ManagerTaskDetailScreen> createState() => _ManagerTaskDetailScreenState();
}

class _ManagerTaskDetailScreenState extends State<ManagerTaskDetailScreen> {
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
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Detalle de Tarea', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.successGreen))
          : _tarea == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.dangerRed),
                      const SizedBox(height: 16),
                      Text('Error al cargar la tarea', style: TextStyle(fontSize: 16, color: textPrimary)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y Estado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
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
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _tarea!.titulo,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getEstadoColor(_tarea!.estado),
                                        _getEstadoColor(_tarea!.estado).withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getEstadoColor(_tarea!.estado).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _getEstadoText(_tarea!.estado),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tarea!.descripcion,
                              style: TextStyle(
                                fontSize: 15,
                                color: textSecondary,
                                height: 1.5,
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
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
                          children: [
                            Text(
                              'Detalles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.flag_outlined,
                              'Prioridad',
                              _tarea!.prioridad.label,
                              _getPrioridadColor(_tarea!.prioridad),
                              isDark,
                            ),
                            if (_tarea!.departamento != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.business_outlined,
                                'Departamento',
                                _tarea!.departamento!.label,
                                AppTheme.primaryBlue,
                                isDark,
                              ),
                            ],
                            if (_tarea!.asignadoANombre != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.person_outline,
                                'Asignado a',
                                _tarea!.asignadoANombre!,
                                AppTheme.successGreen,
                                isDark,
                              ),
                            ],
                            if (_tarea!.dueDate != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.calendar_today_outlined,
                                'Fecha Límite',
                                '${_tarea!.dueDate!.day}/${_tarea!.dueDate!.month}/${_tarea!.dueDate!.year}',
                                AppTheme.warningOrange,
                                isDark,
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.history,
                              'Creada el',
                              '${_tarea!.createdAt.day}/${_tarea!.createdAt.month}/${_tarea!.createdAt.year}',
                              textSecondary,
                              isDark,
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder),
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
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.verified_outlined, size: 20, color: AppTheme.successGreen),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Capacidades Requeridas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _tarea!.capacidadesRequeridas.map((cap) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    cap,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Botones de Chat
                      if (_tarea!.createdByUsuarioId.isNotEmpty) ...[
                        _buildChatButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat con ${_tarea!.createdByUsuarioNombre.isNotEmpty ? _tarea!.createdByUsuarioNombre : "Creador"}',
                          color: AppTheme.primaryBlue,
                          onPressed: () => _chatWithUser(_tarea!.createdByUsuarioId, _tarea!.createdByUsuarioNombre),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_tarea!.asignadoAUsuarioId != null && _tarea!.asignadoAUsuarioId!.isNotEmpty) ...[
                        _buildChatButton(
                          icon: Icons.person_outline,
                          label: 'Chat con ${_tarea!.asignadoANombre ?? "Trabajador"}',
                          color: AppTheme.successGreen,
                          onPressed: () => _chatWithUser(_tarea!.asignadoAUsuarioId!, _tarea!.asignadoANombre ?? ''),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Botones de acción según estado
                      if (_tarea!.estado == EstadoTarea.asignada) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _aceptarTarea(),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'Aceptar Tarea',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _delegarTarea(),
                            icon: const Icon(Icons.person_add_outlined),
                            label: const Text(
                              'Delegar Tarea',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.warningOrange,
                              side: const BorderSide(color: AppTheme.warningOrange, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],

                      if (_tarea!.estado == EstadoTarea.aceptada) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _finalizarTarea(),
                            icon: const Icon(Icons.task_alt),
                            label: const Text(
                              'Finalizar Tarea',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Color _getEstadoColor(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return AppTheme.warningOrange;
      case EstadoTarea.asignada:
        return AppTheme.primaryBlue;
      case EstadoTarea.aceptada:
        return const Color(0xFF7C3AED);
      case EstadoTarea.finalizada:
        return AppTheme.successGreen;
      case EstadoTarea.cancelada:
        return AppTheme.dangerRed;
    }
  }

  String _getEstadoText(EstadoTarea estado) {
    switch (estado) {
      case EstadoTarea.pendiente:
        return 'Pendiente';
      case EstadoTarea.asignada:
        return 'Asignada';
      case EstadoTarea.aceptada:
        return 'Aceptada';
      case EstadoTarea.finalizada:
        return 'Finalizada';
      case EstadoTarea.cancelada:
        return 'Cancelada';
    }
  }

  Color _getPrioridadColor(prioridad) {
    switch (prioridad.toString()) {
      case 'PrioridadTarea.low':
        return AppTheme.successGreen;
      case 'PrioridadTarea.medium':
        return AppTheme.warningOrange;
      case 'PrioridadTarea.high':
        return AppTheme.dangerRed;
      default:
        return AppTheme.warningOrange;
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
          backgroundColor: AppTheme.successGreen,
        ),
      );
      await _cargarDetalle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tareaProvider.error ?? 'Error al aceptar tarea'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _finalizarTarea() async {
    final evidenciaController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Finalizar Tarea', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de que deseas finalizar esta tarea?'),
              const SizedBox(height: 16),
              TextField(
                controller: evidenciaController,
                decoration: InputDecoration(
                  labelText: 'Evidencia (opcional)',
                  hintText: 'Describe el trabajo realizado...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.successGreen, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      final dto = FinalizarTareaDTO(
        evidenciaTexto: evidenciaController.text.isNotEmpty ? evidenciaController.text : null,
      );

      final success = await tareaProvider.finalizarTarea(widget.tareaId, dto);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tarea finalizada exitosamente!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        await _cargarDetalle();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tareaProvider.error ?? 'Error al finalizar tarea'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _delegarTarea() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de delegación próximamente'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }

  Future<void> _chatWithUser(String userId, String userName) async {
    if (userId.isEmpty) return;

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.successGreen),
        ),
      );

      final chat = await chatProvider.createOneToOneChat(userId);

      if (!mounted) return;

      Navigator.of(context).pop();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerChatDetailScreen(
            chatId: chat.id,
            chatName: userName.isNotEmpty ? userName : 'Usuario',
            chatType: '1:1',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context, rootNavigator: true).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir chat: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }
}
