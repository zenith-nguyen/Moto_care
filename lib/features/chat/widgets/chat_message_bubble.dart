import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../theme/chat_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.isCustomer;
    final foreground = isCustomer ? Colors.white : ChatTheme.messageText;
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isCustomer
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * .8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCustomer
                      ? ChatTheme.messageRed
                      : ChatTheme.incomingBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isCustomer ? 18 : 5),
                    bottomRight: Radius.circular(isCustomer ? 5 : 18),
                  ),
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
                          errorBuilder: (context, error, stackTrace) =>
                              SizedBox(
                                width: 220,
                                height: 160,
                                child: Center(
                                  child: Text(
                                    'Không thể hiển thị ảnh',
                                    style: TextStyle(color: foreground),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    if (message.text case final text?)
                      Text(
                        text,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  message.timeLabel,
                  style: const TextStyle(
                    color: ChatTheme.timestamp,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
