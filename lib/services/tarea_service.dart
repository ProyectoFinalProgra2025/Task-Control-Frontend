import 'dart:convert';
import 'api_http_service.dart';
import '../models/tarea.dart';
import '../models/enums/estado_tarea.dart';
import '../models/enums/prioridad_tarea.dart';
import '../models/enums/departamento.dart';

class TareaService {
  final ApiHttpService _http = ApiHttpService();

  /// Obtener todas las tareas (usa el JWT para determinar la empresa)
  /// Filtros opcionales: estado, prioridad, departamento, asignadoA
  Future<List<Tarea>> getTareas({
    EstadoTarea? estado,
    PrioridadTarea? prioridad,
    Departamento? departamento,
    int? asignadoA,
  }) async {
    try {
      // Construir query params
      final queryParams = <String, String>{};
      if (estado != null) queryParams['estado'] = estado.value.toString();
      if (prioridad != null) queryParams['prioridad'] = prioridad.value.toString();
      if (departamento != null) queryParams['departamento'] = departamento.value.toString();
      if (asignadoA != null) queryParams['asignadoA'] = asignadoA.toString();

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';

      final response = await _http.get('/api/tareas$queryString');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> tareasJson = data['data'] ?? [];
          return tareasJson.map((json) => Tarea.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Error al obtener tareas');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener tareas');
      }
    } catch (e) {
      throw Exception('Error al obtener tareas: $e');
    }
  }

  /// Obtener tarea por ID con detalles completos
  Future<Tarea> getTareaById(int tareaId) async {
    try {
      final response = await _http.get('/api/tareas/$tareaId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Tarea.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Error al obtener tarea');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Tarea no encontrada');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener tarea');
      }
    } catch (e) {
      throw Exception('Error al obtener tarea: $e');
    }
  }

  /// Crear una nueva tarea
  Future<int> createTarea(CreateTareaDTO dto) async {
    try {
      final response = await _http.post(
        '/api/tareas',
        body: dto.toJson(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['id'] ?? 0;
        } else {
          throw Exception(data['message'] ?? 'Error al crear tarea');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo AdminEmpresa puede crear tareas.');
      } else if (response.statusCode == 422) {
        throw Exception('Datos inválidos. Verifica los campos requeridos.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al crear tarea');
      }
    } catch (e) {
      throw Exception('Error al crear tarea: $e');
    }
  }

  /// Asignar tarea manualmente a un usuario
  Future<void> asignarManual(int tareaId, AsignarManualTareaDTO dto) async {
    try {
      final response = await _http.put(
        '/api/tareas/$tareaId/asignar-manual',
        body: dto.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al asignar tarea manualmente');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo AdminEmpresa puede asignar tareas.');
      } else if (response.statusCode == 404) {
        throw Exception('Tarea no encontrada');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al asignar tarea');
      }
    } catch (e) {
      throw Exception('Error al asignar tarea manualmente: $e');
    }
  }

  /// Asignar tarea automáticamente (el sistema elige el mejor candidato)
  Future<void> asignarAutomatico(int tareaId, {bool forzarReasignacion = false}) async {
    try {
      final dto = AsignarAutomaticoTareaDTO(forzarReasignacion: forzarReasignacion);
      final response = await _http.put(
        '/api/tareas/$tareaId/asignar-automatico',
        body: dto.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al asignar tarea automáticamente');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo AdminEmpresa puede asignar tareas.');
      } else if (response.statusCode == 404) {
        throw Exception('Tarea no encontrada');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al asignar tarea automáticamente');
      }
    } catch (e) {
      throw Exception('Error al asignar tarea automáticamente: $e');
    }
  }

  /// Cancelar una tarea (solo AdminEmpresa)
  Future<void> cancelarTarea(int tareaId, {String? motivo}) async {
    try {
      final response = await _http.put(
        '/api/tareas/$tareaId/cancelar',
        body: motivo != null ? {'motivo': motivo} : null,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al cancelar tarea');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo AdminEmpresa puede cancelar tareas.');
      } else if (response.statusCode == 404) {
        throw Exception('Tarea no encontrada');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al cancelar tarea');
      }
    } catch (e) {
      throw Exception('Error al cancelar tarea: $e');
    }
  }

  /// Aceptar una tarea (solo Usuario/Worker)
  Future<void> aceptarTarea(int tareaId) async {
    try {
      final response = await _http.put('/api/tareas/$tareaId/aceptar');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al aceptar tarea');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo trabajadores pueden aceptar tareas.');
      } else if (response.statusCode == 404) {
        throw Exception('Tarea no encontrada');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al aceptar tarea');
      }
    } catch (e) {
      throw Exception('Error al aceptar tarea: $e');
    }
  }

  /// Obtener tareas del trabajador autenticado (GET /api/tareas/mis)
  Future<List<Tarea>> getMisTareas({
    EstadoTarea? estado,
    PrioridadTarea? prioridad,
    Departamento? departamento,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (estado != null) queryParams['estado'] = estado.value.toString();
      if (prioridad != null) queryParams['prioridad'] = prioridad.value.toString();
      if (departamento != null) queryParams['departamento'] = departamento.value.toString();

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';

      final response = await _http.get('/api/tareas/mis$queryString');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> tareasJson = data['data'] ?? [];
          return tareasJson.map((json) => Tarea.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Error al obtener mis tareas');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener mis tareas');
      }
    } catch (e) {
      throw Exception('Error al obtener mis tareas: $e');
    }
  }

  /// Finalizar una tarea (solo Usuario/Worker) con evidencia
  Future<void> finalizarTarea(int tareaId, FinalizarTareaDTO dto) async {
    try {
      final response = await _http.put(
        '/api/tareas/$tareaId/finalizar',
        body: dto.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al finalizar tarea');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo trabajadores pueden finalizar tareas.');
      } else if (response.statusCode == 404) {
        throw Exception('Tarea no encontrada');
      } else if (response.statusCode == 422) {
        throw Exception('Datos inválidos. Verifica los campos requeridos.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al finalizar tarea');
      }
    } catch (e) {
      throw Exception('Error al finalizar tarea: $e');
    }
  }
}
