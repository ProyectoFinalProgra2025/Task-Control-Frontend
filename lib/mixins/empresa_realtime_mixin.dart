import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/empresa_realtime_service.dart';

/// Mixin para agregar funcionalidad de realtime a pantallas de empresas (SuperAdmin).
/// 
/// Uso:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with EmpresaRealtimeMixin {
///   @override
///   void initState() {
///     super.initState();
///     initEmpresaRealtime(); // Conectar al iniciar
///   }
///   
///   @override
///   void dispose() {
///     disposeEmpresaRealtime();
///     super.dispose();
///   }
///   
///   @override
///   void onEmpresaEvent(EmpresaEvent event) {
///     if (event.type == EmpresaEventType.empresaCreated) {
///       // Nueva solicitud de empresa - actualizar lista
///       _loadEmpresas();
///     }
///   }
/// }
/// ```
mixin EmpresaRealtimeMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<EmpresaEvent>? _empresaRealtimeSubscription;
  bool _empresaRealtimeConnected = false;
  
  /// Estado de conexión realtime para empresas
  bool get isEmpresaRealtimeConnected => _empresaRealtimeConnected;
  
  /// Servicio de realtime para empresas
  EmpresaRealtimeService get empresaRealtimeService => EmpresaRealtimeService.instance;
  
  /// Inicializar conexión realtime para empresas
  Future<void> initEmpresaRealtime() async {
    // Suscribirse a eventos PRIMERO
    _empresaRealtimeSubscription = empresaRealtimeService.eventStream.listen((event) {
      if (!mounted) return;
      
      // Actualizar estado de conexión
      if (event.type == EmpresaEventType.connected) {
        _empresaRealtimeConnected = true;
        if (mounted) setState(() {});
      } else if (event.type == EmpresaEventType.connectionLost ||
                 event.type == EmpresaEventType.connectionError ||
                 event.type == EmpresaEventType.reconnecting) {
        _empresaRealtimeConnected = false;
        if (mounted) setState(() {});
      }
      
      // Notificar a la subclase
      onEmpresaEvent(event);
    });
    
    // Conectar al servicio
    _empresaRealtimeConnected = await empresaRealtimeService.connect();
    
    // Actualizar UI con el resultado de la conexión
    if (mounted) setState(() {});
  }
  
  /// Callback para eventos de empresas - Override en subclases
  void onEmpresaEvent(EmpresaEvent event) {
    // Override en subclases para manejar eventos
  }
  
  /// Limpiar suscripción (llamar en dispose)
  void disposeEmpresaRealtime() {
    _empresaRealtimeSubscription?.cancel();
    _empresaRealtimeSubscription = null;
  }
  
  /// Reconectar manualmente
  Future<void> reconnectEmpresaRealtime() async {
    await empresaRealtimeService.disconnect();
    _empresaRealtimeConnected = await empresaRealtimeService.connect();
    if (mounted) setState(() {});
  }
}

/// Widget que muestra indicador de conexión realtime para empresas
class EmpresaRealtimeConnectionIndicator extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onReconnect;
  final Color? connectedColor;
  final Color? disconnectedColor;
  
  const EmpresaRealtimeConnectionIndicator({
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
