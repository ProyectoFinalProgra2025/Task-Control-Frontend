import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/admin_tarea_provider.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../config/theme_config.dart';
import '../../services/tarea_service.dart';
import '../../services/usuario_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/task/task_widgets.dart';
import '../../widgets/task_documentos_widget.dart';
import '../../widgets/task_evidencias_widget.dart';
import '../../models/enums/estado_tarea.dart';

class ManagerTaskDetailScreen extends StatefulWidget {
  final String tareaId;

  const ManagerTaskDetailScreen({
    super.key,
    required this.tareaId,
  });

  @override
  State<ManagerTaskDetailScreen> createState() =>
      _ManagerTaskDetailScreenState();
}

class _ManagerTaskDetailScreenState extends State<ManagerTaskDetailScreen> {
  final StorageService _storage = StorageService();
  final TareaService _tareaService = TareaService();
  final UsuarioService _usuarioService = UsuarioService();
  
  Tarea? _tarea;
  List<Usuario> _trabajadores = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _hasChanges = false; // Track if any changes were made
  String? _currentUserId; // ID del manager actual

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      
      // Obtener ID del usuario actual
      final userData = await _storage.getUserData();
      _currentUserId = userData?['id']?.toString();
      
      // Cargar tarea y trabajadores en paralelo
      final results = await Future.wait([
        tareaProvider.obtenerTareaDetalle(widget.tareaId),
        _usuarioService.getUsuarios(),
      ]);

