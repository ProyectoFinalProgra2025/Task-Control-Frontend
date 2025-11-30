import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat/chat_models.dart';
import 'storage_service.dart';

/// Servicio para operaciones HTTP del chat
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
  Future<List<ChatUserSearchResult>> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/users/search?q=${Uri.encodeComponent(query)}');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return (json['data'] as List)
              .map((u) => ChatUserSearchResult.fromJson(u))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[ChatService] Error searching users: $e');
      return [];
    }
  }

  // ==================== CONVERSATIONS ====================

  /// Obtener todas las conversaciones del usuario
  Future<List<Conversation>> getConversations() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return (json['data'] as List)
              .map((c) => Conversation.fromJson(c))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[ChatService] Error getting conversations: $e');
      return [];
    }
  }

  /// Obtener una conversación específica
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/$conversationId');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return Conversation.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      print('[ChatService] Error getting conversation: $e');
      return null;
    }
  }

  /// Crear o obtener conversación directa (1:1)
  Future<Conversation?> getOrCreateDirectConversation(String otherUserId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/direct');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'otherUserId': otherUserId}),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          // La respuesta básica, necesitamos obtener la conversación completa
          final conversationId = json['data']['id']?.toString();
          if (conversationId != null) {
            return await getConversation(conversationId);
          }
        }
      }
      return null;
    } catch (e) {
      print('[ChatService] Error creating direct conversation: $e');
      return null;
    }
  }

  /// Crear conversación grupal
  Future<Conversation?> createGroupConversation(
    String groupName, 
    List<String> memberIds, 
    {String? imageUrl}
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/group');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'groupName': groupName,
          'memberIds': memberIds,
          if (imageUrl != null) 'imageUrl': imageUrl,
        }),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final conversationId = json['data']['id']?.toString();
          if (conversationId != null) {
            return await getConversation(conversationId);
          }
        }
      }
      return null;
    } catch (e) {
      print('[ChatService] Error creating group conversation: $e');
      return null;
    }
  }

  // ==================== MESSAGES ====================

  /// Obtener mensajes de una conversación
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int skip = 0, 
    int take = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/messages?skip=$skip&take=$take'
      );
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return (json['data'] as List)
              .map((m) => ChatMessage.fromJson(m))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('[ChatService] Error getting messages: $e');
      return [];
    }
  }

  /// Enviar mensaje de texto
  Future<ChatMessage?> sendMessage(
    String conversationId, 
    String content, 
    {String? replyToMessageId}
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/messages');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'content': content,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        }),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return ChatMessage.fromJson(json['data']);
        }
      }
      return null;
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      return null;
    }
  }

  // ==================== READ/DELIVERY STATUS ====================

  /// Marcar mensaje como entregado
  Future<bool> markMessageDelivered(String messageId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/$messageId/delivered');
      
      final response = await http.put(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error marking message delivered: $e');
      return false;
    }
  }

  /// Marcar mensaje como leído
  Future<bool> markMessageRead(String messageId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/$messageId/read');
      
      final response = await http.put(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('[ChatService] Error marking message read: $e');
      return false;
    }
  }

  /// Marcar todos los mensajes de una conversación como leídos
  Future<int> markAllMessagesRead(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/mark-all-read');
      
      final response = await http.put(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['messagesMarked'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('[ChatService] Error marking all messages read: $e');
      return 0;
    }
  }

  /// Obtener conteo de mensajes no leídos
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations/$conversationId/unread-count');
      
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('[ChatService] Error getting unread count: $e');
      return 0;
    }
  }
}
