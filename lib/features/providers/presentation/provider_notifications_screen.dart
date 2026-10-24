import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../../../core/theme/revo_theme.dart';
import '../../notifications/application/notification_inbox_controller.dart';
import '../../notifications/domain/app_notification.dart';
import 'provider_formatters.dart';

/// Provider notifications inbox, backed by the real shared notifications API
/// (GET /notifications, PATCH read / read-all) via notificationInboxController.
class ProviderNotificationsScreen extends ConsumerWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationInboxControllerProvider);
    final controller = ref.read(notificationInboxControllerProvider.notifier);
    final unread = inbox.value?.unreadCount ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: controller.markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: RevoBrandColors.dangerDark,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Không tải được thông báo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: controller.refresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 44,
                      color: RevoBrandColors.textSubtle,
                    ),
                    SizedBox(height: 10),
                    Text('Chưa có thông báo nào.'),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _NotificationCard(
                  notification: item,
                  onTap: item.readAt == null
                      ? () => controller.markRead(item.id)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.readAt == null;
    return Card(
      color: unread ? RevoBrandColors.surfaceSoft : RevoBrandColors.surface,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: RevoBrandColors.surfaceSoft,
          child: Icon(
            unread
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: RevoBrandColors.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: RevoTypography.label.copyWith(
            fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notification.body, style: RevoTypography.body),
            const SizedBox(height: 4),
            Text(
              formatProviderDateTime(notification.createdAt),
              style: RevoTypography.caption,
            ),
          ],
        ),
        trailing: unread
            ? const Icon(Icons.circle, size: 10, color: RevoBrandColors.primary)
            : null,
      ),
    );
  }
}
