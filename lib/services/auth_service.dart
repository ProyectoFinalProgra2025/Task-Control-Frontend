import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  // ========== LOGIN ==========
  
  Future<AuthResponse> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
    
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse['data']);
      
      // Guardar tokens y datos del usuario
      await _storage.saveAuthResponse(authResponse);
      
      return authResponse;
    } else if (response.statusCode == 401) {
      throw Exception('Credenciales incorrectas');
    } else if (response.statusCode == 422) {
      throw Exception('Datos inválidos');
    } else {
      throw Exception('Error al iniciar sesión: ${response.statusCode}');
    }
  }

  // ========== REGISTER EMPRESA ==========
  
  Future<Map<String, dynamic>> registerEmpresa({
    required String email,
    required String password,
    required String nombreCompleto,
    String? telefono,
    required String nombreEmpresa,
    String? direccionEmpresa,
    String? telefonoEmpresa,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEmpresaEndpoint}');
    
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'nombreCompleto': nombreCompleto,
        'telefono': telefono,
        'nombreEmpresa': nombreEmpresa,
        'direccionEmpresa': direccionEmpresa,
        'telefonoEmpresa': telefonoEmpresa,
      }),
    );

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'success': true,
        'message': jsonResponse['message'] ?? 'Empresa registrada exitosamente',
        'empresaId': jsonResponse['data']?['empresaId'],
      };
    } else if (response.statusCode == 400) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Error en los datos proporcionados');
    } else if (response.statusCode == 422) {
      throw Exception('Datos de registro inválidos');
    } else {
      throw Exception('Error al registrar empresa: ${response.statusCode}');
    }
  }

  // ========== REFRESH TOKEN ==========
  
  Future<AuthResponse> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No hay refresh token disponible');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshEndpoint}');
    
    final response = await http.post(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode({
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(jsonResponse['data']);
      
      // Actualizar tokens guardados
      await _storage.saveAuthResponse(authResponse);
      
      return authResponse;
    } else {
      throw Exception('Error al renovar token');
    }
  }

  // ========== LOGOUT ==========
  
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      final accessToken = await _storage.getAccessToken();
      
      if (refreshToken != null && accessToken != null) {
        final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutEndpoint}');
        
        await http.post(
          url,
          headers: ApiConfig.headersWithAuth(accessToken),
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        );
      }
    } catch (e) {
      // Continuar con el logout local aunque falle el servidor
    } finally {
      // Siempre limpiar datos locales
      await _storage.clearAuth();
    }
  }

  // ========== GET CURRENT USER ==========
  
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await _storage.getUserData();
  }

  // ========== CHECK AUTH ==========
  
  Future<bool> isAuthenticated() async {
    return await _storage.isAuthenticated();
  }
}
