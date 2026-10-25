import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/revo_brand.dart';
import '../application/admin_operations_controller.dart';
import '../application/admin_operations_state.dart';
import '../domain/admin_operation_models.dart';
import 'admin_formatters.dart';

/// Admin finance & reconciliation hub, wired to the real AdminOperations
/// controller. It covers the money guardrail end to end:
/// withdrawals (approve/reject) -> payouts (owner transfers by hand, then
/// records the bank transaction here) -> refunds and price disputes.
///
/// IMPORTANT: no action on this screen ever moves real money. Approving a
/// withdrawal only opens a payout; reconciling only records a transfer the
/// owner has already made from the bank by hand.
class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOperationsControllerProvider);

    ref.listen(adminOperationsControllerProvider, (previous, next) {
      final failure = next.value?.lastFailure;
      if (failure != null && previous?.value?.lastFailure != failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: RevoBrandColors.dangerDark,
              content: Text('Thao tác không thành công: $failure'),
            ),
          );
      }
    });

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: RevoBrandColors.bg,
        appBar: AppBar(
          backgroundColor: RevoBrandColors.bg,
          foregroundColor: RevoBrandColors.ink,
          title: const Text(
            'Tài chính & đối soát',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Tải lại',
              onPressed: () => ref
                  .read(adminOperationsControllerProvider.notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: RevoBrandColors.primaryDeep,
            unselectedLabelColor: RevoBrandColors.textSubtle,
            indicatorColor: RevoBrandColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              _tab('Rút tiền', state.value?.pendingWithdrawals.length),
              _tab(
                'Đối soát chi',
                state.value?.pendingWithdrawalPayouts.length,
              ),
              _tab('Hoàn tiền', _refundCount(state.value)),
              _tab('Tranh chấp giá', state.value?.pendingPriceDisputes.length),
            ],
          ),
        ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: 'Không tải được dữ liệu tài chính: $error',
            onRetry: () => ref.invalidate(adminOperationsControllerProvider),
          ),
          data: (data) => TabBarView(
            children: [
              _WithdrawalsTab(data: data),
              _PayoutsTab(data: data),
              _RefundsTab(data: data),
              _DisputesTab(data: data),
            ],
          ),
        ),
      ),
    );
  }

  static int? _refundCount(AdminOperationsState? state) {
    if (state == null) return null;
    return state.pendingFullRefunds.length +
        state.pendingRefundAdjustments.length;
  }

  Widget _tab(String label, int? count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: RevoBrandColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Withdrawals (approve / reject)
// ---------------------------------------------------------------------------

class _WithdrawalsTab extends ConsumerWidget {
  const _WithdrawalsTab({required this.data});

  final AdminOperationsState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = data.pendingWithdrawals;
    return _RefreshableList(
      child: items.isEmpty
          ? const _EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              message: 'Không có yêu cầu rút tiền nào chờ duyệt.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _WithdrawalCard(
                item: items[index],
                busy: data.isBusy,
                acting:
                    data.isBusy &&
                    data.action == AdminOperationsAction.resolveWithdrawal &&
                    data.actionTargetId == items[index].request.id,
              ),
            ),
    );
  }
}

class _WithdrawalCard extends ConsumerWidget {
  const _WithdrawalCard({
    required this.item,
    required this.busy,
    required this.acting,
  });

