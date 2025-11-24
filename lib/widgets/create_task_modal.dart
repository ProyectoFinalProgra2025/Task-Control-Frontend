import 'package:flutter/material.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';
import '../models/enums/prioridad_tarea.dart';
import '../models/enums/departamento.dart';
import '../services/tarea_service.dart';
import '../services/usuario_service.dart';
import '../config/capacidades.dart';

class CreateTaskModal extends StatefulWidget {
  const CreateTaskModal({super.key});

  @override
  State<CreateTaskModal> createState() => _CreateTaskModalState();
}

enum AsignacionMode { ninguna, automatica, manual }

class _CreateTaskModalState extends State<CreateTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TareaService _tareaService = TareaService();
  final UsuarioService _usuarioService = UsuarioService();
  
  PrioridadTarea _selectedPriority = PrioridadTarea.medium;
  Departamento? _selectedDepartment;
  DateTime? _dueDate;
  List<String> _selectedCapacidades = [];
  AsignacionMode _asignacionMode = AsignacionMode.ninguna;
  Usuario? _usuarioSeleccionado;
  bool _isLoading = false;

  @override
  void dispose() {
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _showCapacidadesSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CapacidadesSelectorSheet(
        selectedCapacidades: _selectedCapacidades,
        onCapacidadesChanged: (capacidades) {
          setState(() => _selectedCapacidades = capacidades);
        },
      ),
    );
  }

  Future<void> _selectUsuarioManual() async {
    try {
      // Cargar lista de usuarios
      final usuarios = await _usuarioService.getUsuarios();
      
      if (!mounted) return;
      
      // Filtrar trabajadores y managers activos
      final trabajadores = usuarios
          .where((u) => (u.rol == 'Usuario' || u.rol == 'ManagerDepartamento') && u.isActive)
          .toList();
      
      if (trabajadores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay trabajadores disponibles'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }
      
      // Mostrar diálogo de selección
      final usuario = await showDialog<Usuario>(
        context: context,
        builder: (context) => _UsuarioSelectionDialog(usuarios: trabajadores),
      );
      
      if (usuario != null) {
        setState(() {
          _usuarioSeleccionado = usuario;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar usuarios: ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _submitTask() async {
    if (_formKey.currentState!.validate()) {
      // Validar selección manual
      if (_asignacionMode == AsignacionMode.manual && _usuarioSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione un trabajador para la asignación manual'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final dto = CreateTareaDTO(
          titulo: _taskNameController.text.trim(),
          descripcion: _descriptionController.text.trim(),
          prioridad: _selectedPriority,
          dueDate: _dueDate,
          departamento: _selectedDepartment,
          capacidadesRequeridas: _selectedCapacidades,
        );

        final tareaId = await _tareaService.createTarea(dto);

        // Ejecutar asignación según el modo seleccionado
        if (_asignacionMode == AsignacionMode.automatica) {
          await _tareaService.asignarAutomatico(tareaId);
        } else if (_asignacionMode == AsignacionMode.manual && _usuarioSeleccionado != null) {
          final asignarDto = AsignarManualTareaDTO(
            usuarioId: _usuarioSeleccionado!.id,
          );
          await _tareaService.asignarManual(tareaId, asignarDto);
        }

        if (!mounted) return;

        String mensaje = 'Tarea creada exitosamente';
        if (_asignacionMode == AsignacionMode.automatica) {
          mensaje = 'Tarea creada y asignada automáticamente';
        } else if (_asignacionMode == AsignacionMode.manual) {
          mensaje = 'Tarea creada y asignada a ${_usuarioSeleccionado!.nombreCompleto}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'Crear Nueva Tarea',
                        textAlign: TextAlign.center,
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
              ),

              // Form Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Task Name
                      Text(
                        'Título de la Tarea *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _taskNameController,
                        decoration: InputDecoration(
                          hintText: 'Ingrese el título de la tarea',
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF005A9C),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un título';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Priority
                      Text(
                        'Prioridad *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<PrioridadTarea>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        items: PrioridadTarea.values
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPriority = value);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // Department
                      Text(
                        'Departamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Departamento>(
                        value: _selectedDepartment,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        hint: const Text('Seleccione un departamento'),
                        items: Departamento.principales
                            .map((dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept.label),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedDepartment = value),
                      ),

                      const SizedBox(height: 20),

                      // Due Date
                      Text(
                        'Fecha de Vencimiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDueDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                _dueDate == null
                                    ? 'Seleccionar fecha'
                                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _dueDate == null ? textSecondary : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Capacidades Requeridas
                      Text(
                        'Capacidades Requeridas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showCapacidadesSelector,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.psychology, color: textSecondary),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedCapacidades.isEmpty
                                        ? 'Seleccionar capacidades'
                                        : '${_selectedCapacidades.length} capacidad(es) seleccionada(s)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedCapacidades.isEmpty
                                          ? textSecondary
                                          : textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.chevron_right, color: textSecondary),
                                ],
                              ),
                              if (_selectedCapacidades.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedCapacidades
                                      .map((cap) => Chip(
                                            label: Text(
                                              cap,
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            backgroundColor:
                                                const Color(0xFF005A9C).withOpacity(0.1),
                                            deleteIcon: const Icon(Icons.close, size: 16),
                                            onDeleted: () {
                                              setState(() {
                                                _selectedCapacidades.remove(cap);
                                              });
                                            },
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Descripción *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Ingrese la descripción de la tarea...',
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF005A9C),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una descripción';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Modo de Asignación
                      Text(
                        'Asignación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Sin asignación
                      InkWell(
                        onTap: () => setState(() => _asignacionMode = AsignacionMode.ninguna),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _asignacionMode == AsignacionMode.ninguna
                                ? const Color(0xFF005A9C).withOpacity(0.1)
                                : cardColor,
                            border: Border.all(
                              color: _asignacionMode == AsignacionMode.ninguna
                                  ? const Color(0xFF005A9C)
                                  : borderColor,
                              width: _asignacionMode == AsignacionMode.ninguna ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pending_actions,
                                color: _asignacionMode == AsignacionMode.ninguna
                                    ? const Color(0xFF005A9C)
                                    : textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sin Asignación',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Asignar más tarde',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_asignacionMode == AsignacionMode.ninguna)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF005A9C),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Asignación Automática
                      InkWell(
                        onTap: () => setState(() => _asignacionMode = AsignacionMode.automatica),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _asignacionMode == AsignacionMode.automatica
                                ? const Color(0xFF005A9C).withOpacity(0.1)
                                : cardColor,
                            border: Border.all(
                              color: _asignacionMode == AsignacionMode.automatica
                                  ? const Color(0xFF005A9C)
                                  : borderColor,
                              width: _asignacionMode == AsignacionMode.automatica ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_fix_high,
                                color: _asignacionMode == AsignacionMode.automatica
                                    ? const Color(0xFF005A9C)
                                    : textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Asignación Automática',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'El sistema seleccionará al mejor candidato',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_asignacionMode == AsignacionMode.automatica)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF005A9C),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Asignación Manual
                      InkWell(
                        onTap: () {
                          setState(() => _asignacionMode = AsignacionMode.manual);
                          if (_usuarioSeleccionado == null) {
                            _selectUsuarioManual();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _asignacionMode == AsignacionMode.manual
                                ? const Color(0xFF005A9C).withOpacity(0.1)
                                : cardColor,
                            border: Border.all(
                              color: _asignacionMode == AsignacionMode.manual
                                  ? const Color(0xFF005A9C)
                                  : borderColor,
                              width: _asignacionMode == AsignacionMode.manual ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_add,
                                    color: _asignacionMode == AsignacionMode.manual
                                        ? const Color(0xFF005A9C)
                                        : textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Asignación Manual',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          _usuarioSeleccionado == null
                                              ? 'Seleccionar trabajador'
                                              : _usuarioSeleccionado!.nombreCompleto,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_asignacionMode == AsignacionMode.manual)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF005A9C),
                                    ),
                                ],
                              ),
                              if (_asignacionMode == AsignacionMode.manual && _usuarioSeleccionado != null) ...[
                                const SizedBox(height: 12),
                                Divider(color: borderColor),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF005A9C),
                                      child: Text(
                                        _usuarioSeleccionado!.nombreCompleto[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _usuarioSeleccionado!.nombreCompleto,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _usuarioSeleccionado!.email,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _selectUsuarioManual,
                                      child: const Text('Cambiar'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005A9C),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Crear Tarea',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget separado para el selector de capacidades
class _CapacidadesSelectorSheet extends StatefulWidget {
  final List<String> selectedCapacidades;
  final Function(List<String>) onCapacidadesChanged;

  const _CapacidadesSelectorSheet({
    required this.selectedCapacidades,
    required this.onCapacidadesChanged,
  });

  @override
  State<_CapacidadesSelectorSheet> createState() =>
      _CapacidadesSelectorSheetState();
}

class _CapacidadesSelectorSheetState extends State<_CapacidadesSelectorSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedCapacidades);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101622) : const Color(0xFFF4F6F8);
    final cardColor = isDark ? const Color(0xFF192233) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF4F6F8) : const Color(0xFF212529);
    final textSecondary = isDark ? const Color(0xFF92a4c9) : const Color(0xFF6C757D);
    final borderColor = isDark ? const Color(0xFF324467) : const Color(0xFFE0E0E0);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Seleccionar Capacidades',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onCapacidadesChanged(_tempSelected);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ),

              // List of capacidades
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...Capacidades.porCategoria.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          ...entry.value.map((capacidad) {
                            final isSelected = _tempSelected.contains(capacidad);
                            return CheckboxListTile(
                              title: Text(
                                capacidad,
                                style: TextStyle(color: textPrimary),
                              ),
                              value: isSelected,
                              activeColor: const Color(0xFF005A9C),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _tempSelected.add(capacidad);
                                  } else {
                                    _tempSelected.remove(capacidad);
                                  }
                                });
                              },
                              tileColor: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: borderColor),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget para seleccionar usuario en asignación manual
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

            // Botones
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
                        'Seleccionar',
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
