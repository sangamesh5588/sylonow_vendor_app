import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../orders/models/order.dart';
import '../models/chat_message.dart';
import '../models/chatbot_response.dart';
import '../services/chatbot_service.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final ChatbotResponse? currentResponse;
  final String? conversationId;
  final bool isLoading;
  final bool isError;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.currentResponse,
    this.conversationId,
    this.isLoading = false,
    this.isError = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    ChatbotResponse? currentResponse,
    String? conversationId,
    bool? isLoading,
    bool? isError,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      currentResponse: currentResponse ?? this.currentResponse,
      conversationId: conversationId ?? this.conversationId,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final ChatbotService _chatbotService;
  final String _userId;
  final Ref _ref;
  Timer? _typingTimer;

  ChatController(this._chatbotService, this._userId, this._ref)
      : super(const ChatState()) {
    _initializeChat();
  }

  ChatController.error(this._chatbotService, this._ref)
      : _userId = '',
        super(const ChatState(isError: true)) {
    // Set error state
    state = const ChatState(
      messages: [],
      isTyping: false,
      isLoading: false,
      isError: true,
    );
  }

  void _initializeChat() {
    // Load existing conversation or create new one
    loadConversation();
  }

  Future<void> loadConversation() async {
    try {
      state = state.copyWith(isLoading: true);

      // For now, we'll start with an empty conversation
      // In a full implementation, you'd load from local storage or API
      state = state.copyWith(
        isLoading: false,
        messages: [],
      );

      // Send initial welcome message
      _addBotMessage(
        'Hello! I\'m your AI assistant for Sylonow. How can I help you today?',
        quickReplies: [
          'Check Order Status',
          'View Services',
          'Payment History',
          'My Earnings'
        ],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _addBotMessage(
          'Sorry, I\'m having trouble loading our conversation. Please try again.');
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversationId ?? 'default',
      content: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    try {
      // Call chatbot API
      final response = await _chatbotService.sendMessage(
        userId: _userId,
        message: message,
        conversationId: state.conversationId,
      );

      // Update current response
      state = state.copyWith(currentResponse: response);

      // Add bot response after a small delay for natural feel
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 800), () {
        _addBotMessage(
          response.message,
          quickReplies: response.quickReplies,
          responseData: response,
        );
      });
    } catch (e) {
      // Handle error
      _addBotMessage(
        'I apologize, but I\'m experiencing some technical difficulties. Please try again in a moment, or contact our support team for immediate assistance.',
        requiresEscalation: true,
      );
    }
  }

  void _addBotMessage(
    String content, {
    List<String>? quickReplies,
    bool requiresEscalation = false,
    ChatbotResponse? responseData,
  }) {
    final botMessage = ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversationId ?? 'default',
      content: content,
      type: MessageType.bot,
      timestamp: DateTime.now(),
      metadata: {
        'quick_replies': quickReplies,
        'requires_escalation': requiresEscalation,
        'response_data': responseData?.toJson(),
      },
    );

    state = state.copyWith(
      messages: [...state.messages, botMessage],
      isTyping: false,
      currentResponse: responseData,
    );
  }

  // Handle quick actions that fetch real data
  Future<void> handleQuickAction(String action) async {
    // Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: state.conversationId ?? 'default',
      content: action,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    try {
      switch (action) {
        case 'Show me my recent orders':
          await _handleRecentOrders();
          break;
        case 'Show me my upcoming orders':
          await _handleUpcomingOrders();
          break;
        case 'Show me my earnings':
          await _handleEarnings();
          break;
        case 'Show me my profit summary':
          await _handleProfitSummary();
          break;
        case 'Show me my active listings':
          await _handleActiveListings();
          break;
        case 'I need help with support':
          _handleSupport();
          break;
        default:
          // Fallback to backend for other queries
          await sendMessage(action);
      }
    } catch (e) {
      _addBotMessage(
        'Sorry, I encountered an error while fetching your data. Please try again.',
        requiresEscalation: true,
      );
    }
  }

  Future<void> _handleRecentOrders() async {
    try {
      // Fetch recent orders using the order provider
      final ordersAsync = await _ref.read(ordersProvider('All').future);
      final recentOrders = ordersAsync.take(5).toList(); // Show last 5 orders

      if (recentOrders.isEmpty) {
        _addBotMessage(
          'You don\'t have any recent orders. When you receive new orders, they\'ll appear here!',
          quickReplies: ['View all orders', 'Check upcoming events'],
        );
        return;
      }

      // Show first order with navigation options
      await _showOrderWithNavigation(recentOrders, 0, 'recent');
    } catch (e) {
      throw Exception('Failed to fetch recent orders: $e');
    }
  }

  Future<void> _showOrderWithNavigation(
      List<Order> orders, int currentIndex, String type) async {
    final order = orders[currentIndex];

    // Calculate order values using the same logic as orderValuesProvider
    final orderValues = await _calculateOrderValues(order);

    final orderDate = order.bookingDate.toString().split(' ')[0];
    final earnings = orderValues['yourEarnings'] ?? 0.0;
    final amountToCollect = orderValues['amountToCollect'] ?? 0.0;

    String message = '**${order.serviceTitle}**\n\n';
    message += 'Date: $orderDate\n';
    message +=
        'Total Value: ₹${orderValues['totalOrderValue']?.toStringAsFixed(0)}\n';
    message += 'Your Earnings: ₹${earnings.toStringAsFixed(0)}\n';
    message += 'Amount to Collect: ₹${amountToCollect.toStringAsFixed(0)}\n';
    message += 'Location: ${order.venueAddress ?? 'Address not specified'}\n';
    message += 'Status: ${order.status.toUpperCase()}\n\n';

    // Add navigation buttons
    List<String> quickReplies = [];

    if (currentIndex > 0) {
      quickReplies.add('Previous');
    }

    quickReplies.add('View Details');

    if (currentIndex < orders.length - 1) {
      quickReplies.add('Next');
    }

    if (type == 'recent') {
      quickReplies.add('Upcoming Orders');
    } else {
      quickReplies.add('Recent Orders');
    }

    _addBotMessage(
      message,
      quickReplies: quickReplies,
    );
  }

  Future<Map<String, double>> _calculateOrderValues(Order order) async {
    try {
      // Use the actual order.totalAmount as the base value (what customer paid)
      double totalOrderValue = order.totalAmount;

      // Apply the specific deduction formula: totalOrderValue * 0.05 + (totalOrderValue * 0.05) * 0.18
      double deduction =
          totalOrderValue * 0.05 + (totalOrderValue * 0.05) * 0.18;
      double revenue = totalOrderValue - deduction;

      // Your Earnings = Revenue × 60%
      double yourEarnings = revenue * 0.60;

      // Amount to collect from user = Revenue × 40%
      double amountToCollect = revenue * 0.40;

      return {
        'totalOrderValue': totalOrderValue,
        'revenue': revenue,
        'yourEarnings': yourEarnings,
        'amountToCollect': amountToCollect,
        'deduction': deduction,
      };
    } catch (e) {
      // Fallback to simple calculation
      double totalOrderValue = order.totalAmount;
      double deduction =
          totalOrderValue * 0.05 + (totalOrderValue * 0.05) * 0.18;
      double revenue = totalOrderValue - deduction;
      double yourEarnings = revenue * 0.60;
      double amountToCollect = revenue * 0.40;

      return {
        'totalOrderValue': totalOrderValue,
        'revenue': revenue,
        'yourEarnings': yourEarnings,
        'amountToCollect': amountToCollect,
        'deduction': deduction,
      };
    }
  }

  Future<void> _handleUpcomingOrders() async {
    try {
      // Fetch upcoming orders (future dates)
      final ordersAsync = await _ref.read(ordersProvider('All').future);
      final now = DateTime.now();
      final upcomingOrders = ordersAsync
          .where((order) => order.bookingDate.isAfter(now))
          .take(5)
          .toList();

      if (upcomingOrders.isEmpty) {
        _addBotMessage(
          'You don\'t have any upcoming orders scheduled. New orders will appear here as they come in!',
          quickReplies: ['View all orders', 'Check recent orders'],
        );
        return;
      }

      // Show first upcoming order with navigation options
      await _showOrderWithNavigation(upcomingOrders, 0, 'upcoming');
    } catch (e) {
      throw Exception('Failed to fetch upcoming orders: $e');
    }
  }

  Future<void> _handleEarnings() async {
    try {
      // Calculate real earnings from all orders
      final ordersAsync = await _ref.read(ordersProvider('All').future);
      final now = DateTime.now();

      double totalEarnings = 0.0;
      double thisMonthEarnings = 0.0;
      double lastMonthEarnings = 0.0;
      int totalOrders = 0;

      for (final order in ordersAsync) {
        final orderValues = await _calculateOrderValues(order);
        final earnings = orderValues['yourEarnings'] ?? 0.0;

        totalEarnings += earnings;
        totalOrders++;

        // Calculate monthly earnings
        if (order.bookingDate.year == now.year &&
            order.bookingDate.month == now.month) {
          thisMonthEarnings += earnings;
        } else if (order.bookingDate.year == now.year &&
            order.bookingDate.month == now.month - 1) {
          lastMonthEarnings += earnings;
        }
      }

      final avgPerOrder = totalOrders > 0 ? totalEarnings / totalOrders : 0.0;

      _addBotMessage(
        'Earnings Summary:\n\n'
        'Total Earnings: ₹${totalEarnings.toStringAsFixed(0)}\n'
        'This Month: ₹${thisMonthEarnings.toStringAsFixed(0)}\n'
        'Last Month: ₹${lastMonthEarnings.toStringAsFixed(0)}\n'
        'Average per Order: ₹${avgPerOrder.toStringAsFixed(0)}\n'
        'Total Orders: $totalOrders\n\n'
        'Keep up the great work! Your services are in high demand.',
        quickReplies: [
          'View detailed breakdown',
          'Check payment history',
          'Tax information'
        ],
      );
    } catch (e) {
      throw Exception('Failed to fetch earnings data: $e');
    }
  }

  Future<void> _handleProfitSummary() async {
    try {
      // Calculate real profit data from all orders
      final ordersAsync = await _ref.read(ordersProvider('All').future);

      double totalRevenue = 0.0;
      double totalEarnings = 0.0;
      double totalCosts = 0.0;
      Map<String, double> monthlyProfits = {};
      Map<String, double> serviceProfits = {};

      for (final order in ordersAsync) {
        final orderValues = await _calculateOrderValues(order);
        final earnings = orderValues['yourEarnings'] ?? 0.0;
        final revenue = orderValues['revenue'] ?? 0.0;

        totalRevenue += revenue;
        totalEarnings += earnings;
        totalCosts += (revenue - earnings); // Platform fees + GST

        // Monthly tracking
        final monthKey =
            '${order.bookingDate.year}-${order.bookingDate.month.toString().padLeft(2, '0')}';
        monthlyProfits[monthKey] = (monthlyProfits[monthKey] ?? 0.0) + earnings;

        // Service tracking
        final serviceKey = order.serviceTitle;
        serviceProfits[serviceKey] =
            (serviceProfits[serviceKey] ?? 0.0) + earnings;
      }

      final netProfit = totalEarnings;
      final profitMargin =
          totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

      // Find best performing service and month
      final bestService = serviceProfits.isNotEmpty
          ? serviceProfits.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null;

      final bestMonth = monthlyProfits.isNotEmpty
          ? monthlyProfits.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null;

      _addBotMessage(
        'Profit Summary:\n\n'
        'Total Revenue: ₹${totalRevenue.toStringAsFixed(0)}\n'
        'Total Costs: ₹${totalCosts.toStringAsFixed(0)}\n'
        'Net Profit: ₹${netProfit.toStringAsFixed(0)}\n'
        'Profit Margin: ${profitMargin.toStringAsFixed(1)}%\n\n'
        '${bestService != null ? 'Top Performing Service: ${bestService.key} (₹${bestService.value.toStringAsFixed(0)} profit)\n' : ''}'
        '${bestMonth != null ? 'Best Month: ${bestMonth.key} (₹${bestMonth.value.toStringAsFixed(0)} profit)\n\n' : ''}'
        'Your business is performing excellently!',
        quickReplies: [
          'View detailed analytics',
          'Optimize pricing',
          'Marketing tips'
        ],
      );
    } catch (e) {
      throw Exception('Failed to fetch profit data: $e');
    }
  }

  Future<void> _handleActiveListings() async {
    try {
      // For now, show a placeholder. In a real implementation,
      // you'd fetch actual service listings
      _addBotMessage(
        'Your Active Listings:\n\n'
        'Wedding Photography\n'
        '   Price: ₹15,000 • Rating: 4.8/5 • Bookings: 23\n\n'
        'Birthday Decorations\n'
        '   Price: ₹8,500 • Rating: 4.6/5 • Bookings: 15\n\n'
        'Event DJ Services\n'
        '   Price: ₹12,000 • Rating: 4.9/5 • Bookings: 8\n\n'
        'All your listings are performing well! Consider adding more services to increase your revenue.',
        quickReplies: ['Add new service', 'Update pricing', 'View analytics'],
      );
    } catch (e) {
      throw Exception('Failed to fetch listings data: $e');
    }
  }

  void _handleSupport() {
    _addBotMessage(
      'How can I help you with support?\n\n'
      'I can assist you with:\n'
      '- Technical Issues - App problems, bugs\n'
      '- Payment Problems - Transactions, refunds\n'
      '- Order Issues - Cancellations, modifications\n'
      '- Account Help - Profile, verification\n'
      '- General Questions - How to use features\n\n'
      'Please describe your issue, or choose from the options below.',
      quickReplies: [
        'Technical issue',
        'Payment problem',
        'Order issue',
        'Call support'
      ],
    );
  }

  void startNewConversation() {
    // Clear current conversation and start fresh
    state = const ChatState();

    // Send welcome message
    _addBotMessage(
      'Hello! I\'m your AI assistant for Sylonow. How can I help you today?',
      quickReplies: [
        'Check Order Status',
        'View Services',
        'Payment History',
        'My Earnings'
      ],
    );
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
}

// Provider
final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  // You'll need to configure the base URL for your chatbot backend
  // For development, you might use localhost, for production use your deployed URL
  const baseUrl = String.fromEnvironment(
    'CHATBOT_BASE_URL',
    defaultValue:
        'http://192.168.29.246:8000', // Updated to computer's IP for mobile access
  );

  return ChatbotService(baseUrl: baseUrl);
});

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  final chatbotService = ref.watch(chatbotServiceProvider);

  // Get user from auth state provider to ensure proper reactivity
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull?.session?.user;

  if (user == null) {
    // Return a controller that shows an error state instead of throwing
    return ChatController.error(chatbotService, ref);
  }

  return ChatController(chatbotService, user.id, ref);
});
