class ApiConfig {
  // URL base del API
  static const String baseUrl = 'http://localhost:5080';
  
  // Endpoints de autenticación
  static const String loginEndpoint = '/api/Auth/login';
  static const String refreshEndpoint = '/api/Auth/refresh';
  static const String logoutEndpoint = '/api/Auth/logout';
  static const String registerEmpresaEndpoint = '/api/Auth/register-adminempresa';
  
  // Endpoints de empresas
  static const String empresasEndpoint = '/api/Empresas';
  
  // Endpoints de tareas
  static const String tareasEndpoint = '/api/Tareas';
  
  // Endpoints de usuarios
  static const String usuariosEndpoint = '/api/Usuarios';
  
  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}
