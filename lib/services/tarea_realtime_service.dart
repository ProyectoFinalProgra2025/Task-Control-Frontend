import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'storage_service.dart';
import '../config/api_config.dart';

/// Servicio ligero de SignalR para actualizaciones en tiempo real.
/// 
/// Este servicio se conecta al TareaHub del backend para recibir
/// notificaciones de cambios en tareas, métricas y actualizaciones generales.
/// 
/// NO usa providers globales. Se usa bajo demanda en las pantallas
/// que necesitan escuchar eventos.
/// 
/// Eventos disponibles del backend:
/// - tarea:created - Nueva tarea creada
/// - tarea:assigned - Tarea asignada a un usuario
/// - tarea:accepted - Tarea aceptada por un trabajador
/// - tarea:completed - Tarea completada
/// - tarea:reasignada - Tarea reasignada a otro usuario
/// - tarea:updated - Tarea editada
/// - metrics:updated - Métricas actualizadas
/// - user:updated - Usuario actualizado
/// - team:updated - Equipo actualizado
class TareaRealtimeService {
  static TareaRealtimeService? _instance;
  
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool _isConnecting = false;
  
  // Stream controllers para eventos
  final StreamController<TareaEvent> _eventController = 
      StreamController<TareaEvent>.broadcast();
  
  // Callbacks registrados
  final List<Function(TareaEvent)> _listeners = [];
  
  TareaRealtimeService._();
  
  /// Obtener instancia singleton
  static TareaRealtimeService get instance {
    _instance ??= TareaRealtimeService._();
    return _instance!;
  }
  
  /// Stream de eventos de tareas
  Stream<TareaEvent> get eventStream => _eventController.stream;
  
  /// Estado de conexión
  bool get isConnected => _isConnected;
  
  /// Conectar al hub de SignalR
  Future<bool> connect() async {
    if (_isConnected || _isConnecting) return _isConnected;
    
    _isConnecting = true;
    
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) {
        print('[TareaRealtimeService] No token available');
        _isConnecting = false;
        return false;
      }
      
      // Construir URL del hub - TareaHub para tareas/métricas
      final hubUrl = '${ApiConfig.baseUrl}/tareahub';
      print('[TareaRealtimeService] Connecting to: $hubUrl');
      
      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ))
          .withAutomaticReconnect()
          .build();
      
      // Configurar handlers de conexión
      _hubConnection!.onclose(({error}) {
        _isConnected = false;
        _emitEvent(TareaEvent(
          type: TareaEventType.connectionLost,
          message: 'Connection lost: ${error?.toString() ?? 'Unknown error'}',
        ));
      });
      
      _hubConnection!.onreconnecting(({error}) {
        _emitEvent(TareaEvent(
          type: TareaEventType.reconnecting,
          message: 'Reconnecting...',
        ));
      });
      
      _hubConnection!.onreconnected(({connectionId}) {
        _isConnected = true;
        _emitEvent(TareaEvent(
          type: TareaEventType.connected,
          message: 'Reconnected',
        ));
      });
      
      // Registrar handlers de eventos de tareas
      _registerEventHandlers();
      
      // Iniciar conexión
      await _hubConnection!.start();
      _isConnected = true;
      _isConnecting = false;
      
      print('[TareaRealtimeService] ✅ Connected successfully to $hubUrl');
      
      _emitEvent(TareaEvent(
        type: TareaEventType.connected,
        message: 'Connected to realtime server',
      ));
      
      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      print('[TareaRealtimeService] Connection error: $e');
      _emitEvent(TareaEvent(
        type: TareaEventType.connectionError,
        message: 'Connection error: $e',
      ));
      return false;
    }
  }
  
  /// Registrar handlers para eventos de tareas
  void _registerEventHandlers() {
    if (_hubConnection == null) return;
    
    // tarea:created
    _hubConnection!.on('tarea:created', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:created event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaCreated,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // tarea:assigned
    _hubConnection!.on('tarea:assigned', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:assigned event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaAssigned,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // tarea:accepted
    _hubConnection!.on('tarea:accepted', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:accepted event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaAccepted,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // tarea:completed
    _hubConnection!.on('tarea:completed', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:completed event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaCompleted,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // tarea:reasignada
    _hubConnection!.on('tarea:reasignada', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:reasignada event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaReasignada,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // tarea:updated - cuando se edita una tarea
    _hubConnection!.on('tarea:updated', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:updated event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaUpdated,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // tarea:cancelled - cuando se cancela una tarea
    _hubConnection!.on('tarea:cancelled', (arguments) {
      print('[TareaRealtimeService] 📨 Received tarea:cancelled event: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(TareaEvent(
          type: TareaEventType.tareaCancelled,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
  }
  
  /// Parsear datos del evento
  Map<String, dynamic>? _parseEventData(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
  
  /// Emitir evento a todos los listeners
  void _emitEvent(TareaEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
    for (final listener in _listeners) {
      try {
        listener(event);
      } catch (_) {}
    }
  }
  
  /// Agregar listener para eventos
  void addListener(Function(TareaEvent) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  /// Remover listener
  void removeListener(Function(TareaEvent) listener) {
    _listeners.remove(listener);
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
    _listeners.clear();
    _instance = null;
  }
}

/// Tipos de eventos de tareas
enum TareaEventType {
  // Eventos de conexión
  connected,
  connectionLost,
  connectionError,
  reconnecting,
  
  // Eventos de tareas
  tareaCreated,
  tareaAssigned,
  tareaAccepted,
  tareaCompleted,
  tareaReasignada,
  tareaUpdated,
  tareaCancelled,
}

/// Evento de tarea
class TareaEvent {
  final TareaEventType type;
  final Map<String, dynamic>? data;
  final String? message;
  final DateTime timestamp;
  
  TareaEvent({
    required this.type,
    this.data,
    this.message,
  }) : timestamp = DateTime.now();
  
  /// ID de la tarea del evento
  String? get tareaId => data?['id']?.toString();
  
  /// Título de la tarea
  String? get titulo => data?['titulo']?.toString();
  
  /// Estado de la tarea
  String? get estado => data?['estado']?.toString();
  
  /// ID del usuario asignado
  String? get asignadoAUsuarioId => data?['asignadoAUsuarioId']?.toString();
  
  /// Nombre del usuario asignado
  String? get asignadoANombre => data?['asignadoANombre']?.toString();
  
  /// Es un evento de tarea (no de conexión)?
  bool get isTareaEvent => type == TareaEventType.tareaCreated ||
      type == TareaEventType.tareaAssigned ||
      type == TareaEventType.tareaAccepted ||
      type == TareaEventType.tareaCompleted ||
      type == TareaEventType.tareaReasignada ||
      type == TareaEventType.tareaUpdated ||
      type == TareaEventType.tareaCancelled;
  
  @override
  String toString() => 'TareaEvent($type, data: $data, message: $message)';
}
