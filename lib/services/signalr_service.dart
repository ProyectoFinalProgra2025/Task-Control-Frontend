import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/chat_model.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final StreamController<MessageModel> _messageController = StreamController<MessageModel>.broadcast();
  final StreamController<Map<String, dynamic>> _tareaEventController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _empresaEventController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _usuarioEventController = StreamController<Map<String, dynamic>>.broadcast();
  final Set<String> _joinedChats = {};
  final Set<String> _joinedGroups = {};
  
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get tareaEventStream => _tareaEventController.stream;
  Stream<Map<String, dynamic>> get empresaEventStream => _empresaEventController.stream;
  Stream<Map<String, dynamic>> get usuarioEventStream => _usuarioEventController.stream;

  // Connect to SignalR hub
  Future<void> connect(String accessToken) async {
    if (_hubConnection != null && isConnected) {
      print('SignalR: Already connected');
      return;
    }

    try {
      // Build the connection
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            '${ApiConfig.signalRHubUrl}?access_token=$accessToken',
            options: HttpConnectionOptions(
              accessTokenFactory: () => Future.value(accessToken),
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Set up event listeners
      _setupEventListeners();

      // Start the connection
      await _hubConnection!.start();
      print('SignalR: Connected successfully');
    } catch (e) {
      print('SignalR: Connection error: $e');
      throw Exception('Failed to connect to SignalR: $e');
    }
  }

  // Setup event listeners
  void _setupEventListeners() {
    if (_hubConnection == null) return;

    // ==================== CHAT EVENTS ====================
    _hubConnection!.on('chat:message', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final messageData = arguments[0] as Map<String, dynamic>;
          final message = MessageModel(
            id: messageData['id'] as String,
            chatId: messageData['chatId'] as String,
            senderId: messageData['senderId']?.toString() ?? '',
            body: messageData['body'] as String,
            createdAt: DateTime.parse(messageData['createdAt'] as String),
            isRead: messageData['isRead'] ?? false,
            readAt: messageData['readAt'] != null 
                ? DateTime.parse(messageData['readAt'] as String)
                : null,
          );
          
          _messageController.add(message);
          print('SignalR: Received message in chat ${message.chatId}');
        } catch (e) {
          print('SignalR: Error parsing message: $e');
        }
      }
    });

    // ==================== TAREA EVENTS ====================
    _hubConnection!.on('tarea:created', (arguments) {
      _handleTareaEvent('created', arguments);
    });

    _hubConnection!.on('tarea:assigned', (arguments) {
      _handleTareaEvent('assigned', arguments);
    });

    _hubConnection!.on('tarea:accepted', (arguments) {
      _handleTareaEvent('accepted', arguments);
    });

    _hubConnection!.on('tarea:completed', (arguments) {
      _handleTareaEvent('completed', arguments);
    });

    // ==================== EMPRESA EVENTS ====================
    _hubConnection!.on('empresa:created', (arguments) {
      _handleEmpresaEvent('created', arguments);
    });

    _hubConnection!.on('empresa:approved', (arguments) {
      _handleEmpresaEvent('approved', arguments);
    });

    _hubConnection!.on('empresa:rejected', (arguments) {
      _handleEmpresaEvent('rejected', arguments);
    });

    // ==================== CONNECTION STATE ====================
    _hubConnection!.onclose(({error}) {
      print('SignalR: Connection closed. Error: $error');
    });

    _hubConnection!.onreconnecting(({error}) {
      print('SignalR: Reconnecting... Error: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      print('SignalR: Reconnected with ID: $connectionId');
      _rejoinAll();
    });
  }

  // Handle tarea events
  void _handleTareaEvent(String eventType, List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      try {
        final data = arguments[0] as Map<String, dynamic>;
        data['eventType'] = eventType;
        _tareaEventController.add(data);
        print('SignalR: Received tarea:$eventType event');
      } catch (e) {
        print('SignalR: Error parsing tarea event: $e');
      }
    }
  }

  // Handle empresa events
  void _handleEmpresaEvent(String eventType, List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      try {
        final data = arguments[0] as Map<String, dynamic>;
        data['eventType'] = eventType;
        _empresaEventController.add(data);
        print('SignalR: Received empresa:$eventType event');
      } catch (e) {
        print('SignalR: Error parsing empresa event: $e');
      }
    }
  }

  // Join a chat room
  Future<void> joinChat(String chatId) async {
    if (_hubConnection == null || !isConnected) {
      throw Exception('SignalR not connected. Call connect() first.');
    }

    try {
      await _hubConnection!.invoke('JoinChat', args: [chatId]);
      _joinedChats.add(chatId);
      print('SignalR: Joined chat $chatId');
    } catch (e) {
      print('SignalR: Error joining chat $chatId: $e');
      throw Exception('Failed to join chat: $e');
    }
  }

  // Leave a chat room
  Future<void> leaveChat(String chatId) async {
    if (_hubConnection == null || !isConnected) {
      print('SignalR: Not connected, skipping leaveChat');
      return;
    }

    try {
      await _hubConnection!.invoke('LeaveChat', args: [chatId]);
      _joinedChats.remove(chatId);
      print('SignalR: Left chat $chatId');
    } catch (e) {
      print('SignalR: Error leaving chat $chatId: $e');
    }
  }

  // ==================== GROUP MANAGEMENT ====================
  
  // Join super admin group
  Future<void> joinSuperAdminGroup() async {
    if (_hubConnection == null || !isConnected) {
      throw Exception('SignalR not connected');
    }

    try {
      await _hubConnection!.invoke('JoinSuperAdminGroup');
      _joinedGroups.add('super_admin');
      print('SignalR: Joined super_admin group');
    } catch (e) {
      print('SignalR: Error joining super_admin group: $e');
      rethrow;
    }
  }

  // Leave super admin group
  Future<void> leaveSuperAdminGroup() async {
    if (_hubConnection == null || !isConnected) return;

    try {
      await _hubConnection!.invoke('LeaveSuperAdminGroup');
      _joinedGroups.remove('super_admin');
      print('SignalR: Left super_admin group');
    } catch (e) {
      print('SignalR: Error leaving super_admin group: $e');
    }
  }

  // Join empresa group
  Future<void> joinEmpresaGroup(String empresaId) async {
    if (_hubConnection == null || !isConnected) {
      throw Exception('SignalR not connected');
    }

    try {
      await _hubConnection!.invoke('JoinEmpresaGroup', args: [empresaId]);
      _joinedGroups.add('empresa_$empresaId');
      print('SignalR: Joined empresa_$empresaId group');
    } catch (e) {
      print('SignalR: Error joining empresa group: $e');
      rethrow;
    }
  }

  // Leave empresa group
  Future<void> leaveEmpresaGroup(String empresaId) async {
    if (_hubConnection == null || !isConnected) return;

    try {
      await _hubConnection!.invoke('LeaveEmpresaGroup', args: [empresaId]);
      _joinedGroups.remove('empresa_$empresaId');
      print('SignalR: Left empresa_$empresaId group');
    } catch (e) {
      print('SignalR: Error leaving empresa group: $e');
    }
  }

  // Rejoin all groups and chats after reconnection
  Future<void> _rejoinAll() async {
    // Rejoin chats
    final chatsToRejoin = List<String>.from(_joinedChats);
    for (final chatId in chatsToRejoin) {
      try {
        await joinChat(chatId);
      } catch (e) {
        print('SignalR: Error rejoining chat $chatId: $e');
      }
    }

    // Rejoin groups
    final groupsToRejoin = List<String>.from(_joinedGroups);
    for (final group in groupsToRejoin) {
      try {
        if (group == 'super_admin') {
          await joinSuperAdminGroup();
        } else if (group.startsWith('empresa_')) {
          final empresaId = group.substring(8);
          await joinEmpresaGroup(empresaId);
        }
      } catch (e) {
        print('SignalR: Error rejoining group $group: $e');
      }
    }
  }

  // Disconnect from hub
  Future<void> disconnect() async {
    if (_hubConnection == null) return;

    try {
      // Leave all chats
      for (final chatId in List<String>.from(_joinedChats)) {
        await leaveChat(chatId);
      }

      // Leave all groups
      for (final group in List<String>.from(_joinedGroups)) {
        if (group == 'super_admin') {
          await leaveSuperAdminGroup();
        } else if (group.startsWith('empresa_')) {
          final empresaId = group.substring(8);
          await leaveEmpresaGroup(empresaId);
        }
      }

      await _hubConnection!.stop();
      _joinedChats.clear();
      _joinedGroups.clear();
      print('SignalR: Disconnected successfully');
    } catch (e) {
      print('SignalR: Error during disconnect: $e');
    } finally {
      _hubConnection = null;
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _tareaEventController.close();
    _empresaEventController.close();
    _usuarioEventController.close();
  }
}
