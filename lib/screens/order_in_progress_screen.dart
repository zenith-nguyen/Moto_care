import 'dart:async';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import '../widgets/order_identity.dart';
import 'order_completed_screen.dart';
import 'order_final_quote_screen.dart';
import 'order_received_screen.dart';

class OrderInProgressScreen extends StatefulWidget {
  const OrderInProgressScreen({super.key, required this.order});
  final ActiveOrder order;
  @override
  State<OrderInProgressScreen> createState() => _OrderInProgressScreenState();
}

class _OrderInProgressScreenState extends State<OrderInProgressScreen> {
  late final Timer _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final order = widget.order;
          final pending = order.quoteStatus == QuoteStatus.pending;
          final blocked = order.completionBlockedReason;
          final elapsed = DateTime.now().difference(
            order.repairStartedAt ?? DateTime.now(),
          );
          const steps = [
            'Kiểm tra tình trạng xe',
            'Tiến hành xử lý sự cố',
            'Kiểm tra lại và bàn giao',
          ];
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const ScreenHeader(title: 'Đang sửa chữa'),
                  Expanded(
                    child: ListView(
                      padding: AppSpace.pageInsets,
                      children: [
                        OrderIdentityCard(offer: order.offer),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: order.otpVerifiedAt != null
                              ? const StatusBadge.success('Đã xác nhận OTP')
                              : const StatusBadge.pending('Chưa xác nhận OTP'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatHms(elapsed),
                          textAlign: TextAlign.center,
                          style: appText(
                            26,
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Vui lòng hoàn thành đúng quy trình,\nđảm bảo an toàn.',
                          textAlign: TextAlign.center,
                          style: appText(13,
                              color: AppColors.textSub, height: 1.7),
                        ),
                        const SizedBox(height: 14),
                        for (var i = 0; i < steps.length; i++)
                          InkWell(
                            onTap:
                                order.canAdvanceRepair && i == order.repairStage
                                    ? () => appState.advanceRepair(
                                        orderId: order.orderId)
                                    : null,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < order.repairStage
                                          ? AppColors.successSoft
                                          : AppColors.light,
                                      border: Border.all(
                                        color: i == order.repairStage
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      '0${i + 1}',
                                      style: appText(
                                        10,
                                        weight: FontWeight.w600,
                                        color: i < order.repairStage
                                            ? AppColors.successDark
                                            : i == order.repairStage
                                                ? AppColors.primary
                                                : AppColors.textSub,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      steps[i],
                                      style: appText(
                                        13,
                                        weight: i == order.repairStage
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    i < order.repairStage
                                        ? Icons.check_circle_rounded
                                        : (i == order.repairStage &&
                                                order.canAdvanceRepair)
                                            ? Icons
                                                .radio_button_unchecked_rounded
                                            : Icons.lock_outline_rounded,
                                    color: i < order.repairStage
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (pending ||
                            order.rejectedQuoteNeedsAction ||
                            order.quoteStatus == QuoteStatus.accepted) ...[
                          SurfaceCard(
                            color: AppColors.light,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pending
                                      ? 'Đang chờ khách duyệt'
                                      : order.rejectedQuoteNeedsAction
                                          ? 'Khách từ chối báo giá'
                                          : 'Khách đã duyệt báo giá',
                                  style: appText(
                                    13,
                                    weight: FontWeight.w600,
                                    color: order.rejectedQuoteNeedsAction &&
                                            !pending
                                        ? AppColors.danger
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pending
                                      ? appState.demoEnabled
                                          ? 'Mở báo giá bên dưới, chọn mô phỏng khách đồng ý hoặc từ chối. Chỉ bước kiểm tra xe được thực hiện trong lúc chờ.'
                                          : 'Chờ phản hồi khách hàng. Chỉ bước kiểm tra xe được thực hiện trong lúc chờ.'
                                      : order.rejectedQuoteNeedsAction
                                          ? 'Mở báo giá để chỉnh sửa, gửi lại hoặc bỏ phát sinh bị từ chối.'
                                          : 'Chi phí đã xác nhận: ${formatVnd(order.finalPrice)}. Hoàn tất sửa chữa và bàn giao.',
                                  style: appText(
                                    12,
                                    color: AppColors.textSub,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderFinalQuoteScreen(
                                      order: order,
                                      fromRepair: true,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  pending
                                      ? 'Xem báo giá đang chờ duyệt'
                                      : order.rejectedQuoteNeedsAction
                                          ? 'Xử lý báo giá bị từ chối'
                                          : 'Báo giá phát sinh',
                                  style: appText(12, color: AppColors.primary),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Nhắn khách',
                              onPressed: () => openOrderChat(context, order),
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          title: Text(
                            'Chi tiết & báo giá',
                            style: appText(13, color: AppColors.textSub),
                          ),
                          children: [
                            SurfaceCard(
                              color: AppColors.light,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          order.offer.customerName,
                                          style: appText(
                                            13,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Nhắn khách',
                                        onPressed: () =>
                                            openOrderChat(context, order),
                                        icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${order.offer.vehicle} · ${order.offer.issue}',
                                    style:
                                        appText(13, color: AppColors.textSub),
                                  ),
                                  KeyValueRow(
                                    'Tổng chi phí',
                                    formatVnd(order.finalPrice),
                                  ),
                                  if (order.quoteStatus == QuoteStatus.accepted)
                                    const StatusBadge.success(
                                      'Khách đã duyệt báo giá',
                                    ),
                                  if (order.quoteStatus == QuoteStatus.rejected)
                                    const StatusBadge.danger(
                                      'Khách từ chối · Giữ chi phí đã xác nhận',
                                    ),
                                  const SizedBox(height: 12),
                                  OutlineActionButton(
                                    label: pending
                                        ? 'Xem báo giá đang chờ duyệt'
                                        : order.rejectedQuoteNeedsAction
                                            ? 'Xử lý báo giá bị từ chối'
                                            : 'Báo giá phát sinh',
                                    borderColor: AppColors.border,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderFinalQuoteScreen(
                                          order: order,
                                          fromRepair: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: AppSpace.footerInsets,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (blocked != null) ...[
                          Text(
                            blocked,
                            key: const ValueKey('completion-blocked-reason'),
                            textAlign: TextAlign.center,
                            style: appText(
                              11,
                              color: AppColors.textSub,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        PrimaryButton(
                          label: 'Hoàn thành sửa chữa',
                          onPressed: blocked != null
                              ? null
                              : () {
                                  try {
                                    final item = appState.completeOrder(
                                      orderId: order.orderId,
                                    );
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrderCompletedScreen(item: item),
                                      ),
                                      (r) => r.isFirst,
                                    );
                                  } on StateError catch (error) {
                                    showAppSnack(context, error.message);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
