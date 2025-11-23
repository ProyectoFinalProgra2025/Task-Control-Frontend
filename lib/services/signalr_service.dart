import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/chat_model.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final StreamController<MessageModel> _messageController = StreamController<MessageModel>.broadcast();
  final Set<String> _joinedChats = {};
  
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Stream<MessageModel> get messageStream => _messageController.stream;

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

    // Listen for incoming messages
    _hubConnection!.on('chat:message', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          final messageData = arguments[0] as Map<String, dynamic>;
          final message = MessageModel(
            id: messageData['id'] as String,
            chatId: messageData['chatId'] as String,
            senderId: messageData['senderId'] as int,
            body: messageData['body'] as String,
            createdAt: DateTime.parse(messageData['createdAt'] as String),
          );
          
          _messageController.add(message);
          print('SignalR: Received message in chat ${message.chatId}');
        } catch (e) {
          print('SignalR: Error parsing message: $e');
        }
      }
    });

    // Connection state listeners
    _hubConnection!.onclose(({error}) {
      print('SignalR: Connection closed. Error: $error');
    });

    _hubConnection!.onreconnecting(({error}) {
      print('SignalR: Reconnecting... Error: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      print('SignalR: Reconnected with ID: $connectionId');
      // Rejoin all previously joined chats
      _rejoinChats();
    });
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

  // Rejoin all chats after reconnection
  Future<void> _rejoinChats() async {
    final chatsToRejoin = List<String>.from(_joinedChats);
    for (final chatId in chatsToRejoin) {
      try {
        await joinChat(chatId);
      } catch (e) {
        print('SignalR: Error rejoining chat $chatId: $e');
      }
    }
  }

  // Disconnect from hub
  Future<void> disconnect() async {
    if (_hubConnection == null) return;

    try {
      // Leave all chats first
      for (final chatId in List<String>.from(_joinedChats)) {
        await leaveChat(chatId);
      }

      await _hubConnection!.stop();
      _joinedChats.clear();
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
  }
}
