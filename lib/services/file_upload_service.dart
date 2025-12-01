import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/documento_adjunto.dart';
import '../models/evidencia.dart';
import 'storage_service.dart';

/// Modelo para la respuesta de subida de archivo
class FileUploadResponse {
  final bool success;
  final String? fileName;
  final String? blobUrl;
  final String? contentType;
  final int? size;
  final String? message;
  final dynamic data;

  FileUploadResponse({
    required this.success,
    this.fileName,
    this.blobUrl,
    this.contentType,
    this.size,
    this.message,
    this.data,
  });

  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return FileUploadResponse(
      success: json['success'] ?? false,
      fileName: data?['fileName'],
      blobUrl: data?['blobUrl'],
      contentType: data?['contentType'],
      size: data?['size'],
      message: json['message'],
      data: json['data'],
    );
  }

  factory FileUploadResponse.error(String message) {
    return FileUploadResponse(
      success: false,
      message: message,
    );
  }
}

/// Servicio para subir archivos al backend (Azure Blob Storage)
class FileUploadService {
  final StorageService _storage = StorageService();

  /// Selecciona un archivo usando el file picker
  Future<PlatformFile?> pickFile({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// Selecciona múltiples archivos
  Future<List<PlatformFile>> pickMultipleFiles({FileType type = FileType.any}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files;
      }
      return [];
    } catch (e) {
      print('Error picking files: $e');
      return [];
    }
  }

  /// Selecciona una imagen
  Future<PlatformFile?> pickImage() async {
    return pickFile(type: FileType.image);
  }

  /// Sube un archivo al backend
  /// [file] - El archivo a subir (PlatformFile de file_picker)
  /// [folder] - Carpeta opcional dentro del contenedor de blob storage
  Future<FileUploadResponse> uploadFile(PlatformFile file, {String? folder}) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return FileUploadResponse.error('No hay token de acceso');
      }

      // Construir URL del endpoint
      String endpoint = '/api/files/upload';
      if (folder != null && folder.isNotEmpty) {
        endpoint = '/api/files/upload/$folder';
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      // Crear multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Agregar header de autorización
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar el archivo
      if (file.bytes != null) {
        // Web/memoria - usar bytes directamente
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        // Móvil/Desktop - usar path del archivo
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        return FileUploadResponse.error('No se puede leer el archivo');
      }

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return FileUploadResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        return FileUploadResponse.error('Sesión expirada. Por favor, inicia sesión nuevamente.');
      } else {
        try {
          final jsonResponse = jsonDecode(response.body);
          return FileUploadResponse.error(jsonResponse['message'] ?? 'Error al subir archivo (${response.statusCode})');
        } catch (e) {
          // Si no es JSON válido, mostrar el body raw
          return FileUploadResponse.error('Error del servidor: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }
    } catch (e) {
      print('Error uploading file: $e');
      return FileUploadResponse.error('Error de conexión: $e');
    }
  }

  // ============================================================
  // DOCUMENTOS ADJUNTOS DE TAREA
  // ============================================================

  /// Sube un documento adjunto a una tarea
  /// POST /api/tareas/{tareaId}/documentos
  Future<DocumentoAdjunto?> uploadDocumentoTarea(String tareaId, PlatformFile file) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/tareas/$tareaId/documentos');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!, filename: file.name),
        );
      } else {
        throw Exception('No se puede leer el archivo');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return DocumentoAdjunto.fromJson(jsonResponse['data']);
        }
      }
      
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg);
    } catch (e) {
      print('Error uploading documento: $e');
      rethrow;
    }
  }

  /// Obtiene los documentos adjuntos de una tarea
  /// GET /api/tareas/{tareaId}/documentos
  Future<List<DocumentoAdjunto>> getDocumentosTarea(String tareaId) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/tareas/$tareaId/documentos');
      final response = await http.get(uri, headers: ApiConfig.headersWithAuth(token));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> docs = jsonResponse['data'];
          return docs.map((d) => DocumentoAdjunto.fromJson(d)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting documentos: $e');
      return [];
    }
  }

  /// Elimina un documento adjunto de una tarea
  /// DELETE /api/tareas/{tareaId}/documentos/{documentoId}
  Future<bool> deleteDocumentoTarea(String tareaId, String documentoId) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/tareas/$tareaId/documentos/$documentoId');
      final response = await http.delete(uri, headers: ApiConfig.headersWithAuth(token));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting documento: $e');
      return false;
    }
  }

  // ============================================================
  // EVIDENCIAS DE TAREA
  // ============================================================

  /// Agrega una evidencia a una tarea (texto y/o archivo)
  /// POST /api/tareas/{tareaId}/evidencias
  Future<Evidencia?> uploadEvidenciaTarea(
    String tareaId, {
    String? descripcion,
    PlatformFile? file,
  }) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      // Validar que haya al menos descripción o archivo
      if ((descripcion == null || descripcion.isEmpty) && file == null) {
        throw Exception('Debe proporcionar una descripción o un archivo');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/tareas/$tareaId/evidencias');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Agregar descripción si existe
      if (descripcion != null && descripcion.isNotEmpty) {
        request.fields['Descripcion'] = descripcion;
      }

      // Agregar archivo si existe
      if (file != null) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
          );
        } else if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath('file', file.path!, filename: file.name),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Evidencia upload status: ${response.statusCode}');
      print('Evidencia upload body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return Evidencia.fromJson(jsonResponse['data']);
        }
      }
      
      final errorMsg = _extractErrorMessage(response);
      throw Exception(errorMsg);
    } catch (e) {
      print('Error uploading evidencia: $e');
      rethrow;
    }
  }

  /// Obtiene las evidencias de una tarea
  /// GET /api/tareas/{tareaId}/evidencias
  Future<List<Evidencia>> getEvidenciasTarea(String tareaId) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/tareas/$tareaId/evidencias');
      final response = await http.get(uri, headers: ApiConfig.headersWithAuth(token));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> evidencias = jsonResponse['data'];
          return evidencias.map((e) => Evidencia.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting evidencias: $e');
      return [];
    }
  }

  /// Elimina una evidencia de una tarea
  /// DELETE /api/tareas/{tareaId}/evidencias/{evidenciaId}
  Future<bool> deleteEvidenciaTarea(String tareaId, String evidenciaId) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/tareas/$tareaId/evidencias/$evidenciaId');
      final response = await http.delete(uri, headers: ApiConfig.headersWithAuth(token));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting evidencia: $e');
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Elimina un archivo de blob storage por su URL
  Future<bool> deleteFile(String blobUrl) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/files?blobUrl=${Uri.encodeComponent(blobUrl)}');
      
      final response = await http.delete(
        uri,
        headers: ApiConfig.headersWithAuth(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Extrae el mensaje de error de una respuesta HTTP
  String _extractErrorMessage(http.Response response) {
    try {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['message'] ?? 'Error (${response.statusCode})';
    } catch (e) {
      return 'Error del servidor (${response.statusCode})';
    }
  }

  /// Formatea el tamaño de un archivo en bytes a una cadena legible
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
