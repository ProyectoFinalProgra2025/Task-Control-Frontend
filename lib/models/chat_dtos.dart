class CreateOneToOneChatDto {
  final int userId;

  CreateOneToOneChatDto({required this.userId});

  Map<String, dynamic> toJson() {
    return {'userId': userId};
  }
}

class CreateGroupChatDto {
  final String name;
  final List<int> memberIds;

  CreateGroupChatDto({
    required this.name,
    required this.memberIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'memberIds': memberIds,
    };
  }
}

class SendMessageDto {
  final String text;

  SendMessageDto({required this.text});

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}

class AddMemberDto {
  final int userId;

  AddMemberDto({required this.userId});

  Map<String, dynamic> toJson() {
    return {'userId': userId};
  }
}
