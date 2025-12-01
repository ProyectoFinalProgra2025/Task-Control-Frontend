import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';
import '../models/enums/prioridad_tarea.dart';
import '../models/enums/departamento.dart';
import '../services/tarea_service.dart';
import '../services/usuario_service.dart';
import '../services/file_upload_service.dart';
import '../config/capacidades.dart';
import 'file_attachment_widget.dart';

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
  final FileUploadService _fileUploadService = FileUploadService();
  
  PrioridadTarea _selectedPriority = PrioridadTarea.medium;
  Departamento? _selectedDepartment;
  DateTime? _dueDate;
  List<String> _selectedCapacidades = [];
  AsignacionMode _asignacionMode = AsignacionMode.ninguna;
  Usuario? _usuarioSeleccionado;
  bool _isLoading = false;
  
  // Archivos adjuntos
  List<PlatformFile> _attachedFiles = [];

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

        // Subir archivos adjuntos si hay
        if (_attachedFiles.isNotEmpty) {
          for (final file in _attachedFiles) {
            try {
              await _fileUploadService.uploadDocumentoTarea(tareaId, file);
            } catch (e) {
              print('Error subiendo archivo ${file.name}: $e');
              // Continuar con los demás archivos
            }
          }
        }

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
        if (_attachedFiles.isNotEmpty) {
          mensaje += ' con ${_attachedFiles.length} archivo(s) adjunto(s)';
        }
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
              // Header moderno con gradiente
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Crear Nueva Tarea',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.title_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Título de la Tarea',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _taskNameController,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'Ej: Revisar inventario mensual',
                          hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A6CFF),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un título';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Priority
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Prioridad',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PrioridadTarea>(
                        value: _selectedPriority,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                        dropdownColor: cardColor,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0A6CFF), width: 2),
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

                      const SizedBox(height: 24),

                      // Department
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Departamento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Departamento>(
                        value: _selectedDepartment,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                        dropdownColor: cardColor,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0A6CFF), width: 2),
                          ),
                        ),
                        hint: Text('Seleccione un departamento', style: TextStyle(color: textSecondary.withOpacity(0.6))),
                        items: Departamento.principales
                            .map((dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept.label),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedDepartment = value),
                      ),

                      const SizedBox(height: 24),

                      // Due Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fecha de Vencimiento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDueDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            border: Border.all(color: borderColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dueDate == null
                                      ? 'Seleccionar fecha de vencimiento'
                                      : DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_dueDate!),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: _dueDate == null ? FontWeight.w400 : FontWeight.w600,
                                    color: _dueDate == null ? textSecondary.withOpacity(0.6) : textPrimary,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Capacidades Requeridas
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Capacidades Requeridas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showCapacidadesSelector,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            border: Border.all(color: borderColor.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.psychology_rounded, color: Color(0xFFEF4444), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedCapacidades.isEmpty
                                          ? 'Seleccionar habilidades requeridas'
                                          : '${_selectedCapacidades.length} habilidad(es) seleccionada(s)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: _selectedCapacidades.isEmpty ? FontWeight.w400 : FontWeight.w600,
                                        color: _selectedCapacidades.isEmpty
                                            ? textSecondary.withOpacity(0.6)
                                            : textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
                                ],
                              ),
                              if (_selectedCapacidades.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _selectedCapacidades
                                      .map((cap) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFEF4444), Color(0xFFF97316)],
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  cap,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedCapacidades.remove(cap);
                                                    });
                                                  },
                                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'Describe los detalles de la tarea, objetivos y requisitos especiales...',
                          hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                          filled: true,
                          fillColor: cardColor,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF0A6CFF),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
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

                      // Archivos Adjuntos
                      FileAttachmentWidget(
                        selectedFiles: _attachedFiles,
                        onFilesChanged: (files) {
                          setState(() => _attachedFiles = files);
                        },
                        title: 'Archivos Adjuntos',
                        hint: 'Adjuntar documentos de referencia (PDF, Excel, imágenes)',
                        maxFiles: 5,
                      ),

                      const SizedBox(height: 28),

                      // Modo de Asignación
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Modo de Asignación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      
                      // Sin asignación
                      InkWell(
                        onTap: () => setState(() => _asignacionMode = AsignacionMode.ninguna),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: _asignacionMode == AsignacionMode.ninguna
                                ? const LinearGradient(
                                    colors: [Color(0xFF0A6CFF), Color(0xFF11C3FF)],
                                  )
                                : null,
                            color: _asignacionMode == AsignacionMode.ninguna ? null : cardColor,
                            border: Border.all(
                              color: _asignacionMode == AsignacionMode.ninguna
                                  ? Colors.transparent
                                  : borderColor.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _asignacionMode == AsignacionMode.ninguna
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0A6CFF).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _asignacionMode == AsignacionMode.ninguna
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFF6B7280).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.schedule_rounded,
                                  color: _asignacionMode == AsignacionMode.ninguna
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sin Asignación',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _asignacionMode == AsignacionMode.ninguna
                                            ? Colors.white
                                            : textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Asignar manualmente después',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _asignacionMode == AsignacionMode.ninguna
                                            ? Colors.white.withOpacity(0.8)
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_asignacionMode == AsignacionMode.ninguna)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Asignación Automática
                      InkWell(
                        onTap: () => setState(() => _asignacionMode = AsignacionMode.automatica),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: _asignacionMode == AsignacionMode.automatica
                                ? const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                  )
                                : null,
                            color: _asignacionMode == AsignacionMode.automatica ? null : cardColor,
                            border: Border.all(
                              color: _asignacionMode == AsignacionMode.automatica
                                  ? Colors.transparent
                                  : borderColor.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _asignacionMode == AsignacionMode.automatica
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _asignacionMode == AsignacionMode.automatica
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: _asignacionMode == AsignacionMode.automatica
                                      ? Colors.white
                                      : const Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Asignación Automática',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _asignacionMode == AsignacionMode.automatica
                                            ? Colors.white
                                            : textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'IA selecciona al mejor candidato',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _asignacionMode == AsignacionMode.automatica
                                            ? Colors.white.withOpacity(0.8)
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_asignacionMode == AsignacionMode.automatica)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 24,
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
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: _asignacionMode == AsignacionMode.manual
                                ? const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  )
                                : null,
                            color: _asignacionMode == AsignacionMode.manual ? null : cardColor,
                            border: Border.all(
                              color: _asignacionMode == AsignacionMode.manual
                                  ? Colors.transparent
                                  : borderColor.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _asignacionMode == AsignacionMode.manual
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _asignacionMode == AsignacionMode.manual
                                          ? Colors.white.withOpacity(0.2)
                                          : const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.person_add_alt_rounded,
                                      color: _asignacionMode == AsignacionMode.manual
                                          ? Colors.white
                                          : const Color(0xFF10B981),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Asignación Manual',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: _asignacionMode == AsignacionMode.manual
                                                ? Colors.white
                                                : textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _usuarioSeleccionado == null
                                              ? 'Elegir trabajador específico'
                                              : _usuarioSeleccionado!.nombreCompleto,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _asignacionMode == AsignacionMode.manual
                                                ? Colors.white.withOpacity(0.8)
                                                : textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_asignacionMode == AsignacionMode.manual)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                ],
                              ),
                              if (_asignacionMode == AsignacionMode.manual && _usuarioSeleccionado != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _usuarioSeleccionado!.nombreCompleto[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
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
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _usuarioSeleccionado!.email,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _selectUsuarioManual,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cambiar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button moderno con gradiente
                      Container(
                        decoration: BoxDecoration(
                          gradient: _isLoading
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading ? Colors.grey[600] : Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.check_rounded, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Crear Tarea',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
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
