import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat/chat_models.dart';
import '../services/chat_service.dart';
import '../services/chat_hub_service.dart';
import '../services/storage_service.dart';

/// ChatProvider sincronizado con el backend
/// Usa ChatService para HTTP y ChatHubService para SignalR
class ChatProvider extends ChangeNotifier {
  final ChatHubService hub;
  final ChatService _api = ChatService();
  final StorageService _storage = StorageService();

  ChatProvider({required this.hub});

  String? _token;
  String? _userId;
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _deliveredSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<bool>? _connSub;

  bool _loading = false;
  bool _connected = false;
  List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messages = {};
  String? _activeConversationId;
  
  // Usuarios escribiendo por conversación
  final Map<String, Set<String>> _typingUsers = {};

  // Getters
  bool get loading => _loading;
  bool get connected => _connected;
  List<Conversation> get conversations => _conversations;
  String? get userId => _userId;
  String? get activeConversationId => _activeConversationId;

  List<ChatMessage> get activeMessages {
    if (_activeConversationId == null) return [];
    return _messages[_activeConversationId] ?? [];
  }

  int get totalUnreadCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  /// Obtener usuarios que están escribiendo en la conversación activa
  Set<String> get typingUsersInActiveConversation {
    if (_activeConversationId == null) return {};
    return _typingUsers[_activeConversationId] ?? {};
  }

  /// Inicializar con token del usuario
  Future<void> initialize() async {
    print('[ChatProvider] Inicializando...');
    final token = await _storage.getAccessToken();
    final userData = await _storage.getUserData();
    final userId = userData?['id']?.toString();

    if (token == null || userId == null) {
      print('[ChatProvider] No hay token o userId');
      return;
    }
    if (_token == token && _connected) {
      print('[ChatProvider] Ya inicializado con el mismo token');
      return;
    }

    _token = token;
    _userId = userId;
    print('[ChatProvider] UserId: $_userId');

    // Conectar hub
    final ok = await hub.connect(token);
    if (!ok) {
      print('[ChatProvider] ❌ Error conectando al hub');
      return;
    }

    // Suscribirse a streams (DESPUÉS de conectar exitosamente)
    await _cancelSubscriptions();

    _msgSub = hub.onMessage.listen(_handleMessage);
    _deliveredSub = hub.onMessageDelivered.listen(_handleDelivered);
    _readSub = hub.onMessageRead.listen(_handleRead);
    _typingSub = hub.onTyping.listen(_handleTyping);
    _connSub = hub.onConnectionStateChanged.listen((connected) {
      _connected = connected;
      notifyListeners();
    });

    _connected = true;
    notifyListeners();

    // Cargar conversaciones
    await loadConversations();
    print('[ChatProvider] ✅ Inicializado correctamente');
  }

  Future<void> _cancelSubscriptions() async {
    await _msgSub?.cancel();
    await _deliveredSub?.cancel();
    await _readSub?.cancel();
    await _typingSub?.cancel();
    await _connSub?.cancel();
  }

