import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

class WalletTransactionDetailScreen extends StatelessWidget {
  const WalletTransactionDetailScreen({super.key, required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final pending = tx.withdrawStatus == WithdrawStatus.pending;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Chi tiết giao dịch'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    credit ? 'Cộng tiền từ đơn hàng' : 'Yêu cầu rút tiền về Ngân hàng',
                    textAlign: TextAlign.center,
                    style: appText(15, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${credit ? '+' : '-'}${formatVnd(tx.amount)}',
                    textAlign: TextAlign.center,
                    style: appText(40,
                        weight: FontWeight.w900,
                        color: credit ? AppColors.success : AppColors.danger,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: pending
                        ? const StatusBadge.pending('Đang chờ duyệt')
                        : const StatusBadge.success(
                            'Giao dịch thành công',
                            icon: Icons.check,
                          ),
                  ),
                  if (tx.customerName != null) ...[
                    const _SectionLabel('Khách hàng'),
                    _BorderCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          AvatarCircle(initial: tx.customerName![0], size: 56),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.customerName!, style: appText(17, weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  '${maskPhone(tx.customerPhone!)} · ${tx.customerArea}',
                                  style: appText(13.5, color: AppColors.textSub),
                                ),
                              ],
                            ),
                          ),
                          RoundIconButton(
                            icon: Icons.call_outlined,
                            tooltip: 'Gọi khách',
                            size: 52,
                            onTap: () => showAppSnack(context,
                                'Đang gọi ${tx.customerName} (${maskPhone(tx.customerPhone!)})...'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (tx.orderCode != null) ...[
                    const _SectionLabel('Đơn hàng liên quan'),
                    _BorderCard(
                      child: Column(
                        children: [
                          _Row('Mã đơn', tx.orderCode!),
                          const Divider(height: 1),
                          _Row('Dịch vụ', tx.serviceName ?? ''),
                          const Divider(height: 1),
                          _Row('Thời gian hoàn tất', formatDayTime(tx.time)),
                        ],
                      ),
                    ),
                  ],
                  const _SectionLabel('Chi tiết giao dịch'),
                  _BorderCard(
                    child: Column(
                      children: [
                        _Row('Mã giao dịch', tx.txnId),
                        const Divider(height: 1),
                        _Row('Phương thức', credit ? 'Ví MotoCare' : 'Chuyển khoản Ngân hàng'),
                        const Divider(height: 1),
                        if (credit)
                          _Row('Chiết khấu sàn (đã trừ riêng)', '-${formatVnd(tx.platformFee)}',
                              valueColor: AppColors.textSub)
                        else
                          _Row('Thời gian yêu cầu', formatDayTime(tx.time)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: OutlineActionButton(
                label: 'Chia sẻ biên nhận',
                icon: Icons.ios_share,
                onPressed: () => showAppSnack(context, 'Đã tạo biên nhận ${tx.txnId} để chia sẻ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(text, style: appText(16, weight: FontWeight.w800, color: AppColors.textSub)),
    );
  }
}

class _BorderCard extends StatelessWidget {
  const _BorderCard({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueColor = AppColors.ink});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Expanded(child: Text(label, style: appText(15, color: AppColors.textSub))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: appText(15, weight: FontWeight.w800, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
