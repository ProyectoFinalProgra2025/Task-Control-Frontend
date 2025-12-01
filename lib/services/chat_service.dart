import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat/chat_models.dart';
import 'storage_service.dart';

/// Servicio para operaciones HTTP del chat
/// Sincronizado con ChatController del backend
class ChatService {
  final StorageService _storage = StorageService();

  /// Headers con autorización
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== USERS SEARCH ====================

  /// Buscar usuarios para chatear
  /// GET /api/chat/users/search?term=xxx
  Future<List<ChatUserSearchResult>> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/users/search?term=${Uri.encodeComponent(query)}');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((u) => ChatUserSearchResult.fromJson(u)).toList();
      }
      print('[ChatService] searchUsers status: ${response.statusCode}');
      return [];
    } catch (e) {
      print('[ChatService] Error searching users: $e');
      return [];
    }
  }

  // ==================== CONVERSATIONS ====================

  /// Obtener todas las conversaciones del usuario
  /// GET /api/chat/conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((c) => Conversation.fromJson(c)).toList();
      }
      print('[ChatService] getConversations status: ${response.statusCode}');
      return [];
    } catch (e) {
      print('[ChatService] Error getting conversations: $e');
      return [];
    }
  }

  /// Obtener una conversación específica
  /// GET /api/chat/conversations/{id}
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/$conversationId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Conversation.fromJson(data);
      }
      print('[ChatService] getConversation status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[ChatService] Error getting conversation: $e');
      return null;
    }
  }

  /// Crear o obtener conversación directa (1:1)
  /// POST /api/chat/conversations/direct
  /// Body: { "recipientUserId": "guid" }
  Future<String?> getOrCreateDirectConversation(String otherUserId) async {
    try {
      final headers = await _getHeaders();
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/direct');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'recipientUserId': otherUserId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['conversationId']?.toString();
      }
      print(
          '[ChatService] createDirectConversation status: ${response.statusCode}');
      print('[ChatService] createDirectConversation body: ${response.body}');
      return null;
    } catch (e) {
      print('[ChatService] Error creating direct conversation: $e');
      return null;
    }
  }

  /// Crear conversación grupal
  /// POST /api/chat/conversations/group
  /// Body: { "name": "string", "memberIds": ["guid1", "guid2"], "imageUrl": "string" }
  Future<String?> createGroupConversation(
    String groupName,
    List<String> memberIds, {
    String? imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/group');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'name': groupName,
          'memberIds': memberIds,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['conversationId']?.toString();
      }
      print(
          '[ChatService] createGroupConversation status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[ChatService] Error creating group conversation: $e');
      return null;
    }
  }

  /// Actualizar conversación (nombre, imagen)
  /// PUT /api/chat/conversations/{id}
  /// Body: { "name": "string", "imageUrl": "string" }
  Future<bool> updateConversation(
    String conversationId, {
    String? name,
    String? imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/conversations/$conversationId');

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error updating conversation: $e');
      return false;
    }
  }

  // ==================== MESSAGES ====================

  /// Obtener mensajes de una conversación
  /// GET /api/chat/conversations/{id}/messages?skip=0&take=50
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int skip = 0,
    int take = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/messages?skip=$skip&take=$take');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((m) => ChatMessage.fromJson(m)).toList();
      }
      print('[ChatService] getMessages status: ${response.statusCode}');
      return [];
    } catch (e) {
      print('[ChatService] Error getting messages: $e');
      return [];
    }
  }

  /// Enviar mensaje de texto
  /// POST /api/chat/conversations/{id}/messages
  /// Body: { "content": "string", "replyToMessageId": "guid" }
  Future<ChatMessage?> sendMessage(
    String conversationId,
    String content, {
    String? replyToMessageId,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/messages');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'content': content,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data);
      }
      print('[ChatService] sendMessage status: ${response.statusCode}');
      print('[ChatService] sendMessage body: ${response.body}');
      return null;
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      return null;
    }
  }

  /// Editar mensaje
  /// PUT /api/chat/messages/{id}
  /// Body: { "content": "string" }
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/$messageId');

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode({'content': newContent}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error editing message: $e');
      return false;
    }
  }

  /// Eliminar mensaje
  /// DELETE /api/chat/messages/{id}
  Future<bool> deleteMessage(String messageId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/$messageId');

      final response = await http.delete(uri, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error deleting message: $e');
      return false;
    }
  }

  // ==================== READ/DELIVERY STATUS ====================

  /// Marcar mensaje como entregado
  /// POST /api/chat/messages/{id}/delivered
  Future<bool> markMessageDelivered(String messageId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/messages/$messageId/delivered');

      final response = await http.post(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error marking message delivered: $e');
      return false;
    }
  }

  /// Marcar mensaje como leído
  /// POST /api/chat/messages/{id}/read
  Future<bool> markMessageRead(String messageId) async {
    try {
      final headers = await _getHeaders();
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/$messageId/read');

      final response = await http.post(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error marking message read: $e');
      return false;
    }
  }

  /// Marcar todos los mensajes de una conversación como leídos
  /// POST /api/chat/conversations/{id}/read-all
  Future<int> markAllMessagesRead(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/read-all');

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('[ChatService] Error marking all messages read: $e');
      return 0;
    }
  }

  /// Obtener conteo de mensajes no leídos
  /// GET /api/chat/conversations/{id}/unread-count
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/unread-count');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('[ChatService] Error getting unread count: $e');
      return 0;
    }
  }
}