  /// Cargar conversaciones
  Future<void> loadConversations() async {
    if (_token == null) return;
    _loading = true;
    notifyListeners();

    try {
      _conversations = await _api.getConversations();
      print('[ChatProvider] Cargadas ${_conversations.length} conversaciones');
    } catch (e) {
      print('[ChatProvider] Error cargando conversaciones: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Buscar usuarios para iniciar chat
  Future<List<ChatUserSearchResult>> searchUsers(String query) async {
    return await _api.searchUsers(query);
  }

  /// Crear o obtener conversación directa con un usuario
  Future<String?> getOrCreateDirectConversation(String otherUserId) async {
    final conversationId = await _api.getOrCreateDirectConversation(otherUserId);
    if (conversationId != null) {
      await loadConversations(); // Refrescar lista
    }
    return conversationId;
  }

  /// Crear conversación grupal
  Future<String?> createGroupConversation(
    String groupName,
    List<String> memberIds, {
    String? imageUrl,
  }) async {
    final conversationId = await _api.createGroupConversation(
      groupName, 
      memberIds, 
      imageUrl: imageUrl,
    );
    if (conversationId != null) {
      await loadConversations(); // Refrescar lista
    }
    return conversationId;
  }

  /// Entrar a conversación
  Future<void> enterConversation(String id) async {
    print('[ChatProvider] Entrando a conversación: $id');
    _activeConversationId = id;
    await hub.joinConversation(id);
    await loadMessages(id);
    await markAllRead(id);
    notifyListeners();
  }

  /// Salir de conversación
  Future<void> leaveConversation() async {
    if (_activeConversationId != null) {
      print('[ChatProvider] Saliendo de conversación: $_activeConversationId');
      await hub.leaveConversation(_activeConversationId!);
      _activeConversationId = null;
      notifyListeners();
    }
  }

  /// Cargar mensajes
  Future<void> loadMessages(String conversationId, {int skip = 0, int take = 50}) async {
    if (_token == null) return;
    try {
      final msgs = await _api.getMessages(conversationId, skip: skip, take: take);
      
      if (skip == 0) {
        _messages[conversationId] = msgs;
      } else {
        // Cargar más mensajes (paginación)
        _messages[conversationId] = [...(_messages[conversationId] ?? []), ...msgs];
      }
      
      print('[ChatProvider] Cargados ${msgs.length} mensajes para conversación $conversationId');
      notifyListeners();
    } catch (e) {
      print('[ChatProvider] Error cargando mensajes: $e');
    }
  }

  /// Enviar mensaje
  Future<void> sendMessage(String text, {String? replyToMessageId}) async {
    if (_activeConversationId == null || text.trim().isEmpty) return;
    
    try {
      final msg = await _api.sendMessage(
        _activeConversationId!, 
        text.trim(),
        replyToMessageId: replyToMessageId,
      );
      if (msg != null) {
        _appendMessage(_activeConversationId!, msg);
        print('[ChatProvider] ✅ Mensaje enviado: ${msg.id}');
      }
    } catch (e) {
      print('[ChatProvider] Error enviando mensaje: $e');
    }
  }

  /// Editar mensaje
  Future<bool> editMessage(String messageId, String newContent) async {
    final success = await _api.editMessage(messageId, newContent);
    if (success) {
      // Actualizar mensaje localmente
      for (final entry in _messages.entries) {
        final idx = entry.value.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          // Recargar mensajes para obtener la versión actualizada
          await loadMessages(entry.key);
          break;
        }
      }
    }
    return success;
  }

  /// Eliminar mensaje
  Future<bool> deleteMessage(String messageId) async {
    final success = await _api.deleteMessage(messageId);
    if (success) {
      // Remover mensaje localmente
      for (final entry in _messages.entries) {
        entry.value.removeWhere((m) => m.id == messageId);
      }
      notifyListeners();
    }
    return success;
  }

  /// Enviar indicador de escritura
  Future<void> sendTypingIndicator() async {
    if (_activeConversationId == null) return;
    await hub.sendTypingIndicator(_activeConversationId!);
  }

  /// Marcar todos como leídos
  Future<void> markAllRead(String conversationId) async {
    final msgs = _messages[conversationId];
    if (msgs == null || msgs.isEmpty) return;

    for (final m in msgs) {
      if (m.senderId != _userId && m.status != MessageStatus.read) {
        await _api.markMessageRead(m.id);
      }
    }
    
    // Actualizar contador local
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      await loadConversations(); // Refrescar para actualizar contadores
    }
  }

  /// Handlers de eventos SignalR
  void _handleMessage(Map<String, dynamic> data) {
    try {
      print('[ChatProvider] 📨 Mensaje recibido: $data');
      final msg = ChatMessage.fromJson(data);
      _appendMessage(msg.conversationId, msg);

      // Marcar como delivered
      if (msg.senderId != _userId) {
        _api.markMessageDelivered(msg.id);

        // Marcar como read si está en conversación activa
        if (_activeConversationId == msg.conversationId) {
          _api.markMessageRead(msg.id);
        }
      }

      // Actualizar lista de conversaciones
      loadConversations();
    } catch (e) {
      print('[ChatProvider] Error procesando mensaje: $e');
    }
  }

  void _handleDelivered(Map<String, dynamic> data) {
    final msgId = data['messageId']?.toString();
    if (msgId == null) return;
    print('[ChatProvider] ✓ Mensaje entregado: $msgId');
    _updateMessageStatus(msgId, MessageStatus.delivered);
  }

  void _handleRead(Map<String, dynamic> data) {
    final msgId = data['messageId']?.toString();
    if (msgId == null) return;
    print('[ChatProvider] ✓✓ Mensaje leído: $msgId');
    _updateMessageStatus(msgId, MessageStatus.read);
  }

  void _handleTyping(Map<String, dynamic> data) {
    final conversationId = data['conversationId']?.toString();
    final senderId = data['senderId']?.toString();
    final senderName = data['senderName']?.toString() ?? 'Usuario';
    final isTyping = data['isTyping'] == true;
    
    if (conversationId == null || senderId == null) return;
    if (senderId == _userId) return; // Ignorar propios eventos
    
    print('[ChatProvider] ⌨️ Typing: $senderName (typing: $isTyping)');
    
    _typingUsers.putIfAbsent(conversationId, () => {});
    
    if (isTyping) {
      _typingUsers[conversationId]!.add(senderName);
    } else {
      _typingUsers[conversationId]!.remove(senderName);
    }
    
    notifyListeners();
    
    // Auto-limpiar después de 5 segundos si no hay actualización
    if (isTyping) {
      Future.delayed(const Duration(seconds: 5), () {
        _typingUsers[conversationId]?.remove(senderName);
        notifyListeners();
      });
    }
  }

  void _appendMessage(String conversationId, ChatMessage msg) {
    final list = _messages.putIfAbsent(conversationId, () => []);
    if (!list.any((m) => m.id == msg.id)) {
      // Insertar al principio (mensajes más recientes primero)
      list.insert(0, msg);
      notifyListeners();
    }
  }

  void _updateMessageStatus(String msgId, MessageStatus status) {
    for (final entry in _messages.entries) {
      final list = entry.value;
      final idx = list.indexWhere((m) => m.id == msgId);
      if (idx != -1) {
        final old = list[idx];
        list[idx] = old.copyWithStatus(status);
        notifyListeners();
        return;
      }
    }
  }

  /// Reiniciar provider (para logout)
  Future<void> reset() async {
    await _cancelSubscriptions();
    await hub.disconnect();
    _token = null;
    _userId = null;
    _connected = false;
    _conversations = [];
    _messages.clear();
    _activeConversationId = null;
    _typingUsers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
