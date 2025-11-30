import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';

/// Servicio SINGLETON para gestionar conexión SignalR del Chat
/// Sincronizado con ChatHub del backend
/// 
/// Eventos del backend:
/// - "ReceiveMessage" -> Nuevo mensaje en cualquier chat
/// - "MessageDelivered" -> Confirmación de entrega (✓)
/// - "MessageRead" -> Confirmación de lectura (✓✓)
/// - "UserTyping" -> Usuario está escribiendo
/// 
/// Métodos que el cliente puede invocar:
/// - JoinConversation(conversationId) -> Unirse a un chat específico
/// - LeaveConversation(conversationId) -> Salir de un chat específico
/// - SendTyping(conversationId) -> Indicar que está escribiendo
class ChatHubService {
  static final ChatHubService _instance = ChatHubService._internal();
  factory ChatHubService() => _instance;
  ChatHubService._internal();

  HubConnection? _conn;
  String? _currentToken;

  // Streams para eventos (patrón broadcast)
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeliveredController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Getters de streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onMessageDelivered => _messageDeliveredController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<bool> get onConnectionStateChanged => _connectionStateController.stream;

  bool get isConnected => _conn?.state == HubConnectionState.Connected;

  /// Conectar a SignalR con token
  Future<bool> connect(String token) async {
    // Si ya conectado con el mismo token, no hacer nada
    if (_conn != null && _currentToken == token && isConnected) {
      print('[ChatHubService] Ya conectado con el mismo token');
      return true;
    }

    _currentToken = token;
    await disconnect();

    try {
      final url = '${ApiConfig.baseUrl}/chathub?access_token=$token';
      print('[ChatHubService] Conectando a: $url');

      final conn = HubConnectionBuilder()
          .withUrl(url)
          .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 30000])
          .build();

      // Registrar event handlers
      _registerEventHandlers(conn);

      // Handlers de conexión
      conn.onclose(({error}) {
        print('[ChatHubService] Conexión cerrada: $error');
        _connectionStateController.add(false);
      });

      conn.onreconnecting(({error}) {
        print('[ChatHubService] Reconectando: $error');
        _connectionStateController.add(false);
      });

      conn.onreconnected(({connectionId}) {
        print('[ChatHubService] Reconectado: $connectionId');
        _connectionStateController.add(true);
      });

      // Conectar
      await conn.start();
      _conn = conn;
      _connectionStateController.add(true);

      print('[ChatHubService] ✅ Conectado exitosamente');
      return true;
    } catch (e) {
      print('[ChatHubService] ❌ Error de conexión: $e');
      _connectionStateController.add(false);
      return false;
    }
  }

  /// Registrar todos los event handlers
  /// Nombres de eventos según ChatHub.cs del backend
  void _registerEventHandlers(HubConnection conn) {
    // Nuevo mensaje - Backend: "ReceiveMessage"
    conn.on('ReceiveMessage', (args) {
      print('[ChatHubService] 📨 ReceiveMessage recibido: $args');
      if (args != null && args.isNotEmpty) {
        final data = _parseEventData(args[0]);
        if (data != null) {
          _messageController.add(data);
        }
      }
    });

    // Mensaje entregado - Backend: "MessageDelivered"
    conn.on('MessageDelivered', (args) {
      print('[ChatHubService] ✓ MessageDelivered recibido: $args');
      if (args != null && args.isNotEmpty) {
        final data = _parseEventData(args[0]);
        if (data != null) {
          _messageDeliveredController.add(data);
        }
      }
    });

    // Mensaje leído - Backend: "MessageRead"
    conn.on('MessageRead', (args) {
      print('[ChatHubService] ✓✓ MessageRead recibido: $args');
      if (args != null && args.isNotEmpty) {
        final data = _parseEventData(args[0]);
        if (data != null) {
          _messageReadController.add(data);
        }
      }
    });

    // Usuario escribiendo - Backend: "UserTyping"
    conn.on('UserTyping', (args) {
      print('[ChatHubService] ⌨️ UserTyping recibido: $args');
      if (args != null && args.isNotEmpty) {
        final data = _parseEventData(args[0]);
        if (data != null) {
          _typingController.add(data);
        }
      }
    });
  }

  /// Parse event data
  Map<String, dynamic>? _parseEventData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return null;
  }

  /// Unirse a una conversación
  /// Método del backend: JoinConversation(string conversationId)
  Future<void> joinConversation(String conversationId) async {
    if (!isConnected || _conn == null) {
      print('[ChatHubService] No conectado, no puede unirse a conversación');
      return;
    }
    try {
      await _conn!.invoke('JoinConversation', args: [conversationId]);
      print('[ChatHubService] 💬 Unido a conversación: $conversationId');
    } catch (e) {
      print('[ChatHubService] Error uniéndose a conversación: $e');
    }
  }

  /// Salir de una conversación
  /// Método del backend: LeaveConversation(string conversationId)
  Future<void> leaveConversation(String conversationId) async {
    if (!isConnected || _conn == null) return;
    try {
      await _conn!.invoke('LeaveConversation', args: [conversationId]);
      print('[ChatHubService] 🚪 Salió de conversación: $conversationId');
    } catch (e) {
      print('[ChatHubService] Error saliendo de conversación: $e');
    }
  }

  /// Enviar indicador de escritura
  /// Método del backend: SendTyping(string conversationId)
  Future<void> sendTypingIndicator(String conversationId) async {
    if (!isConnected || _conn == null) return;
    try {
      await _conn!.invoke('SendTyping', args: [conversationId]);
    } catch (e) {
      print('[ChatHubService] Error enviando typing: $e');
    }
  }

  /// Desconectar
  Future<void> disconnect() async {
    if (_conn != null) {
      try {
        await _conn!.stop();
        print('[ChatHubService] 👋 Desconectado');
      } catch (e) {
        print('[ChatHubService] Error desconectando: $e');
      }
      _conn = null;
      _connectionStateController.add(false);
    }
  }

  /// Dispose (cerrar streams)
  void dispose() {
    _messageController.close();
    _messageDeliveredController.close();
    _messageReadController.close();
    _typingController.close();
    _connectionStateController.close();
    disconnect();
  }
}
