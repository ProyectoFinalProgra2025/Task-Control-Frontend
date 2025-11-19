import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';
import '../models/enums/estado_tarea.dart';
import '../models/enums/prioridad_tarea.dart';
import '../services/tarea_service.dart';
import '../services/usuario_service.dart';

class TareaDetailWidget extends StatefulWidget {
  final int tareaId;

  const TareaDetailWidget({super.key, required this.tareaId});

  @override
  State<TareaDetailWidget> createState() => _TareaDetailWidgetState();
}

class _TareaDetailWidgetState extends State<TareaDetailWidget> {
  final TareaService _tareaService = TareaService();
  final UsuarioService _usuarioService = UsuarioService();
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
    try {
      // Cargar lista de usuarios
      final usuarios = await _usuarioService.getUsuarios();
      
      if (!mounted) return;
      
      // Filtrar solo trabajadores activos
      final trabajadores = usuarios
          .where((u) => u.rol == 'Usuario' && u.isActive)
          .toList();
      
      if (trabajadores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay trabajadores disponibles para asignar'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }
      
      // Mostrar diálogo de selección
      final usuarioSeleccionado = await showDialog<Usuario>(
        context: context,
        builder: (context) => _UsuarioSelectionDialog(usuarios: trabajadores),
      );
      
      if (usuarioSeleccionado == null) return;
      
      // Asignar la tarea al usuario seleccionado
      final dto = AsignarManualTareaDTO(
        usuarioId: usuarioSeleccionado.id,
      );
      
      await _tareaService.asignarManual(widget.tareaId, dto);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea asignada a ${usuarioSeleccionado.nombreCompleto}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      
      _loadTarea(); // Recargar datos
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar tarea: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _asignarAutomatico() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignación Automática'),
        content: const Text(
          'El sistema asignará esta tarea al trabajador más adecuado '
          'según sus capacidades y carga de trabajo actual. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005A9C),
            ),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _tareaService.asignarAutomatico(widget.tareaId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea asignada automáticamente con éxito'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _loadTarea(); // Recargar datos
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar automáticamente: ${e.toString()}'),
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

// Diálogo para seleccionar un usuario
class _UsuarioSelectionDialog extends StatefulWidget {
  final List<Usuario> usuarios;

  const _UsuarioSelectionDialog({required this.usuarios});

  @override
  State<_UsuarioSelectionDialog> createState() => _UsuarioSelectionDialogState();
}

class _UsuarioSelectionDialogState extends State<_UsuarioSelectionDialog> {
  String _searchQuery = '';
  Usuario? _selectedUsuario;

  List<Usuario> get _filteredUsuarios {
    if (_searchQuery.isEmpty) return widget.usuarios;
    
    final query = _searchQuery.toLowerCase();
    return widget.usuarios.where((usuario) {
      return usuario.nombreCompleto.toLowerCase().contains(query) ||
          usuario.email.toLowerCase().contains(query) ||
          (usuario.departamento?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : Colors.white;
    final cardColor = isDark ? const Color(0xFF192233) : const Color(0xFFF4F6F8);
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor = isDark ? const Color(0xFF324467) : const Color(0xFFE0E0E0);

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_search, color: textPrimary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seleccionar Trabajador',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de búsqueda
                  TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o email...',
                      hintStyle: TextStyle(color: textSecondary),
                      prefixIcon: Icon(Icons.search, color: textSecondary),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lista de usuarios
            Expanded(
              child: _filteredUsuarios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron trabajadores',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredUsuarios.length,
                      itemBuilder: (context, index) {
                        final usuario = _filteredUsuarios[index];
                        final isSelected = _selectedUsuario?.id == usuario.id;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: isSelected
                              ? const Color(0xFF005A9C).withOpacity(0.1)
                              : cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF005A9C)
                                  : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                _selectedUsuario = usuario;
                              });
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF005A9C),
                              child: Text(
                                usuario.nombreCompleto[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              usuario.nombreCompleto,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  usuario.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                                if (usuario.departamento != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.business,
                                        size: 14,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        usuario.departamento!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (usuario.capacidades.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: usuario.capacidades
                                        .take(3)
                                        .map((cap) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF005A9C)
                                                    .withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${cap.nombre} (Nv.${cap.nivel})',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: const Color(0xFF005A9C),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF005A9C),
                                    size: 28,
                                  )
                                : Icon(
                                    Icons.radio_button_unchecked,
                                    color: textSecondary,
                                    size: 28,
                                  ),
                          ),
                        );
                      },
                    ),
            ),

            // Botón de asignar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(color: borderColor),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedUsuario == null
                          ? null
                          : () => Navigator.of(context).pop(_selectedUsuario),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005A9C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: textSecondary.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Asignar Tarea',
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
          ],
        ),
      ),
    );
  }
}
