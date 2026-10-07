import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/rescue_order.dart';
import '../providers/activity_provider.dart';
import '../services/activity_actions.dart';
import '../theme/activity_theme.dart';

class OrderRatingCard extends ConsumerStatefulWidget {
  const OrderRatingCard({super.key, required this.order});
  final RescueOrder order;

  @override
  ConsumerState<OrderRatingCard> createState() => _OrderRatingCardState();
}

class _OrderRatingCardState extends ConsumerState<OrderRatingCard> {
  int? _selection;

  @override
  Widget build(BuildContext context) {
    final canRate = widget.order.status == RescueOrderStatus.completed;
    final rating = _selection?.toDouble() ?? widget.order.rating ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đánh giá dịch vụ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Semantics(
              label:
                  'Đánh giá ${NumberFormat('0.#', 'vi').format(rating)} trên 5 sao',
              child: Wrap(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: 'Đánh giá $star sao',
                      onPressed: canRate
                          ? () => setState(() => _selection = star)
                          : null,
                      icon: Icon(
                        rating >= star
                            ? Icons.star_rounded
                            : rating > star - 1
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                        color: rating > star - 1
                            ? ActivityTheme.orange
                            : ActivityTheme.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              canRate
                  ? widget.order.rating == null
                        ? 'Bạn chưa đánh giá đơn này.'
                        : 'Cảm ơn bạn đã đánh giá!'
                  : 'Chỉ có thể đánh giá đơn đã hoàn thành.',
              style: const TextStyle(
                color: ActivityTheme.mutedText,
                height: 1.5,
              ),
            ),
            if (canRate) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _selection == null
                    ? null
                    : () {
                        final saved = ref
                            .read(activityProvider.notifier)
                            .rateOrder(widget.order.id, _selection!);
                        if (!saved) return;
                        setState(() => _selection = null);
                        ActivityActions.feedback(
                          context,
                          'Đã lưu đánh giá trong phiên dùng thử.',
                        );
                      },
                child: const Text('Lưu đánh giá'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
