import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/signalr_service.dart';
import '../services/storage_service.dart';

/// Provider for handling real-time events across the app
/// Manages SignalR connection and broadcasts events to listeners
class RealtimeProvider with ChangeNotifier {
  final SignalRService _signalRService = SignalRService();
  final StorageService _storage = StorageService();
  
  StreamSubscription? _tareaEventSubscription;
  StreamSubscription? _empresaEventSubscription;
  StreamSubscription? _usuarioEventSubscription;

  bool _isConnected = false;
  String? _error;
  Map<String, dynamic>? _lastTareaEvent;
  Map<String, dynamic>? _lastEmpresaEvent;
  Map<String, dynamic>? _lastUsuarioEvent;

  // Getters
  bool get isConnected => _isConnected;
  String? get error => _error;
  Map<String, dynamic>? get lastTareaEvent => _lastTareaEvent;
  Map<String, dynamic>? get lastEmpresaEvent => _lastEmpresaEvent;
  Map<String, dynamic>? get lastUsuarioEvent => _lastUsuarioEvent;

  // Event streams for direct subscription
  Stream<Map<String, dynamic>> get tareaEventStream => _signalRService.tareaEventStream;
  Stream<Map<String, dynamic>> get empresaEventStream => _signalRService.empresaEventStream;
  Stream<Map<String, dynamic>> get usuarioEventStream => _signalRService.usuarioEventStream;

  RealtimeProvider() {
    _subscribeToEvents();
  }

  // Subscribe to all real-time events
  void _subscribeToEvents() {
    _tareaEventSubscription = _signalRService.tareaEventStream.listen(
      (event) {
        _lastTareaEvent = event;
        print('RealtimeProvider: Tarea event received: ${event['eventType']}');
        notifyListeners();
      },
      onError: (error) {
        print('RealtimeProvider: Error in tarea event stream: $error');
      },
    );

    _empresaEventSubscription = _signalRService.empresaEventStream.listen(
      (event) {
        _lastEmpresaEvent = event;
        print('RealtimeProvider: Empresa event received: ${event['eventType']}');
        notifyListeners();
      },
      onError: (error) {
        print('RealtimeProvider: Error in empresa event stream: $error');
      },
    );

    _usuarioEventSubscription = _signalRService.usuarioEventStream.listen(
      (event) {
        _lastUsuarioEvent = event;
        print('RealtimeProvider: Usuario event received: ${event['eventType']}');
        notifyListeners();
      },
      onError: (error) {
        print('RealtimeProvider: Error in usuario event stream: $error');
      },
    );
  }

  // Connect to SignalR and join appropriate groups
  Future<void> connect({bool isSuperAdmin = false, String? empresaId}) async {
    if (_isConnected) {
      print('RealtimeProvider: ✅ Already connected');
      return;
    }

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      // Connect to SignalR
      await _signalRService.connect(token);
      print('RealtimeProvider: ✅ SignalR connected');

      // Join groups based on role (optional - may fail if backend is old version)
      if (isSuperAdmin) {
        try {
          await _signalRService.joinSuperAdminGroup();
          print('RealtimeProvider: ✅ Joined super admin group');
        } catch (e) {
          print('RealtimeProvider: ⚠️ Super admin group not available: $e');
          // Continue anyway - basic SignalR still works
        }
      }

      if (empresaId != null) {
        try {
          await _signalRService.joinEmpresaGroup(empresaId);
          print('RealtimeProvider: ✅ Joined empresa group $empresaId');
        } catch (e) {
          print('RealtimeProvider: ⚠️ Empresa group not available: $e');
          // Continue anyway
        }
      }

      _isConnected = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to connect: $e';
      _isConnected = false;
      print('RealtimeProvider: ❌ Connection error: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Disconnect from SignalR
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      await _signalRService.disconnect();
      _isConnected = false;
      _lastTareaEvent = null;
      _lastEmpresaEvent = null;
      _lastUsuarioEvent = null;
      notifyListeners();
    } catch (e) {
      print('RealtimeProvider: Disconnect error: $e');
    }
  }

  // Clear last events
  void clearLastEvents() {
    _lastTareaEvent = null;
    _lastEmpresaEvent = null;
    _lastUsuarioEvent = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tareaEventSubscription?.cancel();
    _empresaEventSubscription?.cancel();
    _usuarioEventSubscription?.cancel();
    _signalRService.dispose();
    super.dispose();
  }
}
