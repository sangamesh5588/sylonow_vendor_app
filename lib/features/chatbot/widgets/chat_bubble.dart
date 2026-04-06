import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const ChatBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.type == MessageType.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.type == MessageType.bot) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.type == MessageType.user
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.type == MessageType.user
                        ? AppTheme.primaryColor
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: message.type == MessageType.user
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: message.type == MessageType.user
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.type == MessageType.user
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      if (message.isTyping) ...[
                        const SizedBox(height: 8),
                        _buildTypingIndicator(),
                      ],
                    ],
                  ),
                ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),

                // Status indicators for user messages
                if (message.type == MessageType.user) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(message.status),
                          size: 14,
                          color: _getStatusColor(message.status),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (message.type == MessageType.user) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 18,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline,
        size: 18,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time only
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return DateFormat('EEE HH:mm').format(timestamp);
    } else {
      // Older - show date and time
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.error:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return AppTheme.textSecondaryColor;
      case MessageStatus.sent:
        return AppTheme.textSecondaryColor;
      case MessageStatus.delivered:
        return AppTheme.primaryColor;
      case MessageStatus.read:
        return AppTheme.primaryColor;
      case MessageStatus.error:
        return AppTheme.errorColor;
    }
  }
}
