enum ConversationStatus {
  active,
  closed,
  escalated,
}

class Conversation {
  final String id;
  final String userId;
  final String title;
  final ConversationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessage;
  final Map<String, dynamic>? metadata;

  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    this.status = ConversationStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessage,
    this.metadata,
  });

  Conversation copyWith({
    String? id,
    String? userId,
    String? title,
    ConversationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessage,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'message_count': messageCount,
      'last_message': lastMessage,
      'metadata': metadata,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConversationStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messageCount: json['message_count'] ?? 0,
      lastMessage: json['last_message'],
      metadata: json['metadata'],
    );
  }
}