import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

/// Card hạng thợ (gamification): huy chương đổi màu theo hạng + progress bar.
/// Bấm giữ để đổi sang hạng kế tiếp (chỉ dùng khi demo).
class TierProgressCard extends StatefulWidget {
  const TierProgressCard({
    super.key,
    required this.tier,
    required this.totalOrders,
    this.onLongPress,
  });

  final TierInfo tier;
  final int totalOrders;
  final VoidCallback? onLongPress;

  @override
  State<TierProgressCard> createState() => _TierProgressCardState();
}

class _TierProgressCardState extends State<TierProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _progress;

  double get _target => widget.tier.progress(widget.totalOrders);

  Animation<double> _tween(double from, double to) {
    return Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = _tween(0, _target);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant TierProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTarget = oldWidget.tier.progress(oldWidget.totalOrders);
    if (oldTarget != _target) {
      _progress = _tween(_progress.value, _target);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    final next = tier.next;
    final remaining = tier.ordersToNext(widget.totalOrders);

    final caption = next == null
        ? 'Bạn đang ở hạng cao nhất. Giữ vững phong độ nhé!'
        : 'Còn $remaining đơn nữa lên ${next.title}';
    final countText = next == null
        ? '${widget.totalOrders} đơn'
        : '${widget.totalOrders}/${next.minOrders} đơn';

    return AppCard(
      onLongPress: widget.onLongPress,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tier.color.op(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.military_tech_outlined,
              size: 30,
              color: tier.color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.title,
                      style: appText(16, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      countText,
                      style: appText(
                        12,
                        weight: FontWeight.w600,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 8,
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(caption, style: appText(12.5, color: AppColors.textSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
