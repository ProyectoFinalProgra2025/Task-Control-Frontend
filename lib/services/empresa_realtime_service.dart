import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'storage_service.dart';
import '../config/api_config.dart';

/// Servicio de SignalR para eventos de empresas.
/// 
/// Este servicio se conecta al TareaHub del backend para recibir
/// notificaciones de cambios en empresas (solicitudes, aprobaciones, rechazos).
/// 
/// Eventos disponibles del backend:
/// - empresa:created - Nueva solicitud de empresa creada
/// - empresa:approved - Empresa aprobada por SuperAdmin
/// - empresa:rejected - Empresa rechazada por SuperAdmin
/// - empresa:updated - Empresa actualizada
class EmpresaRealtimeService {
  static EmpresaRealtimeService? _instance;
  
  HubConnection? _hubConnection;
  bool _isConnected = false;
  bool _isConnecting = false;
  
  // Stream controllers para eventos
  final StreamController<EmpresaEvent> _eventController = 
      StreamController<EmpresaEvent>.broadcast();
  
  // Callbacks registrados
  final List<Function(EmpresaEvent)> _listeners = [];
  
  EmpresaRealtimeService._();
  
  /// Obtener instancia singleton
  static EmpresaRealtimeService get instance {
    _instance ??= EmpresaRealtimeService._();
    return _instance!;
  }
  
  /// Stream de eventos de empresas
  Stream<EmpresaEvent> get eventStream => _eventController.stream;
  
  /// Estado de conexión
  bool get isConnected => _isConnected;
  
  /// Conectar al hub de SignalR
  Future<bool> connect() async {
    if (_isConnected || _isConnecting) return _isConnected;
    
    _isConnecting = true;
    
    try {
      final token = await StorageService().getAccessToken();
      if (token == null) {
        print('[EmpresaRealtimeService] No token available');
        _isConnecting = false;
        return false;
      }
      
      // Usamos TareaHub ya que maneja eventos de empresa también
      final hubUrl = '${ApiConfig.baseUrl}/tareahub';
      print('[EmpresaRealtimeService] Connecting to: $hubUrl');
      
      _hubConnection = HubConnectionBuilder()
          .withUrl(hubUrl, options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ))
          .withAutomaticReconnect()
          .build();
      
      // Configurar handlers de conexión
      _hubConnection!.onclose(({error}) {
        _isConnected = false;
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.connectionLost,
          message: 'Connection lost: ${error?.toString() ?? 'Unknown error'}',
        ));
      });
      
      _hubConnection!.onreconnecting(({error}) {
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.reconnecting,
          message: 'Reconnecting...',
        ));
      });
      
      _hubConnection!.onreconnected(({connectionId}) {
        _isConnected = true;
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.connected,
          message: 'Reconnected',
        ));
      });
      
      // Registrar handlers de eventos de empresas
      _registerEventHandlers();
      
      // Iniciar conexión
      await _hubConnection!.start();
      _isConnected = true;
      _isConnecting = false;
      
      print('[EmpresaRealtimeService] Connected successfully!');
      
      _emitEvent(EmpresaEvent(
        type: EmpresaEventType.connected,
        message: 'Connected to realtime server',
      ));
      
      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      print('[EmpresaRealtimeService] Connection error: $e');
      _emitEvent(EmpresaEvent(
        type: EmpresaEventType.connectionError,
        message: 'Connection error: $e',
      ));
      return false;
    }
  }
  
  /// Registrar handlers para eventos de empresas
  void _registerEventHandlers() {
    if (_hubConnection == null) return;
    
    // empresa:created - Nueva solicitud de empresa
    _hubConnection!.on('empresa:created', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.empresaCreated,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // empresa:approved - Empresa aprobada
    _hubConnection!.on('empresa:approved', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.empresaApproved,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // empresa:rejected - Empresa rechazada
    _hubConnection!.on('empresa:rejected', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.empresaRejected,
          data: _parseEventData(arguments[0]),
        ));
      }
    });
    
    // empresa:updated - Empresa actualizada
    _hubConnection!.on('empresa:updated', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        _emitEvent(EmpresaEvent(
          type: EmpresaEventType.empresaUpdated,
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
  void _emitEvent(EmpresaEvent event) {
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
  void addListener(Function(EmpresaEvent) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  /// Remover listener
  void removeListener(Function(EmpresaEvent) listener) {
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

/// Tipos de eventos de empresas
enum EmpresaEventType {
  // Eventos de conexión
  connected,
  connectionLost,
  connectionError,
  reconnecting,
  
  // Eventos de empresas
  empresaCreated,
  empresaApproved,
  empresaRejected,
  empresaUpdated,
}

/// Evento de empresa
class EmpresaEvent {
  final EmpresaEventType type;
  final Map<String, dynamic>? data;
  final String? message;
  final DateTime timestamp;
  
  EmpresaEvent({
    required this.type,
    this.data,
    this.message,
  }) : timestamp = DateTime.now();
  
  /// ID de la empresa
  String? get empresaId => data?['id']?.toString();
  
  /// Nombre de la empresa
  String? get nombre => data?['nombre']?.toString();
  
  /// Estado de la empresa
  String? get estado => data?['estado']?.toString();
  
  /// Es un evento de empresa (no de conexión)?
  bool get isEmpresaEvent => type == EmpresaEventType.empresaCreated ||
      type == EmpresaEventType.empresaApproved ||
      type == EmpresaEventType.empresaRejected ||
      type == EmpresaEventType.empresaUpdated;
  
  @override
  String toString() => 'EmpresaEvent($type, data: $data, message: $message)';
}
