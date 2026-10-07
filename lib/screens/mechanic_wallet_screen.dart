import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common_widgets.dart';
import 'weekly_summary_screen.dart';

/// Màn 4 — Ví thợ & quản lý doanh thu.
class MechanicWalletScreen extends StatelessWidget {
  const MechanicWalletScreen({super.key});

  Future<void> _deposit(BuildContext context, AppState state) async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AmountSheet(
        title: 'Nạp tiền vào ví',
        subtitle: 'Tiền nạp giúp duy trì mức chiết khấu ưu đãi của sàn.',
        confirmLabel: 'Nạp tiền',
        quickAmounts: [50000, 100000, 200000, 500000],
      ),
    );
    if (amount == null || !context.mounted) return;
    state.deposit(amount);
    showAppSnack(context, 'Đã nạp ${formatVnd(amount)} vào ví (demo).');
  }

  Future<void> _withdraw(BuildContext context, AppState state) async {
    if (state.balance <= 0) {
      showAppSnack(context, 'Số dư ví đang bằng 0, chưa thể rút.');
      return;
    }
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AmountSheet(
        title: 'Rút tiền về ngân hàng',
        subtitle: 'Về tài khoản Vietcombank •••• 4821 (demo).',
        confirmLabel: 'Rút tiền',
        quickAmounts: const [200000, 500000],
        maxAmount: state.balance,
        allowAll: true,
      ),
    );
    if (amount == null || !context.mounted) return;
    if (state.withdraw(amount)) {
      showAppSnack(context, 'Đã gửi yêu cầu rút ${formatVnd(amount)} (demo).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final txs = state.transactions;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Text('Ví của tôi', style: appText(22, weight: FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BalanceCard(
                  balance: state.balance,
                  deposit: state.depositForDiscount,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _deposit(context, state),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: Text('Nạp tiền', style: appText(14.5, weight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.ink, width: 1.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _withdraw(context, state),
                          icon: const Icon(Icons.account_balance_outlined, size: 20),
                          label: Text('Rút tiền về Ngân hàng',
                              style: appText(14.5, weight: FontWeight.w800, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
                child: SectionTitle(
                  'Lịch sử giao dịch',
                  trailing: TextButton.icon(
                    onPressed: () => showWeeklySummary(context),
                    icon: const Icon(Icons.insights_outlined, size: 16),
                    label: Text('Tổng kết tuần',
                        style: appText(12.5, weight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) => _TransactionTile(tx: txs[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card số dư nền đen, trang trí bằng hình tròn đỏ mờ ở góc.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.deposit});
  final int balance;
  final int deposit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg + 4),
      child: Container(
        width: double.infinity,
        color: AppColors.ink,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration:
                    BoxDecoration(color: AppColors.primary.op(0.28), shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: 36,
              bottom: -44,
              child: Container(
                width: 90,
                height: 90,
                decoration:
                    BoxDecoration(color: AppColors.primary.op(0.16), shape: BoxShape.circle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Số dư khả dụng',
                      style: appText(13.5, color: Colors.white.op(0.72))),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatVnd(balance),
                      style: appText(34, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.verified_outlined, size: 16, color: Colors.white.op(0.72)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Tiền nạp duy trì chiết khấu: ${formatVnd(deposit)}',
                          style: appText(12.5, color: Colors.white.op(0.72)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final income = tx.isIncome;
    final color = income ? AppColors.success : AppColors.primary;
    final amountColor = income ? AppColors.successDark : AppColors.primaryDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.op(0.12), shape: BoxShape.circle),
            child: Icon(
              income ? Icons.arrow_upward : Icons.arrow_downward,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.orderId, style: appText(14.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${tx.label} · ${formatTxTime(tx.time, DateTime.now())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatSignedVnd(tx.amount),
            style: appText(14.5, weight: FontWeight.w800, color: amountColor),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet nhập số tiền (dùng cho Nạp / Rút). Trả về số tiền (int) hoặc null.
class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.quickAmounts,
    this.maxAmount,
    this.allowAll = false,
  });

  final String title;
  final String subtitle;
  final String confirmLabel;
  final List<int> quickAmounts;
  final int? maxAmount;
  final bool allowAll; // thêm chip "Rút tất cả"

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _ctrl = TextEditingController();
  String? _error;

  int get _amount => int.tryParse(_ctrl.text) ?? 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setAmount(int v) {
    setState(() {
      _ctrl.text = '$v';
      _error = null;
    });
  }

  void _submit() {
    final max = widget.maxAmount;
    if (_amount <= 0) {
      setState(() => _error = 'Vui lòng nhập số tiền lớn hơn 0.');
    } else if (max != null && _amount > max) {
      setState(() => _error = 'Số tiền vượt quá số dư khả dụng (${formatVnd(max)}).');
    } else {
      Navigator.of(context).pop(_amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final quick = widget.quickAmounts
        .where((v) => widget.maxAmount == null || v <= widget.maxAmount!)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + inset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: appText(18, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(widget.subtitle, style: appText(13, color: AppColors.textSub)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _error = null),
              style: appText(18, weight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Số tiền (đồng)',
                suffixText: 'đ',
                helperText: _amount > 0 ? formatVnd(_amount) : null,
                helperStyle: appText(12.5, weight: FontWeight.w600, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in quick)
                  ActionChip(
                    label: Text(formatVnd(v), style: appText(12.5, weight: FontWeight.w600)),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => _setAmount(v),
                  ),
                if (widget.allowAll && widget.maxAmount != null)
                  ActionChip(
                    label: Text('Rút tất cả', style: appText(12.5, weight: FontWeight.w600)),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => _setAmount(widget.maxAmount!),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error!,
                        style: appText(12.5, weight: FontWeight.w600, color: AppColors.primaryDark)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text(widget.confirmLabel,
                    style: appText(15.5, weight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
