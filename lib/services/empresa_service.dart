import 'dart:convert';
import '../models/empresa_model.dart';
import 'api_http_service.dart';

class EmpresaService {
  final ApiHttpService _http = ApiHttpService();

  // ========== LISTAR EMPRESAS ==========
  Future<List<EmpresaModel>> listarEmpresas({String? estado}) async {
    String endpoint = '/api/Empresas';
    
    if (estado != null && estado.isNotEmpty) {
      endpoint += '?estado=$estado';
    }

    final response = await _http.get(endpoint);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> empresasList = jsonResponse['data'] ?? [];
      return empresasList.map((e) => EmpresaModel.fromJson(e)).toList();
    } else if (response.statusCode == 403) {
      throw Exception('No tienes permisos para ver las empresas');
    } else {
      throw Exception('Error al listar empresas: ${response.statusCode}');
    }
  }

  // ========== APROBAR EMPRESA ==========
  Future<void> aprobarEmpresa(int empresaId) async {
    final response = await _http.put('/api/Empresas/$empresaId/aprobar');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Empresa no encontrada');
    } else if (response.statusCode == 403) {
      throw Exception('No tienes permisos para aprobar empresas');
    } else {
      throw Exception('Error al aprobar empresa: ${response.statusCode}');
    }
  }

  // ========== RECHAZAR EMPRESA ==========
  Future<void> rechazarEmpresa(int empresaId) async {
    final response = await _http.put('/api/Empresas/$empresaId/rechazar');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Empresa no encontrada');
    } else if (response.statusCode == 403) {
      throw Exception('No tienes permisos para rechazar empresas');
    } else {
      throw Exception('Error al rechazar empresa: ${response.statusCode}');
    }
  }

  // ========== ELIMINAR EMPRESA ==========
  Future<void> eliminarEmpresa(int empresaId) async {
    final response = await _http.delete('/api/Empresas/$empresaId');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('Empresa no encontrada');
    } else if (response.statusCode == 403) {
      throw Exception('No tienes permisos para eliminar empresas');
    } else {
      throw Exception('Error al eliminar empresa: ${response.statusCode}');
    }
  }

  // ========== OBTENER ESTADÍSTICAS DE EMPRESA ==========
  Future<Map<String, dynamic>> obtenerEstadisticas(int empresaId) async {
    final response = await _http.get('/api/Empresas/$empresaId/estadisticas');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else if (response.statusCode == 404) {
      throw Exception('Empresa no encontrada');
    } else if (response.statusCode == 403) {
      throw Exception('No tienes permisos para ver las estadísticas');
    } else {
      throw Exception('Error al obtener estadísticas: ${response.statusCode}');
    }
  }
  
  // ========== OBTENER MIS ESTADÍSTICAS (empresa autenticada) ==========
  Future<Map<String, dynamic>> obtenerMisEstadisticas() async {
    // El backend obtiene el empresaId del JWT automáticamente
    final response = await _http.get('/api/Empresas/me/estadisticas');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Error al obtener estadísticas: ${response.statusCode}');
    }
  }

  // ========== OBTENER TODAS LAS ESTADÍSTICAS (para dashboard general) ==========
  Future<SystemStatsModel> obtenerEstadisticasGenerales() async {
    final empresas = await listarEmpresas();
    
    int totalEmpresas = empresas.length;
    int empresasPendientes = empresas.where((e) => e.isPending).length;
    int empresasAprobadas = empresas.where((e) => e.isApproved).length;
    int empresasRechazadas = empresas.where((e) => e.isRejected).length;

    // Obtener estadísticas de todas las empresas aprobadas
    int totalTrabajadores = 0;
    int tareasActivas = 0;
    int tareasCompletadas = 0;

    for (var empresa in empresas.where((e) => e.isApproved)) {
      try {
        final stats = await obtenerEstadisticas(empresa.id);
        totalTrabajadores += (stats['totalTrabajadores'] as int? ?? 0);
        tareasActivas += ((stats['tareasPendientes'] as int? ?? 0) + 
                         (stats['tareasAsignadas'] as int? ?? 0) + 
                         (stats['tareasAceptadas'] as int? ?? 0));
        tareasCompletadas += (stats['tareasFinalizadas'] as int? ?? 0);
      } catch (e) {
        // Continuar si hay error en alguna empresa
        print('Error obteniendo stats de empresa ${empresa.id}: $e');
      }
    }

    return SystemStatsModel(
      totalEmpresas: totalEmpresas,
      empresasPendientes: empresasPendientes,
      empresasAprobadas: empresasAprobadas,
      empresasRechazadas: empresasRechazadas,
      totalTrabajadores: totalTrabajadores,
      tareasActivas: tareasActivas,
      tareasCompletadas: tareasCompletadas,
    );
  }
}
