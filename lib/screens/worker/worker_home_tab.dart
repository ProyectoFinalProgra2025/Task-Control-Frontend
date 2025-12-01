import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/task_progress_indicator.dart';
import '../../widgets/premium_widgets.dart';
import '../../widgets/finish_task_dialog.dart';
import '../../widgets/task_evidencias_widget.dart';
import '../../widgets/calendar/task_calendar_widget.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/usuario_provider.dart';
import '../../models/tarea.dart';
import '../../models/enums/estado_tarea.dart';
import '../../config/theme_config.dart';
import '../../mixins/tarea_realtime_mixin.dart';
import '../../services/tarea_realtime_service.dart';
import '../../services/chat_service.dart';
import '../../services/file_upload_service.dart';
import '../chat/chat_detail_screen.dart';
import 'worker_tasks_list_screen.dart';
import 'worker_task_detail_screen.dart';

class WorkerHomeTab extends StatefulWidget {
  const WorkerHomeTab({super.key});

  @override
  State<WorkerHomeTab> createState() => _WorkerHomeTabState();
}

class _WorkerHomeTabState extends State<WorkerHomeTab> with TareaRealtimeMixin {
  @override
  void initState() {
    super.initState();
    initRealtime(); // Conectar realtime
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  @override
  void dispose() {
    disposeRealtime();
    super.dispose();
  }

  @override
  void onTareaEvent(TareaEvent event) {
    // Cuando llega un evento de tarea, refrescar silenciosamente
    if (event.isTareaEvent && mounted) {
      final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
      tareaProvider.silentRefresh();
    }
  }

  Future<void> _loadData() async {
    final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    await Future.wait([
      tareaProvider.cargarMisTareas(),
      usuarioProvider.cargarPerfil(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Consumer2<TareaProvider, UsuarioProvider>(
        builder: (context, tareaProvider, usuarioProvider, child) {
          if (tareaProvider.isLoading || usuarioProvider.isLoading) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          final tareasPendientes = tareaProvider.tareasPendientes.length;
          final tareaActiva = tareaProvider.tareaActiva ??
              (tareaProvider.tareasPendientes.isNotEmpty ? tareaProvider.tareasPendientes.first : null);
          final nombreUsuario = usuarioProvider.usuario?.nombreCompleto ?? 'Worker';
          final firstName = nombreUsuario.split(' ').first;
          final userInitials = _getInitials(nombreUsuario);
          // Todas las tareas del worker para el calendario
          final misTareas = tareaProvider.misTareas;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        border: Border(bottom: BorderSide(color: isDark ? AppTheme.darkBorder.withOpacity(0.3) : AppTheme.lightBorder, width: 1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [AppTheme.primaryBlue, Color(0xFF8B5CF6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          userInitials,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hola, $firstName',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Worker',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primaryBlue,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              RealtimeConnectionIndicator(
                                                isConnected: isRealtimeConnected,
                                                onReconnect: reconnectRealtime,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const ThemeToggleButton(),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Pendientes',
                              value: '$tareasPendientes',
                              icon: Icons.assignment_outlined,
                              color: AppTheme.primaryBlue,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildViewAllTasksCard(isDark: isDark),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.assignment_outlined,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tarea Activa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Task Card or Empty State
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: tareaActiva != null
                          ? _buildTaskCard(tarea: tareaActiva, isDark: isDark)
                          : _buildPremiumEmptyState(isDark: isDark),
                    ),

                    // Mi Calendario de Tareas
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TaskCalendarWidget(
                        tareas: misTareas,
                        title: 'Mi Calendario',
                        primaryColor: AppTheme.primaryBlue,
                        isLoading: tareaProvider.isLoading,
                        onTaskTap: (tarea) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkerTaskDetailScreen(tareaId: tarea.id),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getInitials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.isEmpty) return 'W';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildViewAllTasksCard({required bool isDark}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WorkerTasksListScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [Color(0xFF192233), Color(0xFF1a2942)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Color(0xFFEC4899).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ver Todas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '→',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({required Tarea tarea, required bool isDark}) {
    Color getEstadoColor(EstadoTarea estado) {
      switch (estado) {
        case EstadoTarea.asignada:
          return AppTheme.primaryBlue;
        case EstadoTarea.aceptada:
          return const Color(0xFFF59E0B);
        case EstadoTarea.finalizada:
          return AppTheme.successGreen;
        case EstadoTarea.cancelada:
          return const Color(0xFFEF4444);
        case EstadoTarea.pendiente:
          return Colors.grey;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerTaskDetailScreen(tareaId: tarea.id),
          ),
        );
      },
      child: PremiumCard(
        isDark: isDark,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    tarea.titulo,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        getEstadoColor(tarea.estado),
                        getEstadoColor(tarea.estado).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: getEstadoColor(tarea.estado).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tarea.estado.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              tarea.descripcion,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 20),

            // Task Progress Indicator
            TaskProgressIndicator(
              estadoActual: tarea.estado,
              primaryColor: AppTheme.primaryBlue,
              showLabels: true,
              height: 70,
            ),

            const SizedBox(height: 20),

            // Task Info
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tag, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '#${tarea.id}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                if (tarea.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '${tarea.dueDate!.day}/${tarea.dueDate!.month}/${tarea.dueDate!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (tarea.createdByUsuarioNombre.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Creado por: ${tarea.createdByUsuarioNombre}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Sección de evidencias (solo si la tarea está aceptada o finalizada)
            if (tarea.estado == EstadoTarea.aceptada || tarea.estado == EstadoTarea.finalizada)
              TaskEvidenciasWidget(
                tareaId: tarea.id,
                showTitle: true,
                canDelete: tarea.estado == EstadoTarea.aceptada, // Solo puede eliminar si no está finalizada
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    text: 'Chat',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => _openChatWithCreator(tarea),
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                // Show Aceptar if asignada, Finalizar if aceptada
                if (tarea.estado == EstadoTarea.asignada)
                  Expanded(
                    flex: 2,
                    child: PremiumButton(
                      text: 'Aceptar',
                      icon: Icons.play_circle_outline,
                      onPressed: () => _showAcceptTaskDialog(tarea),
                      gradientColors: const [AppTheme.primaryBlue, Color(0xFF8B5CF6)],
                    ),
                  )
                else if (tarea.estado == EstadoTarea.aceptada)
                  Expanded(
                    flex: 2,
                    child: PremiumButton(
                      text: 'Finalizar',
                      icon: Icons.check_circle_outline,
                      onPressed: () => _showFinishTaskDialog(tarea),
                      gradientColors: const [AppTheme.successGreen, AppTheme.successGreen],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChatWithCreator(Tarea tarea) async {
    if (tarea.createdByUsuarioId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se puede identificar al creador de la tarea'),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Obtener el ID del usuario actual
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    final currentUserId = usuarioProvider.usuario?.id;
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: No se pudo obtener tu información de usuario'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(
                'Abriendo chat con ${tarea.createdByUsuarioNombre}...',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final chatService = ChatService();
      
      // Crear o obtener conversación directa
      final conversationId = await chatService.getOrCreateDirectConversation(tarea.createdByUsuarioId);
      
      if (conversationId == null) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo iniciar el chat'),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Obtener la conversación completa
      final conversation = await chatService.getConversation(conversationId);
      
      Navigator.pop(context); // Cerrar loading
      
      if (conversation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo cargar la conversación'),
            backgroundColor: AppTheme.dangerRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Navegar al chat
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversation: conversation,
            currentUserId: currentUserId,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir chat: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPremiumEmptyState({required bool isDark}) {
    return PremiumEmptyState(
      icon: Icons.assignment_outlined,
      title: 'Sin Tareas Activas',
      subtitle: 'No tienes tareas asignadas en este momento.',
      isDark: isDark,
    );
  }

  void _showFinishTaskDialog(Tarea tarea) {
    final fileUploadService = FileUploadService();
    
    FinishTaskDialog.show(
      context,
      tarea: tarea,
      onFinish: (descripcion, archivos) async {
        final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
        
        // Primero subir las evidencias con archivos si hay
        for (final archivo in archivos) {
          try {
            await fileUploadService.uploadEvidenciaTarea(
              tarea.id,
              descripcion: archivos.indexOf(archivo) == 0 ? descripcion : null,
              file: archivo,
            );
          } catch (e) {
            print('Error subiendo evidencia: $e');
          }
        }
        
        // Si solo hay descripción sin archivos, subirla como evidencia de texto
        if (archivos.isEmpty && descripcion != null && descripcion.isNotEmpty) {
          try {
            await fileUploadService.uploadEvidenciaTarea(
              tarea.id,
              descripcion: descripcion,
            );
          } catch (e) {
            print('Error subiendo evidencia de texto: $e');
          }
        }
        
        // Finalizar la tarea
        final dto = FinalizarTareaDTO(
          evidenciaTexto: descripcion,
        );
        
        final success = await tareaProvider.finalizarTarea(tarea.id, dto);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('¡Tarea finalizada exitosamente!'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          await tareaProvider.cargarMisTareas();
        } else if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tareaProvider.error ?? 'Error al finalizar tarea'),
              backgroundColor: AppTheme.dangerRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        
        return success;
      },
    );
  }

  void _showAcceptTaskDialog(Tarea tarea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar Tarea'),
        content: Text('¿Deseas aceptar la tarea "${tarea.titulo}"?\n\nAl aceptar, comenzarás a trabajar en esta tarea.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final tareaProvider = Provider.of<TareaProvider>(context, listen: false);
              final success = await tareaProvider.aceptarTarea(tarea.id);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Tarea aceptada! Ahora puedes comenzar a trabajar.'),
                    backgroundColor: Colors.green,
                  ),
                );
                await tareaProvider.cargarMisTareas();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tareaProvider.error ?? 'Error al aceptar tarea'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
