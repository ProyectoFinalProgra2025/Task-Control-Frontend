import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/tarea_realtime_service.dart';

/// Mixin para agregar funcionalidad de realtime a pantallas de tareas.
/// 
/// Uso:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with TareaRealtimeMixin {
///   @override
///   void initState() {
///     super.initState();
///     initRealtime(); // Conectar al iniciar
///   }
///   
///   @override
///   void dispose() {
///     disposeRealtime();
///     super.dispose();
///   }
///   
///   @override
///   void onTareaEvent(TareaEvent event) {
///     if (event.type == TareaEventType.tareaCreated) {
///       // Actualizar lista de tareas
///     }
///   }
/// }
/// ```
mixin TareaRealtimeMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<TareaEvent>? _realtimeSubscription;
  bool _realtimeConnected = false;
  
  /// Estado de conexión realtime
  bool get isRealtimeConnected => _realtimeConnected;
  
  /// Servicio de realtime
  TareaRealtimeService get realtimeService => TareaRealtimeService.instance;
  
  /// Inicializar conexión realtime
  Future<void> initRealtime() async {
    // Suscribirse a eventos PRIMERO
    _realtimeSubscription = realtimeService.eventStream.listen((event) {
      if (!mounted) return;
      
      // Actualizar estado de conexión
      if (event.type == TareaEventType.connected) {
        _realtimeConnected = true;
        if (mounted) setState(() {});
      } else if (event.type == TareaEventType.connectionLost ||
                 event.type == TareaEventType.connectionError ||
                 event.type == TareaEventType.reconnecting) {
        _realtimeConnected = false;
        if (mounted) setState(() {});
      }
      
      // Notificar a la subclase
      onTareaEvent(event);
    });
    
    // Conectar al servicio
    _realtimeConnected = await realtimeService.connect();
    
    // Actualizar UI con el resultado de la conexión
    if (mounted) setState(() {});
  }
  
  /// Callback para eventos de tareas - Override en subclases
  void onTareaEvent(TareaEvent event) {
    // Override en subclases para manejar eventos
  }
  
  /// Limpiar suscripción (llamar en dispose)
  void disposeRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }
  
  /// Reconectar manualmente
  Future<void> reconnectRealtime() async {
    await realtimeService.disconnect();
    _realtimeConnected = await realtimeService.connect();
    if (mounted) setState(() {});
  }
}

/// Widget que muestra indicador de conexión realtime
class RealtimeConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onReconnect;
  final Color? connectedColor;
  final Color? disconnectedColor;
  
  const RealtimeConnectionIndicator({
    super.key,
    required this.isConnected,
    this.onReconnect,
    this.connectedColor,
    this.disconnectedColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !isConnected ? onReconnect : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isConnected 
              ? (connectedColor ?? const Color(0xFF22C55E)).withOpacity(0.1)
              : (disconnectedColor ?? const Color(0xFFEF4444)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected 
                    ? (connectedColor ?? const Color(0xFF22C55E))
                    : (disconnectedColor ?? const Color(0xFFEF4444)),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'Live' : 'Offline',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isConnected 
                    ? (connectedColor ?? const Color(0xFF22C55E))
                    : (disconnectedColor ?? const Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
