import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/income_chart.dart';
import '../widgets/ui.dart';
import 'wallet_transaction_detail_screen.dart';
import 'weekly_summary_screen.dart';

class MechanicWalletScreen extends StatefulWidget {
  const MechanicWalletScreen({super.key});

  @override
  State<MechanicWalletScreen> createState() => _MechanicWalletScreenState();
}

class _MechanicWalletScreenState extends State<MechanicWalletScreen> {
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
          child: Column(
            children: [
              const ScreenHeader(title: 'Ví thợ', showBack: false),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    _BalanceCard(balance: appState.balance),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _IncomeStat(label: 'Hôm nay', value: appState.todayIncome),
                        const SizedBox(width: 12),
                        _IncomeStat(label: 'Tuần này', value: appState.weekIncome),
                      ],
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(label: 'Rút tiền về ngân hàng', onPressed: _withdraw),
                    const SizedBox(height: 10),
                    Text(
                      'Bản sandbox — chưa thực hiện chuyển khoản thật',
                      textAlign: TextAlign.center,
                      style: appText(13, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 20),
                    ShadowCard(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Thu nhập 7 ngày qua',
                                  style: appText(15.5, weight: FontWeight.w600),
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  text: 'Cao nhất: ',
                                  style: appText(13, color: AppColors.textSub),
                                  children: [
                                    TextSpan(
                                      text: formatVnd(appState.highestDayIncome),
                                      style: appText(13, weight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          IncomeLineChart(values: appState.last7Days),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Lịch sử giao dịch',
                              style: appText(17, weight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            'Tổng kết tuần',
                            style: appText(14, weight: FontWeight.w600, color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final tx in appState.transactions) ...[
                      _TransactionTile(tx: tx),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(height: 6, color: AppColors.danger),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng số dư',
                      style: appText(14.5, weight: FontWeight.w500, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatVnd(balance),
                          style: appText(32, weight: FontWeight.w700, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeStat extends StatelessWidget {
  const _IncomeStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SurfaceCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: appText(14, color: AppColors.textSub)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatVnd(value), style: appText(17, weight: FontWeight.w600)),
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
    final credit = tx.isCredit;
    final color = credit ? AppColors.success : AppColors.danger;
    return ShadowCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WalletTransactionDetailScreen(tx: tx)),
      ),
      child: Row(
        children: [
          IconCircle(
            icon: credit ? Icons.arrow_upward : Icons.arrow_downward,
            size: 54,
            background: credit ? AppColors.successSoft : AppColors.dangerSoft,
            color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: appText(16, weight: FontWeight.w500, height: 1.25)),
                const SizedBox(height: 2),
                Text(formatDayTime(tx.time), style: appText(13.5, color: AppColors.textSub)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatSignedVnd(tx.amount, plus: credit),
                style: appText(16, weight: FontWeight.w600, color: color),
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
    final balance = appState.balance;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rút tiền về ngân hàng', style: appText(20, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Số dư: ${formatVnd(balance)}', style: appText(14, color: AppColors.textSub)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: appText(18, weight: FontWeight.w700),
              decoration: const InputDecoration(hintText: 'Số tiền muốn rút', suffixText: 'đ'),
              validator: (v) {
                final n = int.tryParse(v ?? '') ?? 0;
                if (n < 50000) return 'Số tiền rút tối thiểu 50.000đ';
                if (n > balance) return 'Vượt quá số dư';
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
