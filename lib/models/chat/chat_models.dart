/// Modelos para el sistema de chat
/// Sincronizados con los DTOs del backend (ChatController.cs)

/// Tipo de conversación
enum ConversationType { direct, group }

/// Estado del mensaje
enum MessageStatus { sent, delivered, read }

/// Tipo de contenido del mensaje
enum MessageContentType { text, image, document, audio, video }

/// Modelo de conversación
/// Sincronizado con la respuesta de GET /api/chat/conversations
class Conversation {
  final String id;
  final ConversationType type;
  final String? name;
  final String? imageUrl;
  final String createdById;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final bool isActive;
  final List<ConversationMember> members;
  final ChatMessage? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.imageUrl,
    required this.createdById,
    required this.createdAt,
    required this.lastActivityAt,
    this.isActive = true,
    this.members = const [],
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List?)
        ?.map((m) => ConversationMember.fromJson(m))
        .toList() ?? [];
    
    // Debug: imprimir los miembros para diagnosticar
    print('[Conversation.fromJson] id=${json['id']}, members=${members.map((m) => 'userId=${m.userId}, userName=${m.userName}').toList()}');
    
    return Conversation(
      id: json['id']?.toString() ?? '',
      type: json['type'] == 'Group' ? ConversationType.group : ConversationType.direct,
      name: json['name'],
      imageUrl: json['imageUrl'],
      createdById: json['createdById']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastActivityAt: DateTime.tryParse(json['lastActivityAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      members: members,
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  /// Obtener el nombre a mostrar (para chats directos, el nombre del otro usuario)
  String getDisplayName(String currentUserId) {
    print('[Conversation.getDisplayName] currentUserId=$currentUserId, type=$type, membersCount=${members.length}');
    
    if (type == ConversationType.group) {
      return name ?? 'Grupo sin nombre';
    }
    
    // Debug: imprimir todos los miembros
    for (var m in members) {
      print('[Conversation.getDisplayName] member: userId=${m.userId}, userName=${m.userName}, match=${m.userId.toLowerCase() != currentUserId.toLowerCase()}');
    }
    
    // Para chat directo, mostrar el nombre del otro miembro
    // Comparación case-insensitive para GUIDs
    final otherMember = members.firstWhere(
      (m) => m.userId.toLowerCase() != currentUserId.toLowerCase(),
      orElse: () => members.isNotEmpty ? members.first : ConversationMember.empty(),
    );
    print('[Conversation.getDisplayName] otherMember found: userId=${otherMember.userId}, userName=${otherMember.userName}');
    return otherMember.userName;
  }

  /// Obtener el ID del otro usuario en un chat directo
  String? getOtherUserId(String currentUserId) {
    if (type != ConversationType.direct) return null;
    // Comparación case-insensitive para GUIDs
    final otherMember = members.firstWhere(
      (m) => m.userId.toLowerCase() != currentUserId.toLowerCase(),
      orElse: () => ConversationMember.empty(),
    );
    return otherMember.userId.isNotEmpty ? otherMember.userId : null;
  }
}

/// Miembro de una conversación
/// Sincronizado con la respuesta del backend
class ConversationMember {
  final String userId;
  final String userName;
  final String role; // "Member" o "Admin"
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime? lastReadAt;
  final bool isActive;

  ConversationMember({
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
    this.isMuted = false,
    this.lastReadAt,
    this.isActive = true,
  });

  factory ConversationMember.fromJson(Map<String, dynamic> json) {
    return ConversationMember(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      role: json['role'] ?? 'Member',
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      isMuted: json['isMuted'] ?? false,
      lastReadAt: json['lastReadAt'] != null 
          ? DateTime.tryParse(json['lastReadAt']) 
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  factory ConversationMember.empty() {
    return ConversationMember(
      userId: '',
      userName: 'Usuario',
      role: 'Member',
      joinedAt: DateTime.now(),
    );
  }
}

/// Mensaje de chat
/// Sincronizado con la respuesta de GET /api/chat/conversations/{id}/messages
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final MessageContentType contentType;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final String? fileMimeType;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final MessageStatus status;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final String? replyToMessageId;
  final ChatMessage? replyToMessage;
  final List<MessageReadReceipt> readReceipts;
  final List<MessageDeliveryReceipt> deliveryReceipts;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.contentType,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    this.fileMimeType,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    required this.status,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.replyToMessageId,
    this.replyToMessage,
    this.readReceipts = const [],
    this.deliveryReceipts = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? '',
      contentType: _parseContentType(json['contentType']),
      content: json['content'] ?? '',
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSizeBytes: json['fileSizeBytes'],
      fileMimeType: json['fileMimeType'],
      sentAt: DateTime.tryParse(json['sentAt'] ?? '') ?? DateTime.now(),
      deliveredAt: json['deliveredAt'] != null 
          ? DateTime.tryParse(json['deliveredAt']) 
          : null,
      readAt: json['readAt'] != null 
          ? DateTime.tryParse(json['readAt']) 
          : null,
      status: _parseStatus(json['status']),
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null 
          ? DateTime.tryParse(json['editedAt']) 
          : null,
      isDeleted: json['isDeleted'] ?? false,
      replyToMessageId: json['replyToMessageId']?.toString(),
      replyToMessage: json['replyToMessage'] != null 
          ? ChatMessage.fromJson(json['replyToMessage']) 
          : null,
      readReceipts: (json['readReceipts'] as List?)
          ?.map((r) => MessageReadReceipt.fromJson(r))
          .toList() ?? [],
      deliveryReceipts: (json['deliveryReceipts'] as List?)
          ?.map((d) => MessageDeliveryReceipt.fromJson(d))
          .toList() ?? [],
    );
  }

  static MessageContentType _parseContentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'image': return MessageContentType.image;
      case 'document': return MessageContentType.document;
      case 'audio': return MessageContentType.audio;
      case 'video': return MessageContentType.video;
      default: return MessageContentType.text;
    }
  }

  static MessageStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      default: return MessageStatus.sent;
    }
  }

  /// ¿Es mensaje del usuario actual?
  bool isFromCurrentUser(String currentUserId) => senderId == currentUserId;

  /// Crear copia con estado actualizado
  ChatMessage copyWithStatus(MessageStatus newStatus) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      contentType: contentType,
      content: content,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      fileMimeType: fileMimeType,
      sentAt: sentAt,
      deliveredAt: newStatus == MessageStatus.delivered ? DateTime.now() : deliveredAt,
      readAt: newStatus == MessageStatus.read ? DateTime.now() : readAt,
      status: newStatus,
      isEdited: isEdited,
      editedAt: editedAt,
      isDeleted: isDeleted,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage,
      readReceipts: readReceipts,
      deliveryReceipts: deliveryReceipts,
    );
  }
}

