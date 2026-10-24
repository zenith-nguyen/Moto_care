import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_operation_models.dart';

/// Admin provider-approval queue, wired to the real AdminOperationsController
/// (GET /admin/providers/pending, PATCH /admin/providers/:id/approval).
class AdminProviderApprovalScreen extends ConsumerWidget {
  const AdminProviderApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOperationsControllerProvider);
    return Scaffold(
      backgroundColor: RevoBrandColors.bg,
      appBar: AppBar(
        backgroundColor: RevoBrandColors.bg,
        foregroundColor: RevoBrandColors.ink,
        title: const Text(
          'Duyệt hồ sơ thợ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () =>
                ref.read(adminOperationsControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Error(
          message: 'Không tải được hàng chờ duyệt: $error',
          onRetry: () => ref.invalidate(adminOperationsControllerProvider),
        ),
        data: (data) {
          final items = data.pendingProviders;
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 44,
                      color: RevoBrandColors.success,
                    ),
                    SizedBox(height: 10),
                    Text('Không có hồ sơ thợ nào chờ duyệt.'),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(adminOperationsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ProviderCard(
                application: items[index],
                busy: data.isBusy,
                acting: data.isBusy && data.actionTargetId == items[index].id,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  const _ProviderCard({
    required this.application,
    required this.busy,
    required this.acting,
  });

  final PendingProviderApplication application;
  final bool busy;
  final bool acting;

  Future<void> _review(WidgetRef ref, ProviderApprovalStatus status) {
    return ref
        .read(adminOperationsControllerProvider.notifier)
        .reviewProvider(providerId: application.id, status: status);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact =
        application.phone ?? application.email ?? 'Không có liên hệ';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RevoBrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: RevoBrandColors.surfaceSoft,
                child: Icon(
                  Icons.engineering_rounded,
                  color: RevoBrandColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact,
                      style: const TextStyle(color: RevoBrandColors.textSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (application.documentUrl != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: RevoBrandColors.textSubtle,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    application.documentUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RevoBrandColors.primaryDeep,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _review(ref, ProviderApprovalStatus.rejected),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () => _review(ref, ProviderApprovalStatus.approved),
                  child: acting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Duyệt'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
