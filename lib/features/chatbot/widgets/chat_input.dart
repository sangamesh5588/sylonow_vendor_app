import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

import '../../../core/theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.isLoading = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = widget.controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _sendMessage() {
    final message = widget.controller.text.trim();
    if (message.isNotEmpty && !widget.isLoading) {
      widget.onSendMessage(message);
      widget.controller.clear();
      setState(() {
        _canSend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button (future feature)
            IconButton(
              onPressed: () {
                // TODO: Implement attachment functionality
              },
              icon: const HeroIcon(
                HeroIcons.paperClip,
                size: 20,
                color: AppTheme.textSecondaryColor,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),

            // Text input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 100,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppTheme.dividerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: !widget.isLoading,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: widget.isLoading
                        ? 'AI is typing...'
                        : 'Type your message...',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                  ),
                  onSubmitted: widget.isLoading ? null : (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _canSend && !widget.isLoading
                    ? AppTheme.primaryColor
                    : AppTheme.dividerColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _canSend && !widget.isLoading ? _sendMessage : null,
                icon: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _canSend
                                ? Colors.white
                                : AppTheme.textSecondaryColor,
                          ),
                        ),
                      )
                    : HeroIcon(
                        HeroIcons.paperAirplane,
                        size: 20,
                        color: _canSend
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                      ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