/// Recibo de lectura
class MessageReadReceipt {
  final String userId;
  final String userName;
  final DateTime readAt;

  MessageReadReceipt({
    required this.userId,
    required this.userName,
    required this.readAt,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      readAt: DateTime.tryParse(json['readAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Recibo de entrega
class MessageDeliveryReceipt {
  final String userId;
  final String userName;
  final DateTime deliveredAt;

  MessageDeliveryReceipt({
    required this.userId,
    required this.userName,
    required this.deliveredAt,
  });

  factory MessageDeliveryReceipt.fromJson(Map<String, dynamic> json) {
    return MessageDeliveryReceipt(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      deliveredAt: DateTime.tryParse(json['deliveredAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Usuario para búsqueda de chat
/// Sincronizado con respuesta de GET /api/chat/users/search
class ChatUserSearchResult {
  final String id;
  final String nombreCompleto;
  final String email;
  final String rol;
  final String? empresaId;

  ChatUserSearchResult({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
    this.empresaId,
  });

  factory ChatUserSearchResult.fromJson(Map<String, dynamic> json) {
    return ChatUserSearchResult(
      id: json['id']?.toString() ?? '',
      // El backend envía 'nombreCompleto' no 'nombre'
      nombreCompleto: json['nombreCompleto'] ?? json['nombre'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      empresaId: json['empresaId']?.toString(),
    );
  }

  /// Nombre del rol legible
  String get rolDisplayName {
    switch (rol.toLowerCase()) {
      case 'admingeneral': return 'Super Admin';
      case 'adminempresa': return 'Admin';
      case 'managerdepartamento': return 'Manager';
      case 'usuario': return 'Worker';
      default: return rol;
    }
  }
  
  /// Getter para compatibilidad con código existente
  String get nombre => nombreCompleto;
}
