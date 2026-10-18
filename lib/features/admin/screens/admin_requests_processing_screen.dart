import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_action_dialog.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_review_card.dart';

class AdminRequestsProcessingScreen extends ConsumerStatefulWidget {
  const AdminRequestsProcessingScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  ConsumerState<AdminRequestsProcessingScreen> createState() =>
      _AdminRequestsProcessingScreenState();
}

class _AdminRequestsProcessingScreenState
    extends ConsumerState<AdminRequestsProcessingScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(adminPendingCountsProvider).asData?.value;
    return DefaultTabController(
      length: 3,
      initialIndex: _tab,
      child: AdminPage(
        title: 'Xử lý yêu cầu',
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (index) => setState(() => _tab = index),
            tabs: [
              Tab(
                text:
                    'Hoàn tiền${counts == null ? '' : ' (${counts.refunds})'}',
              ),
              Tab(
                text:
                    'Tranh chấp giá${counts == null ? '' : ' (${counts.disputes})'}',
              ),
              Tab(
                text:
                    'Rút tiền${counts == null ? '' : ' (${counts.withdrawals})'}',
              ),
            ],
          ),
          switch (_tab) {
            0 => const _RefundList(),
            1 => const _DisputeList(),
            _ => const _WithdrawalList(),
          },
        ],
      ),
    );
  }
}

class _RefundList extends ConsumerWidget {
  const _RefundList();
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsyncSection(
    value: ref.watch(adminRefundsProvider),
    onRetry: () => ref.invalidate(adminRefundsProvider),
    isEmpty: (items) => items.isEmpty,
    builder: (items) => AdminReviewCardList(
      cards: [
        for (final refund in items)
          AdminReviewCard(
            key: ValueKey('admin-refund-${refund.id}'),
            title: '${refund.id} • ${refund.orderId}',
            status: refund.status,
            fields: [
              AdminField.text(
                'Nguồn yêu cầu',
                refund.source == 'refund'
                    ? 'Hoàn tiền đơn'
                    : 'Điều chỉnh thanh toán',
              ),
              AdminField.text('Tiền hoàn', adminMoney(refund.amount)),
              AdminField.text('Lý do', refund.reason),
              AdminField.text('Mã Sandbox', refund.sandboxTransaction),
            ],
          ),
      ],
    ),
  );
}

class _DisputeList extends ConsumerWidget {
  const _DisputeList();
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsyncSection(
    value: ref.watch(adminDisputesProvider),
    onRetry: () => ref.invalidate(adminDisputesProvider),
    isEmpty: (items) => items.isEmpty,
    builder: (items) => AdminReviewCardList(
      cards: [
        for (final dispute in items)
          AdminReviewCard(
            key: ValueKey('admin-dispute-${dispute.id}'),
            title: '${dispute.id} • ${dispute.orderId}',
            status: dispute.status,
            fields: [
              AdminField.text('Giá gốc', adminMoney(dispute.originalPrice)),
              AdminField.text(
                'Giá thợ đề xuất',
                adminMoney(dispute.proposedPrice),
              ),
              AdminField.text(
                'Chênh lệch',
                '${dispute.difference > 0 ? '+' : ''}${adminMoney(dispute.difference)}',
              ),
              AdminField.text('Lý do thợ', dispute.providerReason),
              AdminField.text('Phản hồi khách', dispute.customerReply),
            ],
            actions: [
              AdminReviewAction(
                label: 'Chấp nhận giá đề xuất',
                onPressed: () => _resolve(context, dispute, true),
              ),
              AdminReviewAction(
                label: 'Bác đề xuất',
                destructive: true,
                onPressed: () => _resolve(context, dispute, false),
              ),
            ],
          ),
      ],
    ),
  );
  void _resolve(
    BuildContext context,
    AdminPriceDispute dispute,
    bool approve,
  ) => showAdminAction(
    context,
    kind: AdminActionKind.dispute,
    id: dispute.id,
    approve: approve,
    title: approve ? 'Chấp nhận giá đề xuất' : 'Bác đề xuất giá',
    description:
        '${dispute.orderId}: ${adminMoney(dispute.originalPrice)} → ${adminMoney(dispute.proposedPrice)}. '
        'Giá sẽ được chốt theo quyết định này; phần tiền chênh lệch cần đối chiếu riêng.',
    noteRequired: true,
  );
}

