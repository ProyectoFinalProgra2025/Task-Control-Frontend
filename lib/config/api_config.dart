class ApiConfig {
  // URL base del API - Cambiar para producción
  static const String baseUrl = 'https://api.taskcontrol.work'; // Producción
  // static const String baseUrl = 'http://localhost:5080'; // Desarrollo
  
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
  
  // Endpoints de chat
  static const String usersSearchEndpoint = '/api/users/search';
  static const String chatsEndpoint = '/api/chats';
  static String chatMessagesEndpoint(String chatId) => '/api/chats/$chatId/messages';
  static String chatMembersEndpoint(String chatId) => '/api/chats/$chatId/members';

  // Endpoints de lectura de mensajes
  static String chatMarkMessageReadEndpoint(String messageId) => '/api/chats/messages/$messageId/mark-read';
  static String chatMarkAllReadEndpoint(String chatId) => '/api/chats/$chatId/mark-all-read';
  static const String chatUnreadCountEndpoint = '/api/chats/unread-count';
  static const String chatUnreadByChatEndpoint = '/api/chats/unread-by-chat';
  
  // SignalR Hub
  static String get signalRHubUrl => '$baseUrl/apphub';
  
  // Headers comunes
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  static Map<String, String> headersWithAuth(String token) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}
