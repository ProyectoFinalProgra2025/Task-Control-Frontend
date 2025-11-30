import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'storage_service.dart';
import '../config/api_config.dart';

/// Servicio de SignalR para chat en tiempo real.
/// 
/// Se conecta al ChatHub del backend para:
/// - Recibir mensajes nuevos
/// - Notificaciones de entrega/lectura
/// - Indicador de "escribiendo..."
/// 
/// Eventos del backend:
/// - chat:message - Nuevo mensaje
/// - chat:message_delivered - Mensaje entregado (✓)
/// - chat:message_read - Mensaje leído (✓✓)
/// - chat:typing - Usuario escribiendo
/// - chat:conversation_updated - Conversación actualizada
class ChatRealtimeService {
  static ChatRealtimeService? _instance;
  
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool _isConnecting = false;
  
  // Stream controllers para eventos
  final StreamController<ChatRealtimeEvent> _eventController = 
      StreamController<ChatRealtimeEvent>.broadcast();
  
  ChatRealtimeService._();
  
  /// Obtener instancia singleton
  static ChatRealtimeService get instance {
    _instance ??= ChatRealtimeService._();
    return _instance!;
  }
  
  /// Stream de eventos de chat
  Stream<ChatRealtimeEvent> get eventStream => _eventController.stream;
  
  /// Estado de conexión
  bool get isConnected => _isConnected;
  
  /// Conectar al hub de chat
  Future<bool> connect() async {
    if (_isConnected || _isConnecting) return _isConnected;
    
    _isConnecting = true;
    
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) {
        print('[ChatRealtimeService] No token available');
        _isConnecting = false;
        return false;
      }
      
      final hubUrl = '${ApiConfig.baseUrl}/chathub';
      print('[ChatRealtimeService] Connecting to: $hubUrl');
      
      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ))
          .withAutomaticReconnect()
          .build();
      
      // Handlers de conexión
      _hubConnection!.onclose(({error}) {
        _isConnected = false;
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.connectionLost,
          message: 'Connection lost',
        ));
      });
      
      _hubConnection!.onreconnecting(({error}) {
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.reconnecting,
          message: 'Reconnecting...',
        ));
      });
      
      _hubConnection!.onreconnected(({connectionId}) {
        _isConnected = true;
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.connected,
          message: 'Reconnected',
        ));
      });
      
      // Registrar handlers de eventos
      _registerEventHandlers();
      
      // Iniciar conexión
      await _hubConnection!.start();
      _isConnected = true;
      _isConnecting = false;
      
      print('[ChatRealtimeService] Connected successfully!');
      
      _emitEvent(ChatRealtimeEvent(
        type: ChatEventType.connected,
        message: 'Connected to chat server',
      ));
      
      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      print('[ChatRealtimeService] Connection error: $e');
      return false;
    }
  }
  
  /// Registrar handlers para eventos de chat
  void _registerEventHandlers() {
    if (_hubConnection == null) return;
    
    // Nuevo mensaje
    _hubConnection!.on('chat:message', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.newMessage,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // Mensaje entregado
    _hubConnection!.on('chat:message_delivered', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.messageDelivered,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // Mensaje leído
    _hubConnection!.on('chat:message_read', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.messageRead,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // Usuario escribiendo
    _hubConnection!.on('chat:typing', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.typing,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // Conversación actualizada
    _hubConnection!.on('chat:conversation_updated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(ChatRealtimeEvent(
          type: ChatEventType.conversationUpdated,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
  }
  
  /// Unirse a una conversación (para recibir eventos de grupo)
  Future<void> joinConversation(String conversationId) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.invoke('JoinConversation', args: [conversationId]);
        print('[ChatRealtimeService] Joined conversation: $conversationId');
      } catch (e) {
        print('[ChatRealtimeService] Error joining conversation: $e');
      }
    }
  }
  
  /// Salir de una conversación
  Future<void> leaveConversation(String conversationId) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.invoke('LeaveConversation', args: [conversationId]);
        print('[ChatRealtimeService] Left conversation: $conversationId');
      } catch (e) {
        print('[ChatRealtimeService] Error leaving conversation: $e');
      }
    }
  }
  
  /// Enviar indicador de "escribiendo..."
  Future<void> sendTypingIndicator(String conversationId, List<String> recipientUserIds) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.invoke(
          'SendTypingIndicator', 
          args: [conversationId, recipientUserIds.join(',')],
        );
      } catch (e) {
        print('[ChatRealtimeService] Error sending typing indicator: $e');
      }
    }
  }
  
  /// Enviar indicador de "dejó de escribir"
  Future<void> sendStoppedTypingIndicator(String conversationId, List<String> recipientUserIds) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection!.invoke(
          'SendStoppedTypingIndicator', 
          args: [conversationId, recipientUserIds.join(',')],
        );
      } catch (e) {
        print('[ChatRealtimeService] Error sending stopped typing indicator: $e');
      }
    }
  }
  
  Map<String, dynamic>? _parseEventData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
  
  void _emitEvent(ChatRealtimeEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
  
  /// Desconectar del hub
  Future<void> disconnect() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
      _hubConnection = null;
    }
    _isConnected = false;
    _isConnecting = false;
  }
  
  /// Dispose del servicio
  void dispose() {
    disconnect();
    _eventController.close();
    _instance = null;
  }
}

/// Tipos de eventos de chat
enum ChatEventType {
  // Conexión
  connected,
  connectionLost,
  reconnecting,
  
  // Mensajes
  newMessage,
  messageDelivered,
  messageRead,
  
  // Otros
  typing,
  conversationUpdated,
}

/// Evento de chat
class ChatRealtimeEvent {
  final ChatEventType type;
  final Map<String, dynamic>? data;
  final String? message;
  final DateTime timestamp;
  
  ChatRealtimeEvent({
    required this.type,
    this.data,
    this.message,
  }) : timestamp = DateTime.now();
  
  // Helpers para acceder a datos comunes
  String? get conversationId => data?['conversationId']?.toString();
  String? get messageId => data?['messageId']?.toString();
  String? get senderId => data?['senderId']?.toString();
  String? get senderName => data?['senderName']?.toString();
  String? get content => data?['content']?.toString();
  bool get isTyping => data?['isTyping'] == true;
  
  @override
  String toString() => 'ChatRealtimeEvent($type, data: $data)';
}
