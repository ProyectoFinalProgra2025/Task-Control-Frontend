import 'package:intl/intl.dart';

enum ChatType {
  oneToOne,
  group,
}

enum ChatRole {
  member,
  owner,
}

class ChatModel {
  final String id;
  final ChatType type;
  final String? name;
  final List<ChatMemberModel> members;
  final MessageModel? lastMessage;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.type,
    this.name,
    required this.members,
    this.lastMessage,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse ID - can be Guid string
      final id = json['id']?.toString() ?? '';
      
      // Parse type
      final typeValue = json['type'];
      ChatType chatType;
      if (typeValue == 0 || typeValue == 'OneToOne') {
        chatType = ChatType.oneToOne;
      } else {
        chatType = ChatType.group;
      }
      
      // Parse members array
      List<ChatMemberModel> membersList = [];
      if (json['members'] != null && json['members'] is List) {
        try {
          membersList = (json['members'] as List<dynamic>)
              .map((m) => ChatMemberModel.fromJson(m as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing members: $e');
        }
      }
      
      // Parse last message
      MessageModel? lastMsg;
      if (json['lastMessage'] != null && json['lastMessage'] is Map) {
        try {
          lastMsg = MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing lastMessage: $e');
        }
      }
      
      // Parse created date
      DateTime created;
      try {
        created = json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now();
      } catch (e) {
        created = DateTime.now();
      }
      
      return ChatModel(
        id: id,
        type: chatType,
        name: json['name']?.toString(),
        members: membersList,
        lastMessage: lastMsg,
        createdAt: created,
      );
    } catch (e) {
      print('Error in ChatModel.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == ChatType.oneToOne ? 0 : 1,
      'name': name,
      'members': members.map((m) => m.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayName {
    if (type == ChatType.group) {
      return name ?? 'Group Chat';
    }
    // For 1:1, show other person's name
    return members.isNotEmpty ? members.first.userName : 'Chat';
  }
}

class ChatMemberModel {
  final int userId;
  final String userName;
  final String email;
  final ChatRole role;

  ChatMemberModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.role,
  });

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    try {
      return ChatMemberModel(
        userId: json['userId'] as int? ?? 0,
        userName: json['nombreCompleto']?.toString() ?? 
                  json['userName']?.toString() ?? 
                  json['email']?.toString() ?? 
                  'Unknown',
        email: json['email']?.toString() ?? '',
        role: (json['role'] == 1 || json['role'] == 'Owner') 
            ? ChatRole.owner 
            : ChatRole.member,
      );
    } catch (e) {
      print('Error in ChatMemberModel.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'role': role == ChatRole.owner ? 1 : 0,
    };
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final int senderId;
  final String body;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    try {
      return MessageModel(
        id: json['id']?.toString() ?? '',
        chatId: json['chatId']?.toString() ?? '',
        senderId: json['senderId'] as int? ?? 0,
        body: json['body']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error in MessageModel.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(createdAt);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  String get detailTime {
    return DateFormat('h:mm a').format(createdAt);
  }
}

class UserSearchResult {
  final int id;
  final String nombreCompleto;
  final String email;

  UserSearchResult({
    required this.id,
    required this.nombreCompleto,
    required this.email,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as int,
      nombreCompleto: json['nombreCompleto'] as String,
      email: json['email'] as String,
    );
  }
}
