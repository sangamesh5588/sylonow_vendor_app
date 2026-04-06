import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/quick_replies.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial messages when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).loadConversation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatState.isError
                ? _buildErrorState()
                : chatState.messages.isEmpty
                    ? _buildWelcomeMessage()
                    : _buildMessagesList(chatState.messages),
          ),

          // Quick Action Buttons (Primary Interface)
          _buildQuickActionButtons(),

          // Quick Replies (if available from bot response)
          if (chatState.currentResponse?.quickReplies != null &&
              chatState.currentResponse!.quickReplies!.isNotEmpty)
            QuickRepliesWidget(
              replies: chatState.currentResponse!.quickReplies!,
              onReplySelected: (reply) {
                _handleQuickReply(reply, chatState.messages.last);
              },
            ),

          // Message Input (Secondary - for custom queries)
          ChatInput(
            controller: _messageController,
            onSendMessage: (message) {
              ref.read(chatControllerProvider.notifier).sendMessage(message);
              _messageController.clear();
            },
            isLoading: chatState.isTyping,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.textPrimaryColor,
      scrolledUnderElevation: 0,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'AI Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: const HeroIcon(HeroIcons.arrowLeft,
            color: AppTheme.textPrimaryColor),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const HeroIcon(HeroIcons.ellipsisVertical,
              color: AppTheme.textSecondaryColor),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hello!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'I\'m your AI assistant for Sylonow. I can help you with:\n\n'
            '• Order status and tracking\n'
            '• Service listings and pricing\n'
            '• Payment and earnings\n'
            '• Account and profile\n'
            '• General support\n\n'
            'How can I assist you today?',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickStartButton('Check Order Status', Icons.receipt_long),
              _buildQuickStartButton('View Services', Icons.room_service),
              _buildQuickStartButton('Payment History', Icons.payment),
              _buildQuickStartButton(
                  'My Earnings', Icons.account_balance_wallet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartButton(String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        ref.read(chatControllerProvider.notifier).sendMessage(text);
      },
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLastMessage = index == messages.length - 1;

        return Column(
          children: [
            ChatBubble(
              message: message,
              isLastMessage: isLastMessage,
            ),
            if (isLastMessage && message.type == MessageType.bot)
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.0,
            children: [
              _buildActionButton(
                icon: Icons.receipt_long,
                title: 'Recent Orders',
                query: 'Show me my recent orders',
                color: AppTheme.primaryColor,
              ),
              _buildActionButton(
                icon: Icons.event_available,
                title: 'Upcoming Orders',
                query: 'Show me my upcoming orders',
                color: AppTheme.successColor,
              ),
              _buildActionButton(
                icon: Icons.account_balance_wallet,
                title: 'My Earnings',
                query: 'Show me my earnings',
                color: AppTheme.warningColor,
              ),
              _buildActionButton(
                icon: Icons.bar_chart,
                title: 'Profit Summary',
                query: 'Show me my profit summary',
                color: AppTheme.accentBlue,
              ),
              _buildActionButton(
                icon: Icons.store,
                title: 'My Listings',
                query: 'Show me my active listings',
                color: AppTheme.accentTeal,
              ),
              _buildActionButton(
                icon: Icons.support_agent,
                title: 'Contact Support',
                query: 'I need help with support',
                color: AppTheme.accentPurple,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider with "or" text
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                  thickness: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppTheme.dividerColor.withOpacity(0.5),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String query,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () {
        ref.read(chatControllerProvider.notifier).handleQuickAction(query);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        shadowColor: Colors.transparent,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Authentication Required',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please log in to access the AI assistant. The chatbot requires authentication to provide personalized support.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.login),
            label: const Text('Go to Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionItem(
              icon: Icons.refresh,
              title: 'Start New Conversation',
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(chatControllerProvider.notifier)
                    .startNewConversation();
              },
            ),
            _buildOptionItem(
              icon: Icons.history,
              title: 'Conversation History',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to conversation history
              },
            ),
            _buildOptionItem(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              onTap: () {
                Navigator.pop(context);
                ref.read(chatControllerProvider.notifier).sendMessage('help');
              },
            ),
            _buildOptionItem(
              icon: Icons.contact_support,
              title: 'Contact Support',
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(chatControllerProvider.notifier)
                    .sendMessage('contact support');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickReply(String reply, ChatMessage lastMessage) {
    // Handle navigation replies
    if (reply == 'Previous' || reply == 'Next') {
      _handleOrderNavigation(reply, lastMessage);
    } else {
      // Default to sending as message
      ref.read(chatControllerProvider.notifier).sendMessage(reply);
    }
  }

  void _handleOrderNavigation(String reply, ChatMessage lastMessage) {
    // Extract navigation metadata from the last message
    final metadata = lastMessage.metadata;
    if (metadata == null || !metadata.containsKey('order_navigation')) {
      // No navigation data, send as regular message
      ref.read(chatControllerProvider.notifier).sendMessage(reply);
      return;
    }

    final navigationData = metadata['order_navigation'] as Map<String, dynamic>;
    final orderIds = List<String>.from(navigationData['orders']);
    final currentIndex = navigationData['current_index'] as int;
    final type = navigationData['type'] as String;

    int newIndex = currentIndex;
    if (reply == 'Previous' && currentIndex > 0) {
      newIndex = currentIndex - 1;
    } else if (reply == 'Next' && currentIndex < orderIds.length - 1) {
      newIndex = currentIndex + 1;
    }

    // If index changed, navigate to that order
    if (newIndex != currentIndex) {
      // For now, just send a message to indicate navigation
      // In a full implementation, we'd call a specific navigation method
      final direction = newIndex > currentIndex ? 'next' : 'previous';
      ref
          .read(chatControllerProvider.notifier)
          .sendMessage('Show $direction order');
    } else {
      // Can't navigate further, send as regular message
      ref.read(chatControllerProvider.notifier).sendMessage(reply);
    }
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
