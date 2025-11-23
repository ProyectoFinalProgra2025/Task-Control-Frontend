import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/signalr_service.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SignalRService _signalRService = SignalRService();
  final StorageService _storage = StorageService();

  List<ChatModel> _chats = [];
  final Map<String, List<MessageModel>> _messagesByChat = {};
  bool _isLoading = false;
  String? _error;
  ChatModel? _currentChat;
  StreamSubscription? _messageSubscription;

  // Getters
  List<ChatModel> get chats => _chats;
  Map<String, List<MessageModel>> get messagesByChat => _messagesByChat;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ChatModel? get currentChat => _currentChat;
  bool get isSignalRConnected => _signalRService.isConnected;

  ChatProvider() {
    _initializeCurrentUser();
    _subscribeToMessages();
  }

  Future<void> _initializeCurrentUser() async {
    final userData = await _storage.getUserData();
    if (userData != null) {
      // Inicialización del usuario actual
      // En el futuro, usar para filtrar mensajes propios
    }
  }

  // Subscribe to SignalR messages
  void _subscribeToMessages() {
    _messageSubscription = _signalRService.messageStream.listen(
      (message) {
        addIncomingMessage(message);
      },
      onError: (error) {
        print('ChatProvider: Error in message stream: $error');
      },
    );
  }

  // Connect to SignalR
  Future<void> connectSignalR() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      await _signalRService.connect(token);
      notifyListeners();
    } catch (e) {
      print('ChatProvider: Failed to connect SignalR: $e');
      _error = 'Failed to connect to chat service';
      notifyListeners();
    }
  }

  // Disconnect from SignalR
  Future<void> disconnectSignalR() async {
    await _signalRService.disconnect();
    notifyListeners();
  }

  // Load all chats
  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _chatService.getChats();
      _error = null;
    } catch (e) {
      _error = 'Failed to load chats: $e';
      print('ChatProvider: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load messages for a specific chat
  Future<void> loadMessages(String chatId, {int skip = 0, int take = 50}) async {
    try {
      final messages = await _chatService.getMessages(chatId, skip: skip, take: take);
      _messagesByChat[chatId] = messages;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load messages: $e';
      print('ChatProvider: $_error');
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String text) async {
    try {
      await _chatService.sendMessage(chatId, text);
      // Don't add to local cache - wait for SignalR to broadcast it back
      // This prevents duplicate messages
      _error = null;
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('ChatProvider: $_error');
      notifyListeners();
      rethrow;
    }
  }

  // Add incoming message from SignalR
  void addIncomingMessage(MessageModel message) {
    // Add to messages cache
    if (_messagesByChat[message.chatId] != null) {
      // Check if message already exists (from optimistic update)
      final exists = _messagesByChat[message.chatId]!.any((m) => m.id == message.id);
      if (!exists) {
        _messagesByChat[message.chatId]!.add(message);
      }
    }

    // Update last message in chat list
    final chatIndex = _chats.indexWhere((c) => c.id == message.chatId);
    if (chatIndex != -1) {
      // Update the chat's last message and move to top
      final updatedChat = ChatModel(
        id: _chats[chatIndex].id,
        type: _chats[chatIndex].type,
        name: _chats[chatIndex].name,
        members: _chats[chatIndex].members,
        lastMessage: message,
        createdAt: _chats[chatIndex].createdAt,
      );
      
      _chats.removeAt(chatIndex);
      _chats.insert(0, updatedChat);
    }

    notifyListeners();
  }

  // Create 1:1 chat
  Future<ChatModel> createOneToOneChat(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final chat = await _chatService.createOneToOneChat(userId);
      
      // Add to local list if not already present
      if (!_chats.any((c) => c.id == chat.id)) {
        _chats.insert(0, chat);
      }

      _error = null;
      return chat;
    } catch (e) {
      _error = 'Failed to create chat: $e';
      print('ChatProvider: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create group chat
  Future<ChatModel> createGroupChat(String name, List<String> memberIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final chat = await _chatService.createGroupChat(name, memberIds);
      
      // Add to local list
      _chats.insert(0, chat);

      _error = null;
      return chat;
    } catch (e) {
      _error = 'Failed to create group chat: $e';
      print('ChatProvider: $_error');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search users
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      return await _chatService.searchUsers(query);
    } catch (e) {
      print('ChatProvider: Failed to search users: $e');
      return [];
    }
  }

  // Set current chat
  void setCurrentChat(ChatModel? chat) {
    _currentChat = chat;
    notifyListeners();
  }

  // Join chat room via SignalR
  Future<void> joinChatRoom(String chatId) async {
    try {
      if (!_signalRService.isConnected) {
        await connectSignalR();
      }
      await _signalRService.joinChat(chatId);
    } catch (e) {
      print('ChatProvider: Failed to join chat room: $e');
    }
  }

  // Leave chat room via SignalR
  Future<void> leaveChatRoom(String chatId) async {
    try {
      await _signalRService.leaveChat(chatId);
    } catch (e) {
      print('ChatProvider: Failed to leave chat room: $e');
    }
  }

  // Get messages for a chat (from cache or load)
  List<MessageModel> getMessages(String chatId) {
    return _messagesByChat[chatId] ?? [];
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _signalRService.dispose();
    super.dispose();
  }
}
