import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_chat_screen.dart';

/// Mở bottom sheet đánh giá khách (dùng ở màn Hoàn thành đơn).
Future<void> showRateCustomerSheet(BuildContext context, OrderHistoryItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
      child: ListenableBuilder(
        listenable: appState,
        builder: (_, __) => _RatingSection(
          item: item,
          onSubmitted: () {
            Navigator.of(ctx).pop();
            showAppSnack(context, 'Đã gửi đánh giá khách ${item.customerName}');
          },
        ),
      ),
    ),
  );
}

class OrderHistoryDetailScreen extends StatelessWidget {
  const OrderHistoryDetailScreen({super.key, required this.item});

  final OrderHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final done = item.status == OrderStatus.completed;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) => Column(
            children: [
              ScreenHeader(title: 'Đơn ${item.code}'),
              Expanded(
                child: ScrollColumn(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.issue, style: appText(17, weight: FontWeight.w800)),
                        ),
                        done
                            ? const StatusBadge.success('Hoàn thành')
                            : const StatusBadge(
                                label: 'Đã hủy',
                                foreground: AppColors.dangerDark,
                                background: AppColors.dangerSoft,
                              ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formatDayTime(item.time), style: appText(14, color: AppColors.textSub)),
                    const SizedBox(height: 22),
                    const SectionTitle('Tiến trình đơn'),
                    const SizedBox(height: 12),
                    _Timeline(events: item.timeline, cancelled: !done),
                    const SizedBox(height: 18),
                    const SectionTitle('Thông tin xe'),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                      child: Column(
                        children: [
                          KeyValueRow('Khách hàng', item.customerName),
                          KeyValueRow('Dòng xe', item.vehicle),
                          KeyValueRow('Biển số', item.plate),
                          KeyValueRow('Địa chỉ', item.address),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const SectionTitle('Chi phí'),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KeyValueRow('Giá ban đầu', formatVnd(item.initialPrice)),
                          KeyValueRow(
                            'Phụ phí phát sinh',
                            item.extra == 0
                                ? '0đ'
                                : '${item.extra > 0 ? '+' : '-'}${formatVnd(item.extra)}',
                          ),
                          if (item.extraReason != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Lý do: ${item.extraReason}',
                                style: appText(13.5, color: AppColors.textSub, height: 1.4),
                              ),
                            ),
                          const Divider(height: 18),
                          KeyValueRow(
                            'Giá cuối',
                            formatVnd(item.finalPrice),
                            labelStyle: appText(16, weight: FontWeight.w800),
                            valueStyle: appText(20, weight: FontWeight.w900),
                          ),
                          if (done)
                            KeyValueRow(
                              'Thu nhập của bạn',
                              '+${formatVnd(item.earning)}',
                              valueStyle:
                                  appText(15, weight: FontWeight.w800, color: AppColors.success),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlineActionButton(
                      label: 'Xem lại chat',
                      icon: Icons.chat_bubble_outline,
                      height: 52,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderChatScreen(
                            customerName: item.customerName,
                            customerPhone: item.customerPhone,
                            messages: item.messages,
                            readOnly: true,
                          ),
                        ),
                      ),
                    ),
                    if (done) ...[
                      const SizedBox(height: 26),
                      _RatingSection(
                        item: item,
                        onSubmitted: () =>
                            showAppSnack(context, 'Đã gửi đánh giá khách ${item.customerName}'),
                      ),
                    ],
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

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events, required this.cancelled});
  final List<TimelineEvent> events;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: cancelled && i == events.length - 1
                              ? AppColors.danger
                              : AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < events.length - 1)
                        Expanded(child: Container(width: 2, color: AppColors.border)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(events[i].label, style: appText(15, weight: FontWeight.w700)),
                        ),
                        Text(formatHm(events[i].time),
                            style: appText(14, color: AppColors.textSub)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Đánh giá khách: hiển thị đánh giá đã gửi, hoặc form nếu chưa đánh giá.
class _RatingSection extends StatefulWidget {
  const _RatingSection({required this.item, required this.onSubmitted});
  final OrderHistoryItem item;
  final VoidCallback onSubmitted;

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  final _commentController = TextEditingController();
  int _stars = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _starRow(int value, {ValueChanged<int>? onTap}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: onTap == null ? null : '$i sao',
            visualDensity: VisualDensity.compact,
            onPressed: onTap == null ? null : () => onTap(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 34,
              color: i <= value ? AppColors.warning : AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rated = item.rating != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionTitle(
          'Đánh giá khách',
          subtitle: rated ? null : 'Đánh giá giúp MotoCare bảo vệ thợ khỏi khách không hợp tác.',
        ),
        const SizedBox(height: 8),
        if (rated)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _starRow(item.rating!),
                if (item.ratingComment != null) ...[
                  const SizedBox(height: 6),
                  Text(item.ratingComment!, style: appText(15, height: 1.45)),
                ],
              ],
            ),
          )
        else ...[
          _starRow(_stars, onTap: (v) => setState(() => _stars = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: appText(15),
            decoration: const InputDecoration(hintText: 'Nhận xét về khách (không bắt buộc)'),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Gửi đánh giá',
            height: 52,
            onPressed: _stars == 0
                ? null
                : () {
                    appState.rateCustomer(item, _stars, _commentController.text);
                    widget.onSubmitted();
                  },
          ),
        ],
      ],
    );
  }
}
