import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class QuickRepliesWidget extends StatelessWidget {
  final List<String> replies;
  final Function(String) onReplySelected;

  const QuickRepliesWidget({
    super.key,
    required this.replies,
    required this.onReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) {
      return const SizedBox.shrink();
    }

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
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Quick replies',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Quick reply buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                replies.map((reply) => _buildQuickReplyButton(reply)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyButton(String reply) {
    return InkWell(
      onTap: () => onReplySelected(reply),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          reply,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
