class ApiConfig {
  // URL base del API - Cambiar para producción
  // static const String baseUrl = 'https://api.taskcontrol.work'; // Producción
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
  
  // Endpoints de chat - COMPLETAMENTE IMPLEMENTADOS
  static const String chatUsersSearchEndpoint = '/api/chat/users/search';
  static const String chatConversationsEndpoint = '/api/chat/conversations';
  static const String chatMessagesEndpoint = '/api/chat/conversations/{id}/messages';
  static const String chatFilesEndpoint = '/api/chat/conversations/{id}/files';
  static const String chatMessageDeliveredEndpoint = '/api/chat/messages/{id}/delivered';
  static const String chatMessageReadEndpoint = '/api/chat/messages/{id}/read';
  static const String chatMessagesReadAllEndpoint = '/api/chat/conversations/{id}/read-all';
  static const String chatUnreadCountEndpoint = '/api/chat/conversations/{id}/unread-count';
  
  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}
