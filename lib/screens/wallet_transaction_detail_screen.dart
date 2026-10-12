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
    final color = credit ? AppColors.success : AppColors.danger;
    final net = tx.amount;
    final gross = tx.finalPrice == 0 ? net + tx.platformFee : tx.finalPrice;
    final netShare = gross == 0 ? 1.0 : (net / gross).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Chi tiết giao dịch'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: [
                  Center(
                    child: IconCircle(
                      icon: credit ? Icons.check : Icons.arrow_downward,
                      size: 104,
                      background: credit ? AppColors.successSoft : AppColors.dangerSoft,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Số tiền: w700 để cùng độ đậm với các tiêu đề / con số khác trên màn hình.
                  Text(
                    formatSignedVnd(tx.amount, plus: credit),
                    textAlign: TextAlign.center,
                    style: appText(36, weight: FontWeight.w700, color: color, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: pending
                        ? const StatusBadge.pending('Đang chờ duyệt')
                        : const StatusBadge.success('Giao dịch thành công', icon: Icons.check),
                  ),
                  if (tx.customerName != null) ...[
                    const SizedBox(height: 22),
                    ShadowCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Row(
                        children: [
                          AvatarCircle(
                              initials: initialsOf(tx.customerName!), dark: false, size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.customerName!, style: appText(17, weight: FontWeight.w600)),
                                Text(
                                  maskPhone(tx.customerPhone!),
                                  style: appText(13.5, color: AppColors.textSub),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          RoundIconButton(
                            icon: Icons.call_outlined,
                            tooltip: 'Gọi khách',
                            onTap: () => showAppSnack(
                              context,
                              'Đang gọi ${tx.customerName} (${maskPhone(tx.customerPhone!)})...',
                            ),
                          ),
                          const SizedBox(width: 8),
                          RoundIconButton(
                            icon: Icons.chat_bubble_outline,
                            tooltip: 'Nhắn khách',
                            onTap: () => showAppSnack(context, 'Mở chat với ${tx.customerName}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SurfaceCard(
                    radius: AppRadius.lg,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tx.orderCode != null) ...[
                          Text('Đơn hàng liên quan', style: appText(15.5, weight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _Row('Mã đơn', tx.orderCode!, bold: true),
                          _Row('Dịch vụ', tx.serviceName ?? '', bold: true),
                          _Row('Thời gian', formatDayTime(tx.time).replaceAll(' · ', ', '),
                              bold: true),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: DashedDivider(),
                          ),
                        ],
                        Text('Chi tiết giao dịch', style: appText(15.5, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _Row('Mã giao dịch', tx.txnId, bold: true),
                        if (credit) ...[
                          _Row('Giá cuối đơn', formatVnd(gross), bold: true),
                          _Row(
                            '- Chiết khấu sàn',
                            formatSignedVnd(tx.platformFee, plus: false),
                            valueColor: AppColors.danger,
                            bold: true,
                          ),
                          const SizedBox(height: 10),
                          _SplitBar(share: netShare),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 18,
                            runSpacing: 6,
                            children: [
                              _Legend(
                                  color: AppColors.success, label: 'Thực nhận ${formatVnd(net)}'),
                              _Legend(
                                color: AppColors.danger,
                                label: 'Chiết khấu ${formatVnd(tx.platformFee)}',
                              ),
                            ],
                          ),
                        ] else ...[
                          const _Row('Phương thức', 'Chuyển khoản ngân hàng', bold: true),
                          _Row('Thời gian yêu cầu', formatDayTime(tx.time), bold: true),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppColors.textSub),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Giao dịch được MotoCare đối soát & bảo vệ',
                          style: appText(13, color: AppColors.textSub),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlineActionButton(
                    label: 'Chia sẻ biên nhận',
                    icon: Icons.share_outlined,
                    onPressed: () =>
                        showAppSnack(context, 'Đã tạo biên nhận ${tx.txnId} để chia sẻ'),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueColor = AppColors.ink, this.bold = false});
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return KeyValueRow(
      label,
      value,
      valueStyle: appText(15, weight: bold ? FontWeight.w600 : FontWeight.w500, color: valueColor),
    );
  }
}

/// Thanh tỉ lệ thực nhận (xanh) / chiết khấu (đỏ).
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.share});
  final double share;

  @override
  Widget build(BuildContext context) {
    final net = (share * 1000).round().clamp(1, 999);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(flex: net, child: Container(color: AppColors.success)),
            Expanded(flex: 1000 - net, child: Container(color: AppColors.danger)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: appText(13.5, weight: FontWeight.w500, color: AppColors.textSub)),
      ],
    );
  }
}
