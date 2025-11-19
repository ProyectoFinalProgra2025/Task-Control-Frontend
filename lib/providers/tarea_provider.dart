import 'package:flutter/foundation.dart';
import '../models/tarea.dart';
import '../models/enums/estado_tarea.dart';
import '../models/enums/prioridad_tarea.dart';
import '../models/enums/departamento.dart';
import '../services/tarea_service.dart';

class TareaProvider extends ChangeNotifier {
  final TareaService _tareaService = TareaService();

  List<Tarea> _misTareas = [];
  bool _isLoading = false;
  String? _error;

  List<Tarea> get misTareas => _misTareas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener tareas pendientes
  List<Tarea> get tareasPendientes =>
      _misTareas.where((t) => t.estado == EstadoTarea.asignada).toList();

  // Obtener tareas aceptadas (en progreso)
  List<Tarea> get tareasEnProgreso =>
      _misTareas.where((t) => t.estado == EstadoTarea.aceptada).toList();

  // Obtener tareas finalizadas
  List<Tarea> get tareasFinalizadas =>
      _misTareas.where((t) => t.estado == EstadoTarea.finalizada).toList();

  // Obtener tarea activa (la primera aceptada)
  Tarea? get tareaActiva {
    final enProgreso = tareasEnProgreso;
    return enProgreso.isNotEmpty ? enProgreso.first : null;
  }

  /// Cargar mis tareas desde el backend
  Future<void> cargarMisTareas({
    EstadoTarea? estado,
    PrioridadTarea? prioridad,
    Departamento? departamento,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _misTareas = await _tareaService.getMisTareas(
        estado: estado,
        prioridad: prioridad,
        departamento: departamento,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _misTareas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener detalle de una tarea específica
  Future<Tarea?> obtenerTareaDetalle(int tareaId) async {
    try {
      return await _tareaService.getTareaById(tareaId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Aceptar una tarea
  Future<bool> aceptarTarea(int tareaId) async {
    try {
      await _tareaService.aceptarTarea(tareaId);
      // Actualizar la tarea localmente
      final index = _misTareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        _misTareas[index] = Tarea(
          id: _misTareas[index].id,
          titulo: _misTareas[index].titulo,
          descripcion: _misTareas[index].descripcion,
          prioridad: _misTareas[index].prioridad,
          estado: EstadoTarea.aceptada,
          departamento: _misTareas[index].departamento,
          dueDate: _misTareas[index].dueDate,
          empresaId: _misTareas[index].empresaId,
          asignadoA: _misTareas[index].asignadoA,
          asignadoANombre: _misTareas[index].asignadoANombre,
          creadoPor: _misTareas[index].creadoPor,
          creadoPorNombre: _misTareas[index].creadoPorNombre,
          capacidadesRequeridas: _misTareas[index].capacidadesRequeridas,
          createdAt: _misTareas[index].createdAt,
          updatedAt: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Finalizar una tarea
  Future<bool> finalizarTarea(int tareaId, FinalizarTareaDTO dto) async {
    try {
      await _tareaService.finalizarTarea(tareaId, dto);
      // Actualizar la tarea localmente
      final index = _misTareas.indexWhere((t) => t.id == tareaId);
      if (index != -1) {
        _misTareas[index] = Tarea(
          id: _misTareas[index].id,
          titulo: _misTareas[index].titulo,
          descripcion: _misTareas[index].descripcion,
          prioridad: _misTareas[index].prioridad,
          estado: EstadoTarea.finalizada,
          departamento: _misTareas[index].departamento,
          dueDate: _misTareas[index].dueDate,
          empresaId: _misTareas[index].empresaId,
          asignadoA: _misTareas[index].asignadoA,
          asignadoANombre: _misTareas[index].asignadoANombre,
          creadoPor: _misTareas[index].creadoPor,
          creadoPorNombre: _misTareas[index].creadoPorNombre,
          capacidadesRequeridas: _misTareas[index].capacidadesRequeridas,
          createdAt: _misTareas[index].createdAt,
          updatedAt: DateTime.now(),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refrescar todas las tareas
  Future<void> refresh() async {
    await cargarMisTareas();
  }
}
