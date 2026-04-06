enum MessageType {
  user,
  bot,
  system,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isTyping;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.type,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.metadata,
    this.isTyping = false,
  });

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'is_typing': isTyping,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.user,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
      isTyping: json['is_typing'] ?? false,
    );
  }
}