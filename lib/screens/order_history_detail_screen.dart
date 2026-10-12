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
              ScreenHeader(title: 'Chi tiết đơn ${item.code}'),
              Expanded(
                child: ScrollColumn(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    SurfaceCard(
                      radius: AppRadius.md,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_outlined, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.issue, style: appText(17, weight: FontWeight.w600)),
                                Text(
                                  '${item.vehicle} · ${item.plate}',
                                  style: appText(13.5, color: AppColors.textSub),
                                ),
                              ],
                            ),
                          ),
                          done
                              ? const StatusBadge.success('Hoàn thành')
                              : const StatusBadge.danger('Đã hủy'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadowCard(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: _Timeline(events: item.timeline, cancelled: !done),
                    ),
                    if (done) ...[
                      const SizedBox(height: 16),
                      SurfaceCard(
                        radius: AppRadius.md,
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KeyValueRow('Giá ban đầu', formatVnd(item.initialPrice)),
                            KeyValueRow(
                              'Phụ phí phát sinh',
                              item.extra == 0
                                  ? '0đ'
                                  : formatSignedVnd(item.extra.abs(), plus: item.extra > 0),
                            ),
                            if (item.extraReason != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Lý do: ${item.extraReason}',
                                  style: appText(13.5, color: AppColors.textSub, height: 1.4),
                                ),
                              ),
                            const Divider(height: 22),
                            KeyValueRow(
                              'Giá cuối',
                              formatVnd(item.finalPrice),
                              labelStyle: appText(16, weight: FontWeight.w600),
                              valueStyle: appText(20, weight: FontWeight.w700),
                            ),
                            KeyValueRow(
                              'Thu nhập của bạn',
                              formatSignedVnd(item.earning, plus: true),
                              valueStyle:
                                  appText(15, weight: FontWeight.w700, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlineActionButton(
                      label: 'Xem lại lịch sử chat',
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
                    if (done && item.customerRating != null) ...[
                      const SizedBox(height: 16),
                      ShadowCard(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đánh giá từ khách', style: appText(16, weight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _Stars(value: item.customerRating!, size: 26),
                            if (item.customerReview != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"${item.customerReview}"',
                                style: appText(14.5, color: AppColors.textSub, height: 1.45),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (done) ...[
                      const SizedBox(height: 24),
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

class _Stars extends StatelessWidget {
  const _Stars({required this.value, this.size = 30});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= value ? AppColors.warning : AppColors.textMuted,
          ),
      ],
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
                  width: 18,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: cancelled && i == events.length - 1
                              ? AppColors.danger
                              : AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < events.length - 1)
                        Expanded(child: Container(width: 3, color: AppColors.border)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatHm(events[i].time),
                          style: appText(13, weight: FontWeight.w500, color: AppColors.textSub),
                        ),
                        Text(events[i].label, style: appText(15.5, weight: FontWeight.w500)),
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

/// Đánh giá khách (thợ đánh giá): hiển thị đánh giá đã gửi, hoặc form nếu chưa đánh giá.
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
        const SizedBox(height: 10),
        if (rated)
          SurfaceCard(
            radius: AppRadius.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stars(value: item.rating!),
                if (item.ratingComment != null) ...[
                  const SizedBox(height: 6),
                  Text(item.ratingComment!, style: appText(15, height: 1.45)),
                ],
              ],
            ),
          )
        else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i sao',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34,
                    color: i <= _stars ? AppColors.warning : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: appText(15),
            decoration: InputDecoration(
              hintText: 'Nhận xét về khách (không bắt buộc)',
              contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
              ),
            ),
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