      if (mounted) {
        setState(() {
          _tarea = results[0] as Tarea?;
          _trabajadores = results[1] as List<Usuario>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _asignarTarea(String trabajadorId) async {
    setState(() => _isProcessing = true);

    try {
      await _tareaService.asignarManual(
        widget.tareaId, 
        AsignarManualTareaDTO(usuarioId: trabajadorId),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea asignada exitosamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        _hasChanges = true;
        // Recargar datos y actualizar provider
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _delegarTarea() async {
    // Obtener lista de jefes para delegar
    try {
      final jefes = await _tareaService.getJefesArea();
      
      if (!mounted) return;
      
      // Filtrar el jefe actual
      final userData = await _storage.getUserData();
      final userId = userData?['id']?.toString();
      final jefesDisponibles = jefes.where((j) => j['id'].toString() != userId).toList();

      if (jefesDisponibles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay otros jefes disponibles para delegar'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
        return;
      }

      _mostrarDialogoDelegacion(jefesDisponibles);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener jefes: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  void _mostrarDialogoDelegacion(List<Map<String, dynamic>> jefes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delegar Tarea',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${jefes.length} jefes disponibles',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jefes.length,
                  itemBuilder: (context, index) {
                    final jefe = jefes[index];
                    return _JefeListItem(
                      nombre: jefe['nombreCompleto'] ?? 'Jefe',
                      departamento: jefe['departamento']?.toString(),
                      onSelect: () {
                        Navigator.pop(context);
                        _confirmarDelegacion(jefe['id'].toString());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarDelegacion(String jefeId) async {
    setState(() => _isProcessing = true);

    try {
      await _tareaService.delegarTarea(widget.tareaId, jefeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea delegada exitosamente'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al delegar: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _aceptarDelegacion() async {
    setState(() => _isProcessing = true);

    try {
      await _tareaService.aceptarDelegacion(widget.tareaId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delegación aceptada. Ahora puedes asignar trabajadores.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _hasChanges = true;
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rechazarDelegacion() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rechazar Delegación',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: TextField(
          controller: motivoController,
          maxLines: 3,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Motivo del rechazo (mínimo 10 caracteres)...',
            hintStyle: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivoController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.trim().length < 10) {
      if (motivo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El motivo debe tener al menos 10 caracteres'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _tareaService.rechazarDelegacion(widget.tareaId, motivo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delegación rechazada'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
        
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Aceptar tarea propia (cuando está asignada al manager)
  Future<void> _aceptarTareaPropia() async {
    setState(() => _isProcessing = true);

    try {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      final success = await tareaProvider.aceptarTarea(widget.tareaId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(success 
                    ? '¡Tarea aceptada exitosamente!' 
                    : tareaProvider.error ?? 'Error al aceptar'),
              ],
            ),
            backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (success) {
          _hasChanges = true;
          Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Finalizar tarea propia (cuando está aceptada por el manager)
  Future<void> _finalizarTareaPropia() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final evidenciaController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.task_alt, color: AppTheme.successGreen, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Finalizar Tarea', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas finalizar esta tarea?',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: evidenciaController,
              decoration: InputDecoration(
                labelText: 'Evidencia del trabajo',
                hintText: 'Describe lo que realizaste...',
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
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      final dto = FinalizarTareaDTO(
        evidenciaTexto: evidenciaController.text.isNotEmpty
            ? evidenciaController.text
            : null,
      );

      final success = await tareaProvider.finalizarTarea(widget.tareaId, dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 12),
                Text(success 
                    ? '¡Tarea finalizada exitosamente!' 
                    : tareaProvider.error ?? 'Error al finalizar'),
              ],
            ),
            backgroundColor: success ? AppTheme.successGreen : AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (success) {
          _hasChanges = true;
          Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
          await _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Reasignar tarea a un worker del departamento
  Future<void> _reasignarAWorker() async {
    // Mostrar diálogo para elegir acción
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.warningOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                '¿Qué deseas hacer?',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionOption(
                icon: Icons.person_add_rounded,
                title: 'Asignar a un Worker',
                subtitle: 'Asignar a un trabajador de tu departamento',
                color: AppTheme.successGreen,
                onTap: () => Navigator.pop(context, 'asignar_worker'),
              ),
              const SizedBox(height: 8),
              _buildActionOption(
                icon: Icons.supervisor_account_rounded,
                title: 'Delegar a otro Manager',
                subtitle: 'Pasar la tarea a otro jefe de departamento',
                color: AppTheme.primaryBlue,
                onTap: () => Navigator.pop(context, 'delegar_manager'),
              ),
              const SizedBox(height: 8),
              _buildActionOption(
                icon: Icons.cancel_rounded,
                title: 'Rechazar tarea',
                subtitle: 'Devolver la tarea al creador',
                color: AppTheme.dangerRed,
                onTap: () => Navigator.pop(context, 'rechazar'),
              ),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) return;

    if (action == 'asignar_worker') {
      _mostrarDialogoAsignar();
    } else if (action == 'delegar_manager') {
      _delegarTarea();
    } else if (action == 'rechazar') {
      _rechazarTareaPropia();
    }
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }

  /// Rechazar tarea propia (cancelar)
  Future<void> _rechazarTareaPropia() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_rounded, color: AppTheme.dangerRed, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Rechazar Tarea',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La tarea volverá al creador como "Sin asignar".',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              maxLines: 3,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Motivo del rechazo (obligatorio)',
                hintText: 'Explica por qué rechazas...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.dangerRed, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes proporcionar un motivo'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
                return;
              }
              Navigator.pop(context, motivoController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (motivo == null || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await _tareaService.cancelarTarea(widget.tareaId, motivo: motivo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea rechazada'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
        
        _hasChanges = true;
        Provider.of<TareaProvider>(context, listen: false).cargarMisTareas();
        Provider.of<AdminTareaProvider>(context, listen: false).cargarTodasLasTareas();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _chatWithUser(String recipientId, String recipientName) async {
    // TODO: Implementar chat con nuevo backend
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El sistema de chat estará disponible pronto'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarDialogoAsignar() {
    // Filtrar trabajadores con capacidades requeridas
    final trabajadoresCompatibles = _trabajadores.where((t) {
      if (_tarea?.capacidadesRequeridas.isEmpty ?? true) return true;

      final capacidadesUsuario = t.capacidades.map((c) => c.nombre.toLowerCase()).toSet();
      final capacidadesRequeridas = _tarea!.capacidadesRequeridas.map((c) => c.toLowerCase()).toSet();

      return capacidadesRequeridas.every(capacidadesUsuario.contains);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asignar Trabajador',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${trabajadoresCompatibles.length} trabajadores compatibles',
                            style: TextStyle(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.white10 : Colors.black12),
              Expanded(
                child: trabajadoresCompatibles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay trabajadores con las\ncapacidades requeridas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: trabajadoresCompatibles.length,
                        itemBuilder: (context, index) {
                          final trabajador = trabajadoresCompatibles[index];
                          return _WorkerListItem(
                            trabajador: trabajador,
                            capacidadesRequeridas: _tarea?.capacidadesRequeridas ?? [],
                            onAssign: () {
                              Navigator.pop(context);
                              _asignarTarea(trabajador.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TaskContactButton> _buildContactButtons() {
    final contacts = <TaskContactButton>[];

    if (_tarea == null) return contacts;

    // Creador de la tarea
    if (_tarea!.createdByUsuarioId.isNotEmpty) {
      contacts.add(TaskContactButton(
        name: _tarea!.createdByUsuarioNombre,
        role: 'Creó esta tarea',
        color: AppTheme.primaryBlue,
        isLoading: false,
        onTap: () => _chatWithUser(
          _tarea!.createdByUsuarioId,
          _tarea!.createdByUsuarioNombre,
        ),
      ));
    }

    // Trabajador asignado
    if (_tarea!.asignadoAUsuarioId != null && _tarea!.asignadoANombre != null) {
      contacts.add(TaskContactButton(
        name: _tarea!.asignadoANombre!,
        role: 'Trabajador asignado',
        color: Colors.teal,
        isLoading: false,
        onTap: () => _chatWithUser(
          _tarea!.asignadoAUsuarioId!,
          _tarea!.asignadoANombre!,
        ),
      ));
    }

    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Parent will receive true if changes were made
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          title: const Text(
            'Detalle de Tarea',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        body: _buildBody(isDark),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const TaskLoadingWidget(message: 'Cargando tarea...');
    }

    if (_tarea == null) {
      return TaskErrorWidget(
        message: 'No se pudo cargar la tarea',
        onRetry: _loadData,
      );
    }

    final contacts = _buildContactButtons();
    final showDelegacionPendiente = _tarea!.estaDelegada && 
        _tarea!.delegacionAceptada == null;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de delegación pendiente
            if (showDelegacionPendiente)
              _DelegacionPendienteBanner(
                isProcessing: _isProcessing,
                onAceptar: _aceptarDelegacion,
                onRechazar: _rechazarDelegacion,
              ),

            // Header con título y estado
            TaskDetailHeader(
              title: _tarea!.titulo,
              description: _tarea!.descripcion,
              statusBadge: TaskStatusBadge(
                estado: _tarea!.estado,
                showIcon: true,
              ),
            ),
            const SizedBox(height: 16),

            // Información de la Tarea
            TaskInfoSection(
              title: 'Detalles',
              items: [
                TaskInfoItem(
                  icon: Icons.flag_outlined,
                  label: 'Prioridad',
                  value: TaskHelpers.getPrioridadLabel(_tarea!.prioridad),
                  color: TaskHelpers.getPrioridadColor(_tarea!.prioridad),
                ),
                if (_tarea!.departamento != null)
                  TaskInfoItem(
                    icon: TaskHelpers.getDepartamentoIcon(_tarea!.departamento),
                    label: 'Departamento',
                    value: _tarea!.departamento!.label,
                    color: TaskHelpers.getDepartamentoColor(_tarea!.departamento),
                  ),
                if (_tarea!.dueDate != null)
                  TaskInfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha Límite',
                    value: TaskHelpers.getRelativeDueDate(_tarea!.dueDate),
                    color: TaskHelpers.isOverdue(_tarea!.dueDate)
                        ? AppTheme.dangerRed
                        : AppTheme.warningOrange,
                  ),
                if (_tarea!.asignadoANombre != null)
                  TaskInfoItem(
                    icon: Icons.assignment_ind_rounded,
                    label: 'Asignado a',
                    value: _tarea!.asignadoANombre!,
                    color: Colors.teal,
                  ),
                if (_tarea!.estaDelegada)
                  TaskInfoItem(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Delegación',
                    value: _tarea!.delegacionAceptada == true
                        ? 'Aceptada'
                        : _tarea!.delegacionAceptada == false
                            ? 'Rechazada'
                            : 'Pendiente',
                    color: _tarea!.delegacionAceptada == true
                        ? AppTheme.successGreen
                        : _tarea!.delegacionAceptada == false
                            ? AppTheme.dangerRed
                            : AppTheme.warningOrange,
                  ),
              ],
            ),

            // Capacidades Requeridas
            if (_tarea!.capacidadesRequeridas.isNotEmpty) ...[
              const SizedBox(height: 16),
              TaskSkillsSection(
                skills: _tarea!.capacidadesRequeridas,
                color: AppTheme.primaryBlue,
              ),
            ],

            // Documentos Adjuntos
            const SizedBox(height: 16),
            TaskDocumentosWidget(
              tareaId: widget.tareaId,
              showTitle: true,
              canDelete: false, // Manager no puede eliminar documentos
            ),

            // Evidencias (cuando la tarea está aceptada o finalizada)
            if (_tarea!.estado == EstadoTarea.aceptada || 
                _tarea!.estado == EstadoTarea.finalizada) ...[
              const SizedBox(height: 16),
              TaskEvidenciasWidget(
                tareaId: widget.tareaId,
                showTitle: true,
                canDelete: false,
              ),
            ],

            // Banner de rechazo si aplica
            if (_tarea!.delegacionAceptada == false && 
                _tarea!.motivoRechazoJefe != null) ...[
              const SizedBox(height: 16),
              TaskRejectionBanner(
                reason: _tarea!.motivoRechazoJefe!,
              ),
            ],

            // Sección de Contactos
            if (contacts.isNotEmpty) ...[
              const SizedBox(height: 16),
              TaskContactsSection(
                title: 'Comunicación',
                contacts: contacts,
              ),
            ],

            // Botones de acción
            const SizedBox(height: 24),
            _buildActionButtons(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = <Widget>[];
    
    // Verificar si la tarea está asignada al manager actual
    final bool isMiTarea = _tarea!.asignadoAUsuarioId == _currentUserId;

    // =========================================
    // CASO 1: Tarea asignada al manager mismo
    // =========================================
    if (isMiTarea) {
      // Si está ASIGNADA al manager -> puede Aceptar o Reasignar
      if (_tarea!.estado.value == 1) { // asignada
        actions.add(
          TaskActionButton(
            label: 'Aceptar Tarea',
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.successGreen,
            isLoading: _isProcessing,
            onPressed: _aceptarTareaPropia,
          ),
        );

        actions.add(const SizedBox(height: 12));

        actions.add(
          TaskActionButton(
            label: 'Delegar / Reasignar',
            icon: Icons.swap_horiz_rounded,
            color: AppTheme.warningOrange,
            isLoading: _isProcessing,
            isOutlined: true,
            onPressed: _reasignarAWorker,
          ),
        );
      }
      // Si está ACEPTADA por el manager -> puede Finalizar o Reasignar
      else if (_tarea!.estado.value == 2) { // aceptada
        actions.add(
          TaskActionButton(
            label: 'Finalizar Tarea',
            icon: Icons.task_alt_rounded,
            color: AppTheme.successGreen,
            isLoading: _isProcessing,
            onPressed: _finalizarTareaPropia,
          ),
        );

        actions.add(const SizedBox(height: 12));

        actions.add(
          TaskActionButton(
            label: 'Reasignar',
            icon: Icons.swap_horiz_rounded,
            color: AppTheme.primaryBlue,
            isLoading: _isProcessing,
            isOutlined: true,
            onPressed: _reasignarAWorker,
          ),
        );
      }
    }
    // =========================================
    // CASO 2: Tarea pendiente sin asignar
    // =========================================
    else if (_tarea!.estado.value == 0 && !_tarea!.estaDelegada) {
      actions.add(
        TaskActionButton(
          label: 'Asignar Trabajador',
          icon: Icons.person_add_rounded,
          color: AppTheme.primaryBlue,
          isLoading: _isProcessing,
          onPressed: _mostrarDialogoAsignar,
        ),
      );

      actions.add(const SizedBox(height: 12));

      actions.add(
        TaskActionButton(
          label: 'Delegar a otro Jefe',
          icon: Icons.swap_horiz_rounded,
          color: AppTheme.warningOrange,
          isLoading: _isProcessing,
          isOutlined: true,
          onPressed: _delegarTarea,
        ),
      );
    }
    // =========================================
    // CASO 3: Delegación aceptada - puede asignar
    // =========================================
    else if (_tarea!.estaDelegada && _tarea!.delegacionAceptada == true) {
      if (_tarea!.estado.value == 0) { // pendiente
        actions.add(
          TaskActionButton(
            label: 'Asignar Trabajador',
            icon: Icons.person_add_rounded,
            color: Colors.teal,
            isLoading: _isProcessing,
            onPressed: _mostrarDialogoAsignar,
          ),
        );
      }
    }

    // Si no hay acciones disponibles
    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black45,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getNoActionsMessage(),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: actions);
  }

  String _getNoActionsMessage() {
    if (_tarea!.estado.value == 3) { // finalizada
      return 'Esta tarea ha sido completada';
    }
    if (_tarea!.estado.value == 4) { // cancelada
      return 'Esta tarea fue cancelada';
    }
    if (_tarea!.estado.value == 2) { // aceptada
      return 'El trabajador está realizando esta tarea';
    }
    if (_tarea!.estado.value == 1) { // asignada
      return 'Esperando confirmación del trabajador';
    }
    if (_tarea!.estaDelegada && _tarea!.delegacionAceptada == null) {
      return 'Esperando respuesta del jefe asignado';
    }
    if (_tarea!.estaDelegada && _tarea!.delegacionAceptada == false) {
      return 'La delegación fue rechazada';
    }
    return 'No hay acciones disponibles';
  }
}

// Banner para delegación pendiente
class _DelegacionPendienteBanner extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const _DelegacionPendienteBanner({
    required this.isProcessing,
    required this.onAceptar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningOrange.withOpacity(0.2),
            AppTheme.warningOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delegación Pendiente',
                      style: TextStyle(
                        color: AppTheme.warningOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Esta tarea te fue delegada',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onRechazar,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.dangerRed,
                    side: const BorderSide(color: AppTheme.dangerRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : onAceptar,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Aceptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Item de lista de trabajadores
class _WorkerListItem extends StatelessWidget {
  final Usuario trabajador;
  final List<String> capacidadesRequeridas;
  final VoidCallback onAssign;

  const _WorkerListItem({
    required this.trabajador,
    required this.capacidadesRequeridas,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAssign,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.teal, Colors.tealAccent],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      trabajador.nombreCompleto.isNotEmpty
                          ? trabajador.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trabajador.nombreCompleto,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (trabajador.capacidades.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: trabajador.capacidades.take(3).map((cap) {
                            final isRequired = capacidadesRequeridas
                                .map((c) => c.toLowerCase())
                                .contains(cap.nombre.toLowerCase());
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isRequired
                                    ? AppTheme.successGreen.withOpacity(0.2)
                                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(8),
                                border: isRequired
                                    ? Border.all(color: AppTheme.successGreen.withOpacity(0.5))
                                    : null,
                              ),
                              child: Text(
                                cap.nombre,
                                style: TextStyle(
                                  color: isRequired
                                      ? AppTheme.successGreen
                                      : (isDark ? Colors.white70 : Colors.black54),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Item de lista de jefes para delegar
class _JefeListItem extends StatelessWidget {
  final String nombre;
  final String? departamento;
  final VoidCallback onSelect;

  const _JefeListItem({
    required this.nombre,
    this.departamento,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warningOrange,
                        AppTheme.warningOrange.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (departamento != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          departamento!,
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
