import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'api_http_service.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';
import '../models/capacidad_nivel_item.dart';
import '../models/importar_usuarios_resultado.dart';
import 'storage_service.dart';

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
  Future<Usuario> getUsuarioById(String id) async {
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
  Future<void> deleteUsuario(String id) async {
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

  /// Obtener estadísticas personales de tareas (dashboard)
  Future<UsuarioDashboardStats> getMiDashboard() async {
    try {
      final response = await _http.get('/api/usuarios/me/dashboard');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return UsuarioDashboardStats.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Error al obtener dashboard');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener dashboard');
      }
    } catch (e) {
      throw Exception('Error al obtener dashboard: $e');
    }
  }

  /// Actualizar capacidades de un usuario (AdminEmpresa)
  Future<void> updateCapacidadesUsuario(String usuarioId, List<CapacidadNivelItem> capacidades) async {
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
  Future<void> deleteMiCapacidad(String capacidadId) async {
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

  /// Crear un nuevo usuario (solo AdminEmpresa)
  Future<String> createUsuario(Map<String, dynamic> dto) async {
    try {
      final response = await _http.post('/api/usuarios', body: dto);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['id']?.toString() ?? '';
        } else {
          throw Exception(data['message'] ?? 'Error al crear usuario');
        }
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else if (response.statusCode == 409) {
        throw Exception('El email ya está registrado');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al crear usuario');
      }
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  // ==================== IMPORTACIÓN MASIVA CSV ====================

  final StorageService _storage = StorageService();

  /// Importa usuarios desde un archivo CSV (solo AdminEmpresa)
  /// [file] - Archivo CSV con las columnas: Email,NombreCompleto,Telefono,Rol,Departamento,NivelHabilidad
  /// [passwordPorDefecto] - Si se especifica, todos los usuarios usarán esta contraseña
  Future<ImportarUsuariosResultado> importarUsuariosCsv(
    PlatformFile file, {
    String? passwordPorDefecto,
  }) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/usuarios/importar-csv');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar archivo CSV
      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ArchivoCSV',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'ArchivoCSV',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('No se puede leer el archivo');
      }

      // Agregar contraseña por defecto si existe
      if (passwordPorDefecto != null && passwordPorDefecto.isNotEmpty) {
        request.fields['PasswordPorDefecto'] = passwordPorDefecto;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Import CSV status: ${response.statusCode}');
      print('Import CSV body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return ImportarUsuariosResultado.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Error en la importación');
        }
      } else if (response.statusCode == 400) {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Archivo CSV inválido');
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para importar usuarios');
      } else {
        try {
          final jsonResponse = jsonDecode(response.body);
          throw Exception(jsonResponse['message'] ?? 'Error (${response.statusCode})');
        } catch (e) {
          throw Exception('Error del servidor (${response.statusCode})');
        }
      }
    } catch (e) {
      print('Error importing CSV: $e');
      rethrow;
    }
  }

  /// Descarga la plantilla CSV de ejemplo
  /// Retorna los bytes del archivo o null si falla
  Future<List<int>?> descargarPlantillaCsv() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de autenticación');

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/usuarios/importar-csv/plantilla');
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      print('Error downloading template: $e');
      return null;
    }
  }
}
