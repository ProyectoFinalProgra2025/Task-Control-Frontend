import 'package:flutter/foundation.dart';
import '../models/tarea.dart';
import '../models/enums/estado_tarea.dart';
import '../models/enums/prioridad_tarea.dart';
import '../models/enums/departamento.dart';
import '../services/tarea_service.dart';

/// Provider específico para Admin/Manager que maneja TODAS las tareas de la empresa
class AdminTareaProvider extends ChangeNotifier {
  final TareaService _tareaService = TareaService();

  List<Tarea> _todasLasTareas = [];
  bool _isLoading = false;
  String? _error;

  List<Tarea> get todasLasTareas => _todasLasTareas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtros calculados
  List<Tarea> get tareasActivas =>
      _todasLasTareas.where((t) => t.estado == EstadoTarea.asignada || t.estado == EstadoTarea.aceptada).toList();

  List<Tarea> get tareasAsignadas =>
      _todasLasTareas.where((t) => t.estado == EstadoTarea.asignada).toList();

  List<Tarea> get tareasEnProgreso =>
      _todasLasTareas.where((t) => t.estado == EstadoTarea.aceptada).toList();

  List<Tarea> get tareasFinalizadas =>
      _todasLasTareas.where((t) => t.estado == EstadoTarea.finalizada).toList();

  List<Tarea> get tareasCanceladas =>
      _todasLasTareas.where((t) => t.estado == EstadoTarea.cancelada).toList();

  List<Tarea> get tareasDelegadas =>
      _todasLasTareas.where((t) => t.estaDelegada).toList();

  /// Cargar todas las tareas de la empresa con filtros opcionales
  Future<void> cargarTodasLasTareas({
    EstadoTarea? estado,
    PrioridadTarea? prioridad,
    Departamento? departamento,
    String? asignadoAUsuarioId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todasLasTareas = await _tareaService.getTareas(
        estado: estado,
        prioridad: prioridad,
        departamento: departamento,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _todasLasTareas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener detalle de una tarea específica
  Future<Tarea?> obtenerTareaDetalle(String tareaId) async {
    try {
      return await _tareaService.getTareaById(tareaId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Cancelar una tarea (solo admin/manager)
  Future<bool> cancelarTarea(String tareaId, String? motivo) async {
    try {
      await _tareaService.cancelarTarea(tareaId, motivo: motivo);
      // Recargar tareas después de cancelar
      await cargarTodasLasTareas();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
