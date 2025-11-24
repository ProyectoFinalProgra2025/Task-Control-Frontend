import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';
import '../worker/worker_chat_detail_screen.dart';

class AdminTaskDetailScreen extends StatefulWidget {
  final String tareaId;

  const AdminTaskDetailScreen({super.key, required this.tareaId});

  @override
  State<AdminTaskDetailScreen> createState() => _AdminTaskDetailScreenState();
}

class _AdminTaskDetailScreenState extends State<AdminTaskDetailScreen> {
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
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
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
                                  Icon(Icons.verified_outlined, size: 20, color: AppTheme.primaryBlue),
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
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    cap,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primaryBlue,
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
                      if (_tarea!.asignadoAUsuarioId != null && _tarea!.asignadoAUsuarioId!.isNotEmpty) ...[
                        _buildChatButton(
                          icon: Icons.person_outline,
                          label: 'Chat con ${_tarea!.asignadoANombre ?? "Trabajador Asignado"}',
                          color: AppTheme.primaryBlue,
                          onPressed: () => _chatWithUser(_tarea!.asignadoAUsuarioId!, _tarea!.asignadoANombre ?? ''),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Botón para cancelar tarea (solo admin)
                      if (_tarea!.estado != EstadoTarea.finalizada && _tarea!.estado != EstadoTarea.cancelada) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelarTarea(),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text(
                              'Cancelar Tarea',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.dangerRed,
                              side: const BorderSide(color: AppTheme.dangerRed, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _cancelarTarea() async {
    final motivoController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed),
              const SizedBox(width: 8),
              const Text('Cancelar Tarea', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Estás seguro de que deseas cancelar esta tarea?'),
              const SizedBox(height: 8),
              Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  labelText: 'Motivo de cancelación',
                  hintText: 'Explica por qué se cancela...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.dangerRed, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, mantener', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Sí, cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && motivoController.text.isNotEmpty) {
      Provider.of<TareaProvider>(context, listen: false);
      // Aquí deberías implementar el método para cancelar tarea en el provider
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea cancelada exitosamente'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      await _cargarDetalle();
    } else if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes proporcionar un motivo de cancelación'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
    }
  }

  Future<void> _chatWithUser(String userId, String userName) async {
    if (userId.isEmpty) return;

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
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
