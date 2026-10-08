import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/chat_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.isCustomer;
    final foreground = isCustomer ? Colors.white : null;
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width.clamp(0, 600) * .8,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCustomer ? ChatTheme.messageRed : Colors.white,
          border: isCustomer ? null : Border.all(color: ChatTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageBytes case final bytes?)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  bytes,
                  width: 220,
                  height: 160,
                  fit: BoxFit.cover,
                  semanticLabel: 'Ảnh sự cố xe đã gửi',
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 220,
                    height: 160,
                    child: Center(
                      child: Text(
                        'Không thể hiển thị ảnh',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            if (message.text case final text?)
              Text(text, style: TextStyle(color: foreground, height: 1.5)),
            const SizedBox(height: 6),
            Text(
              message.timeLabel,
              style: TextStyle(
                color: isCustomer ? Colors.white70 : ChatTheme.mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
