import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_model.dart';
import '../models/chat_dtos.dart';
import 'storage_service.dart';

class ChatService {
  final StorageService _storage = StorageService();

  Future<String?> _getAuthToken() async {
    return await _storage.getAccessToken();
  }

  // Get all chats for current user
  Future<List<ChatModel>> getChats() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatsEndpoint}');
    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ChatModel.fromJson(json as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception('Failed to load chats: ${response.statusCode}');
    }
  }

  // Create 1:1 chat
  Future<ChatModel> createOneToOneChat(String userId) async{
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatsEndpoint}/one-to-one');
    final dto = CreateOneToOneChatDto(userId: userId);

    final response = await http.post(
      url,
      headers: ApiConfig.headersWithAuth(token),
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final chatId = jsonResponse['id'] as String;
      
      // Fetch the created chat details
      return await getChatById(chatId);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Failed to create chat: ${response.statusCode}');
    }
  }

  // Create group chat
  Future<ChatModel> createGroupChat(String name, List<String> memberIds) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatsEndpoint}/group');
    final dto = CreateGroupChatDto(name: name, memberIds: memberIds);

    final response = await http.post(
      url,
      headers: ApiConfig.headersWithAuth(token),
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final chatId = jsonResponse['id'] as String;
      
      // Fetch the created chat details
      return await getChatById(chatId);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 400) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Invalid data');
    } else {
      throw Exception('Failed to create group chat: ${response.statusCode}');
    }
  }

  // Get chat by ID (helper method)
  Future<ChatModel> getChatById(String chatId) async {
    final chats = await getChats();
    return chats.firstWhere(
      (chat) => chat.id == chatId,
      orElse: () => throw Exception('Chat not found'),
    );
  }

  // Get messages from a chat
  Future<List<MessageModel>> getMessages(String chatId, {int skip = 0, int take = 50}) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.chatMessagesEndpoint(chatId)}?skip=$skip&take=$take',
    );

    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 403) {
      throw Exception('You are not a member of this chat');
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  // Send message
  Future<MessageModel> sendMessage(String chatId, String text) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.chatMessagesEndpoint(chatId)}',
    );
    final dto = SendMessageDto(text: text);

    final response = await http.post(
      url,
      headers: ApiConfig.headersWithAuth(token),
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return MessageModel.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 403) {
      throw Exception('You are not a member of this chat');
    } else if (response.statusCode == 400) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Invalid message');
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  // Add member to group chat
  Future<void> addMember(String chatId, String userId) async{
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.chatMembersEndpoint(chatId)}',
    );
    final dto = AddMemberDto(userId: userId);

    final response = await http.post(
      url,
      headers: ApiConfig.headersWithAuth(token),
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 403) {
      throw Exception('You don\'t have permission to add members');
    } else if (response.statusCode == 400) {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['message'] ?? 'Failed to add member');
    } else if (response.statusCode == 409) {
      throw Exception('User is already a member');
    } else {
      throw Exception('Failed to add member: ${response.statusCode}');
    }
  }

  // Search users
  Future<List<UserSearchResult>> searchUsers(String query, {int take = 20}) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.usersSearchEndpoint}?q=$query&take=$take',
    );

    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UserSearchResult.fromJson(json as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception('Failed to search users: ${response.statusCode}');
    }
  }

  // Marcar mensaje individual como leído
  Future<void> markMessageAsRead(String messageId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatMarkMessageReadEndpoint(messageId)}');

    final response = await http.put(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      return; // Success
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 404) {
      throw Exception('Message not found');
    } else {
      throw Exception('Failed to mark message as read: ${response.statusCode}');
    }
  }

  // Marcar todos los mensajes de un chat como leídos
  Future<void> markAllChatAsRead(String chatId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatMarkAllReadEndpoint(chatId)}');

    final response = await http.put(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      return; // Success
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else if (response.statusCode == 403) {
      throw Exception('You are not a member of this chat');
    } else {
      throw Exception('Failed to mark all messages as read: ${response.statusCode}');
    }
  }

  // Obtener contador total de mensajes no leídos
  Future<int> getUnreadCount() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatUnreadCountEndpoint}');

    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']['unreadCount'] as int;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception('Failed to get unread count: ${response.statusCode}');
    }
  }

  // Obtener mensajes no leídos por chat (para badges)
  Future<Map<String, int>> getUnreadByChat() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatUnreadByChatEndpoint}');

    final response = await http.get(
      url,
      headers: ApiConfig.headersWithAuth(token),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final Map<String, dynamic> data = jsonResponse['data'];
      return data.map((key, value) => MapEntry(key, value as int));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - please login again');
    } else {
      throw Exception('Failed to get unread by chat: ${response.statusCode}');
    }
  }
}
