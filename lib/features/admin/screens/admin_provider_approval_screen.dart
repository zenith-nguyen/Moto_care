import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_providers.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_review_card.dart';

class AdminProviderApprovalScreen extends ConsumerWidget {
  const AdminProviderApprovalScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminPage(
    title: 'Duyệt hồ sơ thợ',
    children: [
      AdminAsyncSection(
        value: ref.watch(adminProvidersProvider),
        onRetry: () => ref.invalidate(adminProvidersProvider),
        isEmpty: (items) => items.isEmpty,
        builder: (providers) => AdminReviewCardList(
          cards: [
            for (final provider in providers)
              AdminReviewCard(
                key: ValueKey('admin-provider-${provider.id}'),
                titleLabel: 'Mã hồ sơ:',
                title: '${provider.id} • ${provider.name}',
                status: provider.status,
                receivedLabel: 'Đã nhận hồ sơ',
                processingLabel: 'Đang xét duyệt',
                fields: [
                  AdminField.text(
                    'Email / SĐT',
                    '${provider.email}\n${provider.phone}',
                  ),
                  AdminField.text('Thông tin xe', provider.vehicle),
                  AdminField.text('Biển số', provider.plate),
                  AdminField.text(
                    'Thời gian đăng ký',
                    adminDate(provider.registeredAt),
                  ),
                ],
                actions: [
                  AdminReviewAction(
                    label: 'Chi tiết',
                    onPressed: () => context.push(
                      '/admin/providers/${Uri.encodeComponent(provider.id)}',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}
