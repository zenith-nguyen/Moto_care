import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_common.dart';

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
        builder: (providers) => AdminRecordList(
          records: [
            for (final provider in providers)
              AdminRecord(
                title: '${provider.id} • ${provider.name}',
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
                  AdminField(
                    'Trạng thái',
                    AdminStatusChip(
                      provider.status.label,
                      color: adminReviewColor(provider.status),
                    ),
                  ),
                ],
                actions: [
                  OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _ProviderDetails(provider: provider),
                    ),
                    child: const Text('Chi tiết'),
                  ),
                ],
              ),
          ],
        ),
      ),
    ],
  );
}

class _ProviderDetails extends ConsumerWidget {
  const _ProviderDetails({required this.provider});
  final AdminProviderApplication provider;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(adminSessionProvider)?.isAdmin == true;
    return AlertDialog(
      scrollable: true,
      title: Text(provider.name, textAlign: TextAlign.center),
      content: allowed
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hồ sơ: ${provider.id}'),
                Text('Email: ${provider.email}'),
                Text('SĐT: ${provider.phone}'),
                Text('Xe: ${provider.vehicle}'),
                Text('Biển số: ${provider.plate}'),
                Text('Đăng ký: ${adminDate(provider.registeredAt)}'),
                const SizedBox(height: 12),
                AdminStatusChip(
                  provider.status.label,
                  color: adminReviewColor(provider.status),
                ),
              ],
            )
          : const AdminStateView.forbidden(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        if (allowed)
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showAdminAction(
                context,
                kind: AdminActionKind.provider,
                id: provider.id,
                approve: false,
                title: 'Từ chối hồ sơ thợ',
                description: '${provider.name} • ${provider.id}',
                noteRequired: true,
              );
            },
            child: const Text('Từ chối'),
          ),
        if (allowed)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              showAdminAction(
                context,
                kind: AdminActionKind.provider,
                id: provider.id,
                approve: true,
                title: 'Duyệt hồ sơ thợ',
                description:
                    'Cấp quyền hoạt động cho ${provider.name} (${provider.id})?',
              );
            },
            child: const Text('Duyệt'),
          ),
      ],
    );
  }
}
