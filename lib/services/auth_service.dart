import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
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
      // Backend structure: {"success": true, "message": "...", "data": {...}}
      final data = jsonResponse['data'] ?? {};
      final authResponse = AuthResponse.fromJson(data);
      
      // Guardar tokens y datos del usuario
      await _storage.saveAuthResponse(authResponse);
      
      return authResponse;
    } else if (response.statusCode == 401) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Credenciales incorrectas');
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
        'RefreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Backend returns: {"success": true, "data": {"AccessToken": ..., "RefreshToken": ..., "ExpiresIn": ...}}
      final data = jsonResponse['data'] ?? {};
      
      // Get current user data since refresh doesn't return it
      final currentUserData = await _storage.getUserData();
      if (currentUserData == null) {
        throw Exception('No hay datos de usuario guardados');
      }
      
      // Create AuthResponse with tokens and existing user data
      final authResponse = AuthResponse(
        accessToken: data['AccessToken'] ?? data['accessToken'] ?? '',
        refreshToken: data['RefreshToken'] ?? data['refreshToken'] ?? '',
        expiresIn: data['ExpiresIn'] ?? data['expiresIn'] ?? 3600,
        usuario: UserModel.fromJson(currentUserData),
      );
      
      // Actualizar tokens guardados
      await _storage.saveAuthResponse(authResponse);
      
      return authResponse;
    } else {
      throw Exception('Error al renovar token: ${response.statusCode}');
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
            'RefreshToken': refreshToken,
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

  // ========== VERIFY TOKEN (llamar a /api/usuarios/me) ==========
  
  Future<UserModel?> verifyToken() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) return null;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/usuarios/me');
      final response = await http.get(
        url,
        headers: ApiConfig.headersWithAuth(accessToken),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'] ?? {};
        return UserModel.fromJson(data);
      } else if (response.statusCode == 401) {
        // Token expirado, intentar refresh
        try {
          await refreshToken();
          return await verifyToken(); // Retry
        } catch (e) {
          await _storage.clearAuth();
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
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
