enum QueryIntent {
  orderStatus,
  orderDetails,
  orderTracking,
  orderModification,
  orderCancellation,
  listingSearch,
  listingDetails,
  listingPricing,
  listingAvailability,
  paymentStatus,
  paymentIssues,
  earnings,
  profile,
  support,
  general,
  unknown,
}

enum ResponseType {
  text,
  quickReplies,
  action,
  escalation,
}

class ChatbotResponse {
  final String responseId;
  final String query;
  final QueryIntent intent;
  final double confidence;
  final String message;
  final ResponseType type;
  final List<String>? quickReplies;
  final Map<String, dynamic>? action;
  final bool requiresEscalation;
  final DateTime timestamp;
  final Map<String, dynamic>? extractedData;

  const ChatbotResponse({
    required this.responseId,
    required this.query,
    required this.intent,
    required this.confidence,
    required this.message,
    this.type = ResponseType.text,
    this.quickReplies,
    this.action,
    this.requiresEscalation = false,
    required this.timestamp,
    this.extractedData,
  });

  bool get isConfident => confidence >= 0.8;
  bool get needsEscalation => requiresEscalation || !isConfident;

  ChatbotResponse copyWith({
    String? responseId,
    String? query,
    QueryIntent? intent,
    double? confidence,
    String? message,
    ResponseType? type,
    List<String>? quickReplies,
    Map<String, dynamic>? action,
    bool? requiresEscalation,
    DateTime? timestamp,
    Map<String, dynamic>? extractedData,
  }) {
    return ChatbotResponse(
      responseId: responseId ?? this.responseId,
      query: query ?? this.query,
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      message: message ?? this.message,
      type: type ?? this.type,
      quickReplies: quickReplies ?? this.quickReplies,
      action: action ?? this.action,
      requiresEscalation: requiresEscalation ?? this.requiresEscalation,
      timestamp: timestamp ?? this.timestamp,
      extractedData: extractedData ?? this.extractedData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response_id': responseId,
      'query': query,
      'intent': intent.name,
      'confidence': confidence,
      'message': message,
      'type': type.name,
      'quick_replies': quickReplies,
      'action': action,
      'requires_escalation': requiresEscalation,
      'timestamp': timestamp.toIso8601String(),
      'extracted_data': extractedData,
    };
  }

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      responseId: json['response_id'],
      query: json['query'],
      intent: QueryIntent.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => QueryIntent.unknown,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'],
      type: ResponseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ResponseType.text,
      ),
      quickReplies: json['quick_replies'] != null
          ? List<String>.from(json['quick_replies'])
          : null,
      action: json['action'],
      requiresEscalation: json['requires_escalation'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      extractedData: json['extracted_data'],
    );
  }
}