  final AdminWithdrawal item;
  final bool busy;
  final bool acting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = item.request;
    return _FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.provider.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Chip(label: withdrawalStatusLabel(request.status)),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Số tiền', formatAdminMoney(request.amount), emphasize: true),
          _kv('Mã yêu cầu', '#${request.id}'),
          _kv('Mã thợ', '#${item.provider.id}'),
          _kv('Tạo lúc', formatAdminDateTime(request.createdAt)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _reject(context, ref),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: busy ? null : () => _approve(context, ref),
                  child: acting
                      ? const _ButtonSpinner()
                      : const Text('Duyệt yêu cầu'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Duyệt yêu cầu rút tiền',
      message:
          'Duyệt yêu cầu rút ${formatAdminMoney(item.request.amount)} của '
          '${item.provider.name}?\n\nSau khi duyệt, một lệnh chi sẽ được mở ở '
          'tab "Đối soát chi". Bạn sẽ tự chuyển khoản cho thợ rồi ghi nhận lại. '
          'Thao tác này không tự chuyển tiền.',
      confirmLabel: 'Duyệt',
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .resolveWithdrawal(
          requestId: item.request.id,
          decision: AdminDecision.approve,
        );
    if (context.mounted) {
      _reportSuccess(context, ref, 'Đã duyệt yêu cầu rút tiền.');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await _showReasonDialog(
      context,
      title: 'Từ chối yêu cầu rút tiền',
      hint: 'Lý do từ chối (bắt buộc)',
      minLength: 3,
    );
    if (reason == null || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .resolveWithdrawal(
          requestId: item.request.id,
          decision: AdminDecision.reject,
          reason: reason,
        );
    if (context.mounted) {
      _reportSuccess(context, ref, 'Đã từ chối yêu cầu rút tiền.');
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Payouts to reconcile (the manual-transfer money step)
// ---------------------------------------------------------------------------

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab({required this.data});

  final AdminOperationsState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = data.pendingWithdrawalPayouts;
    return _RefreshableList(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const _GuardrailBanner(
            text:
                'Chỉ bấm "Xác nhận đã chuyển" SAU KHI bạn đã tự chuyển khoản '
                'cho thợ từ ngân hàng. Nút này chỉ ghi nhận giao dịch, không tự '
                'động chuyển tiền.',
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: _EmptyState(
                icon: Icons.fact_check_rounded,
                message: 'Không có lệnh chi nào chờ đối soát.',
              ),
            )
          else
            for (final payout in items) ...[
              _PayoutCard(
                payout: payout,
                busy: data.isBusy,
                acting:
                    data.isBusy &&
                    data.action ==
                        AdminOperationsAction.reconcileWithdrawalPayout &&
                    data.actionTargetId == payout.id,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _PayoutCard extends ConsumerWidget {
  const _PayoutCard({
    required this.payout,
    required this.busy,
    required this.acting,
  });

  final AdminWithdrawalPayout payout;
  final bool busy;
  final bool acting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagged = payout.status == WithdrawalPayoutStatus.manualReview;
    return _FinanceCard(
      border: flagged ? RevoBrandColors.warning : RevoBrandColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  payout.provider?.name ?? 'Thợ #${payout.withdrawalId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Chip(
                label: withdrawalPayoutStatusLabel(payout.status),
                color: flagged
                    ? RevoBrandColors.warningDark
                    : RevoBrandColors.primaryDeep,
                background: flagged
                    ? RevoBrandColors.warningSoft
                    : RevoBrandColors.surfaceSoft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _kv(
            'Số tiền cần chi',
            formatAdminMoney(payout.expectedAmount),
            emphasize: true,
          ),
          _kv('Mã lệnh chi', payout.payoutCode),
          _kv('Nội dung chuyển khoản', payout.payoutCode, highlight: true),
          _kv('Mã yêu cầu', '#${payout.withdrawalId}'),
          _kv('Mở lúc', formatAdminDateTime(payout.createdAt)),
          if (payout.reviewReason != null) _kv('Ghi chú', payout.reviewReason!),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RevoBrandColors.warningDark,
                    side: const BorderSide(color: RevoBrandColors.warning),
                  ),
                  onPressed: busy ? null : () => _flag(context, ref),
                  child: const Text('Gắn cờ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: RevoBrandColors.success,
                  ),
                  onPressed: busy ? null : () => _confirm(context, ref),
                  child: acting
                      ? const _ButtonSpinner()
                      : const Text('Xác nhận đã chuyển'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_ReconcileInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ReconcileConfirmSheet(payout: payout),
    );
    if (result == null || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .reconcileWithdrawalPayout(
          payoutId: payout.id,
          decision: PayoutReconciliationDecision.confirm,
          externalTransactionId: result.externalTransactionId,
          observedAmount: result.observedAmount,
          referenceCode: result.referenceCode,
          reason: result.reason,
        );
    if (context.mounted) {
      _reportSuccess(context, ref, 'Đã ghi nhận chi tiền cho thợ.');
    }
  }

  Future<void> _flag(BuildContext context, WidgetRef ref) async {
    final reason = await _showReasonDialog(
      context,
      title: 'Gắn cờ lệnh chi',
      hint: 'Lý do cần kiểm tra lại (bắt buộc)',
      minLength: 3,
    );
    if (reason == null || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .reconcileWithdrawalPayout(
          payoutId: payout.id,
          decision: PayoutReconciliationDecision.flag,
          reason: reason,
        );
    if (context.mounted) {
      _reportSuccess(context, ref, 'Đã gắn cờ lệnh chi để kiểm tra lại.');
    }
  }
}

/// The CONFIRM input sheet. The admin records the bank transaction after the
/// transfer is already done; the observed amount must match the payout.
class _ReconcileConfirmSheet extends StatefulWidget {
  const _ReconcileConfirmSheet({required this.payout});

  final AdminWithdrawalPayout payout;

  @override
  State<_ReconcileConfirmSheet> createState() => _ReconcileConfirmSheetState();
}

class _ReconcileConfirmSheetState extends State<_ReconcileConfirmSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _transactionId;
  late final TextEditingController _observedAmount;
  late final TextEditingController _reference;
  late final TextEditingController _reason;

  @override
  void initState() {
    super.initState();
    _transactionId = TextEditingController();
    _observedAmount = TextEditingController(
      text: widget.payout.expectedAmount.value,
    );
    _reference = TextEditingController();
    _reason = TextEditingController();
  }

  @override
  void dispose() {
    _transactionId.dispose();
    _observedAmount.dispose();
    _reference.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xác nhận đã chuyển khoản',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chỉ xác nhận sau khi bạn đã tự chuyển '
                  '${formatAdminMoney(widget.payout.expectedAmount)} cho '
                  '${widget.payout.provider?.name ?? "thợ"} từ ngân hàng.',
                  style: const TextStyle(color: RevoBrandColors.textSubtle),
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _transactionId,
                  label: 'Mã giao dịch ngân hàng *',
                  hint: 'VD: MBVCB.123456789',
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) {
                      return 'Nhập mã giao dịch (tối thiểu 3 ký tự).';
                    }
                    if (text.length > 120) return 'Tối đa 120 ký tự.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _observedAmount,
                  label: 'Số tiền thực chuyển *',
                  hint: 'VD: ${widget.payout.expectedAmount.value}',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!RegExp(r'^\d+\.\d{2}$').hasMatch(text)) {
                      return 'Định dạng: số với 2 số lẻ (VD 50000.00).';
                    }
                    if (text != widget.payout.expectedAmount.value) {
                      return 'Phải khớp số tiền cần chi '
                          '(${widget.payout.expectedAmount.value}).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _reference,
                  label: 'Mã tham chiếu (tuỳ chọn)',
                  hint: 'VD: FT26010112345678',
                  validator: (value) {
                    if ((value?.trim().length ?? 0) > 120) {
                      return 'Tối đa 120 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _reason,
                  label: 'Ghi chú (tuỳ chọn)',
                  hint: 'VD: Đã kiểm tra người nhận và biên lai',
                  maxLines: 2,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isNotEmpty && text.length < 3) {
                      return 'Tối thiểu 3 ký tự.';
                    }
                    if (text.length > 500) return 'Tối đa 500 ký tự.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: RevoBrandColors.success,
                    ),
                    onPressed: _submit,
                    child: const Text('Ghi nhận đã chi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final reference = _reference.text.trim();
    final reason = _reason.text.trim();
    Navigator.of(context).pop(
      _ReconcileInput(
        externalTransactionId: _transactionId.text.trim(),
        observedAmount: _observedAmount.text.trim(),
        referenceCode: reference.isEmpty ? null : reference,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ReconcileInput {
  const _ReconcileInput({
    required this.externalTransactionId,
    required this.observedAmount,
    required this.referenceCode,
    required this.reason,
  });

  final String externalTransactionId;
  final String observedAmount;
  final String? referenceCode;
  final String? reason;
}

// ---------------------------------------------------------------------------
// Tab 3 — Refunds (full order refunds + adjustment refunds)
// ---------------------------------------------------------------------------

class _RefundsTab extends ConsumerWidget {
  const _RefundsTab({required this.data});

  final AdminOperationsState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullRefunds = data.pendingFullRefunds;
    final adjustments = data.pendingRefundAdjustments;
    final empty = fullRefunds.isEmpty && adjustments.isEmpty;
    return _RefreshableList(
      child: empty
          ? const _EmptyState(
              icon: Icons.replay_rounded,
              message: 'Không có khoản hoàn tiền nào chờ xử lý.',
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (fullRefunds.isNotEmpty) ...[
                  const _GroupLabel('Hoàn toàn bộ đơn'),
                  const SizedBox(height: 10),
                  for (final refund in fullRefunds) ...[
                    _FullRefundCard(
                      refund: refund,
                      busy: data.isBusy,
                      acting:
                          data.isBusy &&
                          data.action ==
                              AdminOperationsAction.refundFullOrder &&
                          data.actionTargetId == refund.orderId,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                if (adjustments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _GroupLabel('Hoàn phần điều chỉnh'),
                  const SizedBox(height: 10),
                  for (final adjustment in adjustments) ...[
                    _AdjustmentCard(
                      adjustment: adjustment,
                      busy: data.isBusy,
                      acting:
                          data.isBusy &&
                          data.action ==
                              AdminOperationsAction.refundAdjustment &&
                          data.actionTargetId == adjustment.order.id,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
    );
  }
}

class _FullRefundCard extends ConsumerWidget {
  const _FullRefundCard({
    required this.refund,
    required this.busy,
    required this.acting,
  });

  final PendingFullRefund refund;
  final bool busy;
  final bool acting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  refund.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (refund.isDemo)
                const _Chip(
                  label: 'SANDBOX',
                  color: RevoBrandColors.warningDark,
                  background: RevoBrandColors.warningSoft,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (refund.amount != null)
            _kv('Số tiền', formatAdminMoney(refund.amount!), emphasize: true),
          _kv('Mã khách', '#${refund.customerId}'),
          if (refund.reason != null) _kv('Lý do', refund.reason!),
          _kv('Tạo lúc', formatAdminDateTime(refund.createdAt)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : () => _refund(context, ref),
              child: acting ? const _ButtonSpinner() : const Text('Hoàn tiền'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refund(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Hoàn toàn bộ đơn ${refund.code}',
      message: refund.amount == null
          ? 'Xác nhận hoàn tiền cho đơn này?'
          : 'Xác nhận hoàn ${formatAdminMoney(refund.amount!)} cho đơn '
                '${refund.code}?',
      confirmLabel: 'Hoàn tiền',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .refundFullOrder(refund.orderId);
    if (context.mounted) {
      _reportSuccess(context, ref, 'Đã xử lý hoàn tiền đơn ${refund.code}.');
    }
  }
}

class _AdjustmentCard extends ConsumerWidget {
  const _AdjustmentCard({
    required this.adjustment,
    required this.busy,
    required this.acting,
  });

  final PendingRefundAdjustment adjustment;
  final bool busy;
  final bool acting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = adjustment.order;
    return _FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (adjustment.isDemo)
                const _Chip(
                  label: 'SANDBOX',
                  color: RevoBrandColors.warningDark,
                  background: RevoBrandColors.warningSoft,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _kv(
            'Số tiền hoàn',
            formatAdminMoney(adjustment.amount),
            emphasize: true,
          ),
          _kv('Mã khách', '#${order.customerId}'),
          _kv('Giá tạm tính', formatAdminMoney(order.estimatedPrice)),
          if (order.finalPrice != null)
            _kv('Giá cuối', formatAdminMoney(order.finalPrice!)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : () => _refund(context, ref),
              child: acting
                  ? const _ButtonSpinner()
                  : const Text('Hoàn phần điều chỉnh'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refund(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Hoàn điều chỉnh ${adjustment.order.code}',
      message:
          'Xác nhận hoàn ${formatAdminMoney(adjustment.amount)} phần '
          'điều chỉnh cho đơn ${adjustment.order.code}?',
      confirmLabel: 'Hoàn tiền',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .refundAdjustment(adjustment.order.id);
    if (context.mounted) {
      _reportSuccess(
        context,
        ref,
        'Đã xử lý hoàn điều chỉnh đơn ${adjustment.order.code}.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 4 — Price disputes (approve / reject)
// ---------------------------------------------------------------------------

class _DisputesTab extends ConsumerWidget {
  const _DisputesTab({required this.data});

  final AdminOperationsState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = data.pendingPriceDisputes;
    return _RefreshableList(
      child: items.isEmpty
          ? const _EmptyState(
              icon: Icons.gavel_rounded,
              message: 'Không có tranh chấp giá nào chờ xử lý.',
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _DisputeCard(
                dispute: items[index],
                busy: data.isBusy,
                acting:
                    data.isBusy &&
                    data.action == AdminOperationsAction.resolvePriceDispute &&
                    data.actionTargetId == items[index].id,
              ),
            ),
    );
  }
}

class _DisputeCard extends ConsumerWidget {
  const _DisputeCard({
    required this.dispute,
    required this.busy,
    required this.acting,
  });

  final AdminPriceDispute dispute;
  final bool busy;
  final bool acting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FinanceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đơn #${dispute.orderId}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _kv(
            'Giá thợ đề xuất',
            formatAdminMoney(dispute.proposedFinalPrice),
            emphasize: true,
          ),
          _kv('Mã thợ', '#${dispute.providerId}'),
          _kv('Lý do đề xuất', dispute.reason),
          if (dispute.disputeReason != null)
            _kv('Khách khiếu nại', dispute.disputeReason!),
          _kv('Tạo lúc', formatAdminDateTime(dispute.createdAt)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RevoBrandColors.dangerDark,
                    side: const BorderSide(color: RevoBrandColors.danger),
                  ),
                  onPressed: busy
                      ? null
                      : () => _resolve(context, ref, AdminDecision.reject),
                  child: const Text('Từ chối giá'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () => _resolve(context, ref, AdminDecision.approve),
                  child: acting
                      ? const _ButtonSpinner()
                      : const Text('Duyệt giá'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    AdminDecision decision,
  ) async {
    final approve = decision == AdminDecision.approve;
    final reason = await _showReasonDialog(
      context,
      title: approve ? 'Duyệt giá đề xuất' : 'Từ chối giá đề xuất',
      hint: 'Lý do quyết định (bắt buộc)',
      minLength: 5,
    );
    if (reason == null || !context.mounted) return;
    await ref
        .read(adminOperationsControllerProvider.notifier)
        .resolvePriceDispute(
          proposalId: dispute.id,
          decision: decision,
          reason: reason,
        );
    if (context.mounted) {
      _reportSuccess(
        context,
        ref,
        approve ? 'Đã duyệt giá đề xuất.' : 'Đã từ chối giá đề xuất.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

void _reportSuccess(BuildContext context, WidgetRef ref, String message) {
  if (!context.mounted) return;
  final failure = ref
      .read(adminOperationsControllerProvider)
      .value
      ?.lastFailure;
  if (failure != null) return; // The error listener already surfaced it.
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: RevoBrandColors.successDark,
        content: Text(message),
      ),
    );
}

Future<bool> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: RevoBrandColors.dangerDark,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> _showReasonDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required int minLength,
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.length < minLength) {
              return 'Nhập tối thiểu $minLength ký tự.';
            }
            if (text.length > 500) return 'Tối đa 500 ký tự.';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

class _RefreshableList extends ConsumerWidget {
  const _RefreshableList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(adminOperationsControllerProvider.notifier).refresh(),
      child: child,
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.child, this.border});

  final Widget child;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RevoBrandColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? RevoBrandColors.border),
      ),
      child: child,
    );
  }
}

class _GuardrailBanner extends StatelessWidget {
  const _GuardrailBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RevoBrandColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RevoBrandColors.warning),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: RevoBrandColors.warningDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: RevoBrandColors.warningDark,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: RevoBrandColors.ink,
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.color = RevoBrandColors.primaryDeep,
    this.background = RevoBrandColors.surfaceSoft,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
}

Widget _kv(
  String label,
  String value, {
  bool emphasize = false,
  bool highlight = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(color: RevoBrandColors.textSubtle),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 16 : 14,
              color: highlight
                  ? RevoBrandColors.primaryDeep
                  : RevoBrandColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: RevoBrandColors.success),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RevoBrandColors.textSubtle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