class _WithdrawalList extends ConsumerWidget {
  const _WithdrawalList();
  @override
  Widget build(BuildContext context, WidgetRef ref) => AdminAsyncSection(
    value: ref.watch(adminWithdrawalDetailsProvider),
    onRetry: () {
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminWalletProvider);
    },
    isEmpty: (items) => items.isEmpty,
    builder: (items) => AdminReviewCardList(
      cards: [
        for (final snapshot in items)
          AdminReviewCard(
            key: ValueKey('admin-withdrawal-${snapshot.request.id}'),
            titleLabel: 'Mã yêu cầu:',
            title: '${snapshot.request.id} • ${snapshot.request.providerName}',
            status: snapshot.request.status,
            fields: [
              AdminField.text(
                'Tiền yêu cầu',
                adminMoney(snapshot.request.amount),
              ),
              AdminField.text(
                'Số dư ví (gồm khóa)',
                adminMoney(snapshot.wallet.balance),
              ),
              AdminField.text(
                'Số dư khả dụng',
                adminMoney(snapshot.wallet.available),
              ),
              AdminField.text(
                'Số dư đang khóa',
                adminMoney(snapshot.wallet.locked),
              ),
              AdminField.text(
                'Thời gian',
                adminDate(snapshot.request.createdAt),
              ),
            ],
            actions: [
              AdminReviewAction(
                label: 'Duyệt',
                onPressed: () => _resolve(context, snapshot, true),
              ),
              AdminReviewAction(
                label: 'Từ chối',
                destructive: true,
                onPressed: () => _resolve(context, snapshot, false),
              ),
              AdminReviewAction(
                label: 'Lịch sử ví',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AdminWalletHistoryDialog(
                    providerId: snapshot.request.providerId,
                    providerName: snapshot.request.providerName,
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
  void _resolve(
    BuildContext context,
    AdminWithdrawalSnapshot snapshot,
    bool approve,
  ) => showAdminAction(
    context,
    kind: AdminActionKind.withdrawal,
    id: snapshot.request.id,
    approve: approve,
    title: approve ? 'Duyệt rút tiền' : 'Từ chối rút tiền',
    description:
        '${snapshot.request.providerName} • ${snapshot.request.id}\n'
        'Số tiền: ${adminMoney(snapshot.request.amount)}\n'
        'Đang khóa: ${adminMoney(snapshot.wallet.locked)}\n'
        '${approve ? 'Xác nhận chi trả mô phỏng từ số dư đang khóa?' : 'Số tiền sẽ được mở khóa về số dư khả dụng.'}',
    noteRequired: !approve,
  );
}

class AdminWalletHistoryDialog extends ConsumerWidget {
  const AdminWalletHistoryDialog({
    super.key,
    required this.providerId,
    required this.providerName,
  });
  final String providerId;
  final String providerName;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AlertDialog(
    scrollable: true,
    title: Text('Ví • $providerName', textAlign: TextAlign.center),
    content: SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminAsyncSection(
            value: ref.watch(adminWalletProvider(providerId)),
            onRetry: () => ref.invalidate(adminWalletProvider(providerId)),
            builder: (wallet) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tổng số dư: ${adminMoney(wallet.balance)}'),
                Text('Khả dụng: ${adminMoney(wallet.available)}'),
                Text('Đang khóa: ${adminMoney(wallet.locked)}'),
                const Divider(height: 28),
                if (wallet.history.isEmpty) const AdminStateView.empty(),
                for (final entry in wallet.history.reversed)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${entry.label} • ${adminMoney(entry.amount)}'),
                    subtitle: Text('${entry.id}\n${adminDate(entry.at)}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Đóng'),
      ),
    ],
  );
}
