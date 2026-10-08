import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/main_navigation.dart';
import '../../home/models/home_destination.dart';
import '../../home/widgets/home_bottom_navigation.dart';
import '../models/chat_conversation.dart';
import '../theme/chat_theme.dart';

Future<bool> _launchPhone(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class TinNhanScreen extends StatelessWidget {
  const TinNhanScreen({super.key, this.launchPhone = _launchPhone});

  final Future<bool> Function(Uri) launchPhone;

  Future<void> _callMechanic(
    BuildContext context,
    ChatConversation conversation,
  ) async {
    var opened = false;
    try {
      opened = await launchPhone(
        Uri(scheme: 'tel', path: conversation.phoneNumber),
      );
    } on Exception {
      opened = false;
    }
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Không thể mở ứng dụng gọi điện. '
            'Bạn có thể gọi số ${conversation.phoneNumber}.',
          ),
        ),
      );
  }

  void _selectDestination(BuildContext context, HomeDestination destination) {
    navigateMainTab(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ChatTheme.light,
      child: DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Scaffold(
          backgroundColor: ChatTheme.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              'Tin nhắn',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: ChatTheme.red,
              unselectedLabelColor: ChatTheme.mutedText,
              indicatorColor: ChatTheme.red,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Cứu hộ'),
                Tab(text: 'Hỗ trợ CSKH'),
                Tab(text: 'Thông báo'),
              ],
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: TabBarView(
                  children: [
                    ListView.builder(
                      key: const PageStorageKey('rescue-conversations'),
                      padding: const EdgeInsets.all(16),
                      itemCount: mockRescueConversations.length,
                      itemBuilder: (context, index) {
                        final conversation = mockRescueConversations[index];
                        return _RescueConversationCard(
                          conversation: conversation,
                          onTap: () =>
                              context.push('/chat-detail', extra: conversation),
                          onCall: () => _callMechanic(context, conversation),
                        );
                      },
                    ),
                    const _AdminMessageList(
                      storageKey: 'customer-support',
                      icon: Icons.support_agent_rounded,
                      messages: [
                        (
                          title: 'CSKH MotoCare',
                          message: 'Xin chào! MotoCare có thể giúp gì cho bạn hôm nay?',
                          time: '09:00',
                        ),
                        (
                          title: 'Hỗ trợ đơn cứu hộ',
                          message: 'Nếu cần hỗ trợ về đơn cứu hộ, hãy gửi mã đơn cho đội ngũ CSKH.',
                          time: 'Hôm qua',
                        ),
                      ],
                    ),
                    const _AdminMessageList(
                      storageKey: 'admin-notifications',
                      icon: Icons.notifications_outlined,
                      messages: [
                        (
                          title: 'Chào mừng đến với MotoCare',
                          message: 'Đội ngũ MotoCare luôn sẵn sàng đồng hành và hỗ trợ bạn trên mọi hành trình.',
                          time: '08:30',
                        ),
                        (
                          title: 'Đơn cứu hộ đã hoàn tất',
                          message: 'Cảm ơn bạn đã sử dụng dịch vụ. Hãy đánh giá trải nghiệm để MotoCare phục vụ tốt hơn.',
                          time: 'Hôm qua',
                        ),
                        (
                          title: 'Nhắc nhở bảo dưỡng xe',
                          message: 'Kiểm tra lốp, phanh và dầu máy định kỳ để chuyến đi luôn an toàn.',
                          time: '28/09',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: HomeBottomNavigation(
            selectedDestination: HomeDestination.account,
            backgroundColor: ChatTheme.navigationSurface,
            selectedIconColor: ChatTheme.red,
            unselectedIconColor: ChatTheme.red,
            onSelected: (destination) =>
                _selectDestination(context, destination),
          ),
        ),
      ),
    );
  }
}

class _RescueConversationCard extends StatelessWidget {
  const _RescueConversationCard({
    required this.conversation,
    required this.onTap,
    required this.onCall,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final statusColor = conversation.status == RescueStatus.completed
        ? ChatTheme.green
        : ChatTheme.orange;
    return Card(
      color: ChatTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ChatTheme.background,
                    foregroundColor: ChatTheme.orange,
                    child: Text(conversation.avatarInitials),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.mechanicName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          conversation.licensePlate,
                          style: const TextStyle(
                            color: ChatTheme.mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Gọi ${conversation.mechanicName}',
                    onPressed: onCall,
                    color: ChatTheme.red,
                    icon: const Icon(Icons.phone),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  conversation.statusLabel ?? conversation.status.label,
                ),
                labelStyle: const TextStyle(
                  color: ChatTheme.background,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: statusColor,
                side: BorderSide(color: statusColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      conversation.lastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ChatTheme.mutedText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    conversation.timeLabel,
                    style: const TextStyle(
                      color: ChatTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _AdminMessage = ({String title, String message, String time});

class _AdminMessageList extends StatelessWidget {
  const _AdminMessageList({
    required this.storageKey,
    required this.icon,
    required this.messages,
  });

  final String storageKey;
  final IconData icon;
  final List<_AdminMessage> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: PageStorageKey(storageKey),
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Card(
          color: ChatTheme.surface,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: ChatTheme.background,
                  child: Icon(icon, color: ChatTheme.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.message,
                        style: const TextStyle(
                          color: ChatTheme.mutedText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message.time,
                        style: const TextStyle(
                          color: ChatTheme.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
