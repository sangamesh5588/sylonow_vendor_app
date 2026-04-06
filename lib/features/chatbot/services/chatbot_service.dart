import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/chatbot_response.dart';
import '../models/conversation.dart';

class ChatbotService {
  final String baseUrl;
  final http.Client _client;

  ChatbotService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Send message to chatbot and get response
  Future<ChatbotResponse> sendMessage({
    required String userId,
    required String message,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4',
        },
        body: jsonEncode({
          'user_id': userId,
          'message': message,
          'conversation_id': conversationId,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatbotResponse.fromJson(data);
      } else {
        throw Exception('Failed to get chatbot response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Chatbot service error: $e');
      // Return fallback response for errors
      return ChatbotResponse(
        responseId: 'error_${DateTime.now().millisecondsSinceEpoch}',
        query: message,
        intent: QueryIntent.unknown,
        confidence: 0.0,
        message: 'I apologize, but I\'m experiencing some technical difficulties. Please try again in a moment, or contact our support team for immediate assistance.',
        requiresEscalation: true,
        timestamp: DateTime.now(),
      );
    }
  }

  // Get conversation history
  Future<List<ChatMessage>> getConversationHistory(String conversationId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching conversation history: $e');
      return [];
    }
  }

  // Get user's conversations
  Future<List<Conversation>> getUserConversations(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/conversations'),
        headers: {
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching user conversations: $e');
      return [];
    }
  }

  // Create new conversation
  Future<Conversation> createConversation({
    required String userId,
    required String title,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4',
        },
        body: jsonEncode({
          'user_id': userId,
          'title': title,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Conversation.fromJson(data);
      } else {
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      // Return a local conversation for offline functionality
      return Conversation(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Update conversation status
  Future<bool> updateConversationStatus({
    required String conversationId,
    required ConversationStatus status,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/conversations/$conversationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4',
        },
        body: jsonEncode({
          'status': status.name,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating conversation status: $e');
      return false;
    }
  }

  // Get quick reply suggestions
  Future<List<String>> getQuickReplies(String intent) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/quick-replies/$intent'),
        headers: {
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => item.toString()).toList();
      } else {
        return _getDefaultQuickReplies(intent);
      }
    } catch (e) {
      debugPrint('Error fetching quick replies: $e');
      return _getDefaultQuickReplies(intent);
    }
  }

  // Default quick replies for offline/fallback scenarios
  List<String> _getDefaultQuickReplies(String intent) {
    switch (intent) {
      case 'orderStatus':
        return ['Check another order', 'View all orders', 'Need help with order'];
      case 'listingDetails':
        return ['View pricing', 'Check availability', 'Contact seller'];
      case 'paymentStatus':
        return ['Payment history', 'Refund status', 'Payment methods'];
      case 'support':
        return ['Call support', 'Email us', 'Live chat'];
      default:
        return ['Help', 'My orders', 'My listings', 'Support'];
    }
  }

  void dispose() {
    _client.close();
  }
}