import 'dart:convert';
import 'api_http_service.dart';
import '../models/usuario.dart';
import '../models/capacidad_nivel_item.dart';

class UsuarioService {
  final ApiHttpService _http = ApiHttpService();

  /// Obtener todos los usuarios (trabajadores) de la empresa
  Future<List<Usuario>> getUsuarios() async {
    try {
      final response = await _http.get('/api/usuarios');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> usuariosJson = data['data'] ?? [];
          return usuariosJson.map((json) => Usuario.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Error al obtener usuarios');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener usuarios');
      }
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Obtener un usuario por ID
  Future<Usuario> getUsuarioById(int id) async {
    try {
      final response = await _http.get('/api/usuarios/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Usuario.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Error al obtener usuario');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener usuario');
      }
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Eliminar un usuario
  Future<void> deleteUsuario(int id) async {
    try {
      final response = await _http.delete('/api/usuarios/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al eliminar usuario');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo AdminEmpresa puede eliminar usuarios.');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar usuario');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Obtener el perfil completo del usuario autenticado
  Future<Usuario> getMe() async {
    try {
      final response = await _http.get('/api/usuarios/me');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Usuario.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Error al obtener perfil');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener perfil');
      }
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// Actualizar capacidades de un usuario (AdminEmpresa)
  Future<void> updateCapacidadesUsuario(int usuarioId, List<CapacidadNivelItem> capacidades) async {
    try {
      final response = await _http.put(
        '/api/usuarios/$usuarioId/capacidades',
        body: {'capacidades': capacidades.map((c) => c.toJson()).toList()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al actualizar capacidades');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Solo AdminEmpresa puede actualizar capacidades.');
      } else if (response.statusCode == 422) {
        throw Exception('Datos inválidos. Verifica los campos requeridos.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar capacidades');
      }
    } catch (e) {
      throw Exception('Error al actualizar capacidades: $e');
    }
  }

  /// Actualizar mis propias capacidades (cualquier usuario autenticado)
  Future<void> updateMisCapacidades(List<CapacidadNivelItem> capacidades) async {
    try {
      final response = await _http.put(
        '/api/usuarios/mis-capacidades',
        body: {'capacidades': capacidades.map((c) => c.toJson()).toList()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al actualizar capacidades');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else if (response.statusCode == 422) {
        throw Exception('Datos inválidos. Verifica los campos requeridos.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar capacidades');
      }
    } catch (e) {
      throw Exception('Error al actualizar capacidades: $e');
    }
  }

  /// Eliminar una capacidad de mi perfil
  Future<void> deleteMiCapacidad(int capacidadId) async {
    try {
      final response = await _http.delete('/api/usuarios/mis-capacidades/$capacidadId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Error al eliminar capacidad');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else if (response.statusCode == 404) {
        throw Exception('Capacidad no encontrada');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar capacidad');
      }
    } catch (e) {
      throw Exception('Error al eliminar capacidad: $e');
    }
  }
}
