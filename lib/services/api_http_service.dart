import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// Servicio HTTP que maneja automáticamente JWT y refresh tokens
class ApiHttpService {
  final StorageService _storage = StorageService();
  bool _isRefreshing = false;

  /// Realizar GET request con autorización automática
  Future<http.Response> get(String endpoint) async {
    return _makeRequest(() async {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      return http.get(url, headers: ApiConfig.headersWithAuth(token));
    });
  }

  /// Realizar POST request con autorización automática
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _makeRequest(() async {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      return http.post(
        url,
        headers: ApiConfig.headersWithAuth(token),
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  /// Realizar PUT request con autorización automática
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _makeRequest(() async {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      return http.put(
        url,
        headers: ApiConfig.headersWithAuth(token),
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  /// Realizar DELETE request con autorización automática
  Future<http.Response> delete(String endpoint) async {
    return _makeRequest(() async {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('No hay token de acceso');

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      return http.delete(url, headers: ApiConfig.headersWithAuth(token));
    });
  }

  /// Wrapper que maneja automáticamente el refresh token si expira el access token
  Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();

      // Si es 401 (Unauthorized), intentar refrescar el token
      if (response.statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshed = await _refreshToken();
          _isRefreshing = false;
          
          if (refreshed) {
            // Reintentar la petición con el nuevo token
            return await request();
          } else {
            throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
          }
        } catch (e) {
          _isRefreshing = false;
          rethrow;
        }
      }

      return response;
    } catch (e) {
      _isRefreshing = false;
      rethrow;
    }
  }

  /// Refrescar el access token usando el refresh token
  Future<bool> _refreshToken() async {
    try {
      final authService = AuthService();
      await authService.refreshToken();
      return true;
    } catch (e) {
      // Si falla el refresh, limpiar tokens y forzar logout
      await _storage.clearAuth();
      return false;
    }
  }
}
