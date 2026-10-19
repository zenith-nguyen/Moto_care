import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/amount_formatter.dart';
import '../widgets/ui.dart';
import '../widgets/app_status.dart';
import 'wallet_transaction_detail_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _form = GlobalKey<FormState>();
  late final _requestId =
      'withdraw-${identityHashCode(this)}-${DateTime.now().microsecondsSinceEpoch}';
  String? _transactionId;
  final _amount = TextEditingController(text: '1.000.000');
  bool _submitting = false;
  bool _done = false;
  int _submittedAmount = 0;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final amount = parseAmount(_amount.text);
    final tx = appState.requestWithdraw(amount, requestId: _requestId);
    if (tx == null) {
      setState(() => _submitting = false);
      _form.currentState!.validate();
      showAppSnack(
        context,
        appState.networkAvailable
            ? 'Yêu cầu chưa hợp lệ. Vui lòng kiểm tra số dư.'
            : 'Mất kết nối mạng. Vui lòng thử lại.',
      );
      return;
    }
    _transactionId = tx.txnId;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _done = true;
      _submitting = false;
      _submittedAmount = amount;
    });
  }

  Widget _action() => PrimaryButton(
        label: _submitting ? 'Đang xử lý…' : 'Rút tiền',
        color: AppColors.primary,
        onPressed: _submitting ? null : _submit,
      );
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: _done ? 'Yêu cầu đã được gửi' : 'Rút tiền'),
              Expanded(
                child: _done
                    ? ListView(
                        padding: AppSpace.pageInsets,
                        children: [
                          const SizedBox(height: 24),
                          const Center(
                            child: IconCircle(
                              icon: Icons.check_rounded,
                              size: 72,
                              background: AppColors.surfaceSoft,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Đã gửi yêu cầu rút tiền',
                            textAlign: TextAlign.center,
                            style: appText(18, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Yêu cầu của bạn đang được xử lý.\nTheo dõi trạng thái trong lịch sử giao dịch.',
                            textAlign: TextAlign.center,
                            style: appText(13, color: AppColors.textSub),
                          ),
                          const SizedBox(height: 20),
                          SurfaceCard(
                            color: AppColors.light,
                            child: Column(
                              children: [
                                KeyValueRow(
                                    'Số tiền', formatVnd(_submittedAmount)),
                                const KeyValueRow('Ngân hàng', 'Vietcombank'),
                                const KeyValueRow('Tài khoản', '•••• 1234'),
                                const KeyValueRow('Trạng thái', 'Đang xử lý'),
                                KeyValueRow(
                                    'Mã giao dịch', _transactionId ?? '—'),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Form(
                        key: _form,
                        child: ListView(
                          padding: AppSpace.pageInsets,
                          children: [
                            const FieldLabel('Số tiền'),
                            TextFormField(
                              controller: _amount,
                              keyboardType: TextInputType.number,
                              inputFormatters: [AmountInputFormatter()],
                              style: appText(20, weight: FontWeight.w600),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                suffixText: 'đ',
                                hintText: '0',
                              ),
                              validator: (v) {
                                final amount = parseAmount(v ?? '');
                                if (amount < 50000) {
                                  return 'Số tiền rút tối thiểu 50.000đ';
                                }
                                if (amount > appState.balance) {
                                  return 'Số tiền vượt quá số dư khả dụng';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Số dư khả dụng: ${formatVnd(appState.balance)}',
                              style: appText(11, color: AppColors.textSub),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (final amount in [200000, 500000, 1000000])
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        showCheckmark: false,
                                        label: FittedBox(
                                          child: Text(
                                            formatNumber(amount),
                                            style: appText(
                                              12,
                                              color:
                                                  parseAmount(_amount.text) ==
                                                          amount
                                                      ? Colors.white
                                                      : AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        selected:
                                            parseAmount(_amount.text) == amount,
                                        selectedColor: AppColors.primary,
                                        backgroundColor: AppColors.light,
                                        side: BorderSide.none,
                                        onSelected: (_) => setState(
                                          () => _amount.text =
                                              formatNumber(amount),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const FieldLabel('Ngân hàng'),
                            Material(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => showReceivingAccount(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_outlined,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Vietcombank',
                                              style: appText(
                                                13,
                                                weight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '•••• 1234',
                                              style: appText(
                                                12,
                                                color: AppColors.textSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: AppColors.textSub,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_submitting)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: AppStatusView(
                                  kind: AppStatusKind.loading,
                                  compact: true,
                                ),
                              ),
                            _action(),
                            const SizedBox(height: 12),
                            Text(
                              'Giao dịch mô phỏng · Không chuyển tiền thật',
                              textAlign: TextAlign.center,
                              style: appText(11, color: AppColors.textSub),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_done)
                Padding(
                  padding: AppSpace.footerInsets,
                  child: Column(
                    children: [
                      OutlineActionButton(
                        label: 'Xem trạng thái giao dịch',
                        borderColor: AppColors.border,
                        onPressed: () {
                          final tx = appState.transactions.firstWhere(
                            (tx) => tx.txnId == _transactionId,
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  WalletTransactionDetailScreen(tx: tx),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        label: 'Quay lại ví',
                        color: AppColors.primary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}

void showReceivingAccount(BuildContext context) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Tài khoản liên kết',
          style: appText(17, weight: FontWeight.w600),
        ),
        content: Text(
          'Vietcombank\n${appState.profile.name.toUpperCase()}\n•••• 1234\n\nTài khoản mẫu cho luồng rút tiền mô phỏng.',
          style: appText(13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
