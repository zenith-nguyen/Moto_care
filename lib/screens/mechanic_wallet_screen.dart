import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'wallet_transaction_detail_screen.dart';
import 'weekly_summary_screen.dart';

class MechanicWalletScreen extends StatefulWidget {
  const MechanicWalletScreen({super.key});

  @override
  State<MechanicWalletScreen> createState() => _MechanicWalletScreenState();
}

class _MechanicWalletScreenState extends State<MechanicWalletScreen> {
  int _selectedDay = 6; // hôm nay

  Future<void> _withdraw() async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _WithdrawSheet(),
    );
    if (amount == null || !mounted) return;
    if (appState.requestWithdraw(amount)) {
      showAppSnack(context, 'Đã ghi nhận yêu cầu rút ${formatVnd(amount)} (sandbox).');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text('Ví của tôi', style: appText(30, weight: FontWeight.w900)),
              const SizedBox(height: 16),
              _BalanceCard(),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  children: [
                    _IncomeStat(value: appState.todayIncome, label: 'Thu nhập hôm nay'),
                    Container(width: 1, color: AppColors.border),
                    _IncomeStat(value: appState.weekIncome, label: 'Thu nhập tuần này'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Rút tiền về Ngân hàng',
                icon: Icons.account_balance_outlined,
                onPressed: _withdraw,
              ),
              const SizedBox(height: 10),
              Text(
                'Bản sandbox — yêu cầu rút được ghi nhận, chưa thực hiện chuyển khoản thật',
                textAlign: TextAlign.center,
                style: appText(12.5, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 26),
              Text('Thu nhập 7 ngày qua',
                  style: appText(16, weight: FontWeight.w800, color: AppColors.textSub)),
              const SizedBox(height: 12),
              _WeekChart(
                values: appState.last7Days,
                selected: _selectedDay,
                onSelect: (i) => setState(() => _selectedDay = i),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text('Lịch sử giao dịch', style: appText(20, weight: FontWeight.w800)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const WeeklySummaryScreen(),
                      ),
                    ),
                    style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                    icon: const Icon(Icons.show_chart, size: 20),
                    label: Text('Tổng kết tuần', style: appText(15, weight: FontWeight.w800)),
                  ),
                ],
              ),
              for (final tx in appState.transactions) ...[
                _TransactionTile(tx: tx),
                const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget sub(String label, int value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: appText(14, color: Colors.white60)),
              const SizedBox(height: 4),
              Text(formatVnd(value),
                  style: appText(18, weight: FontWeight.w900, color: Colors.white)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng số dư', style: appText(15, color: Colors.white70)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatVnd(appState.totalBalance),
              style: appText(44, weight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              children: [
                sub('Khả dụng', appState.available),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white24,
                ),
                sub('Đang khóa', appState.locked),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeStat extends StatelessWidget {
  const _IncomeStat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(formatVnd(value), style: appText(20, weight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: appText(13.5, color: AppColors.textSub)),
        ],
      ),
    );
  }
}

/// Biểu đồ cột thu nhập 7 ngày (vẽ bằng Container, không cần thư viện chart).
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.values, required this.selected, required this.onSelect});
  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 31);
    final today = DateTime.now();
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label:
                    '${weekdayLabel(today.subtract(Duration(days: 6 - i)))}: ${formatVnd(values[i])}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 20,
                        child: i == selected
                            ? FittedBox(
                                child: Text(formatShortVnd(values[i]),
                                    style: appText(12.5, weight: FontWeight.w800)),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 26,
                        height: 100 * values[i] / maxValue + 4,
                        decoration: BoxDecoration(
                          color: i == selected ? AppColors.ink : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        weekdayLabel(today.subtract(Duration(days: 6 - i))),
                        style: appText(14,
                            weight: i == selected ? FontWeight.w800 : FontWeight.w500,
                            color: i == selected ? AppColors.ink : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final color = credit ? AppColors.success : AppColors.danger;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WalletTransactionDetailScreen(tx: tx)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            IconCircle(
              icon: credit ? Icons.arrow_upward : Icons.arrow_downward,
              size: 52,
              background: credit ? AppColors.successSoft : AppColors.dangerSoft,
              color: color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.code, style: appText(16.5, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.title} · ${formatDayTime(tx.time)}',
                    style: appText(13.5, color: AppColors.textSub, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${credit ? '+' : '-'}${formatVnd(tx.amount)}',
                  style: appText(16.5, weight: FontWeight.w900, color: color),
                ),
                if (tx.withdrawStatus != null) ...[
                  const SizedBox(height: 4),
                  tx.withdrawStatus == WithdrawStatus.pending
                      ? const StatusBadge.pending('Đang chờ duyệt')
                      : const StatusBadge.success('Đã duyệt'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final available = appState.available;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rút tiền về Ngân hàng', style: appText(20, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Khả dụng: ${formatVnd(available)}', style: appText(14, color: AppColors.textSub)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: appText(18, weight: FontWeight.w800),
              decoration: const InputDecoration(hintText: 'Số tiền muốn rút', suffixText: 'đ'),
              validator: (v) {
                final n = int.tryParse(v ?? '') ?? 0;
                if (n < 50000) return 'Số tiền rút tối thiểu 50.000đ';
                if (n > available) return 'Vượt quá số dư khả dụng';
                return null;
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Gửi yêu cầu rút',
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.of(context).pop(int.parse(_controller.text));
              },
            ),
          ],
        ),
      ),
    );
  }
}
