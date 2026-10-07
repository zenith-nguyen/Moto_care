import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/widgets/home_bottom_navigation.dart';

import '../models/chat_conversation.dart';
import '../theme/chat_theme.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key, this.conversation});

  final ChatConversation? conversation;

  @override
  Widget build(BuildContext context) {
    final chat = conversation;
    return Theme(
      data: ChatTheme.light,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/tin-nhan');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Chi tiết Chat'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: chat == null
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Chọn một cuộc trò chuyện trong Tin nhắn để xem chi tiết.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: ChatTheme.surface,
                              foregroundColor: ChatTheme.orange,
                              child: Text(chat.avatarInitials),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chat.mechanicName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat.licensePlate,
                                    style: const TextStyle(
                                      color: ChatTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          chat.statusLabel ?? chat.status.label,
                          style: TextStyle(
                            color: chat.status == RescueStatus.completed
                                ? ChatTheme.green
                                : ChatTheme.orange,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ChatTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.lastMessage,
                                  style: const TextStyle(height: 1.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  chat.timeLabel,
                                  style: const TextStyle(
                                    color: ChatTheme.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        bottomNavigationBar: HomeBottomNavigation(
          selectedDestination: HomeDestination.account,
          onSelected: (destination) => navigateMainTab(context, destination),
        ),
      ),
    );
  }
}
