import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kiểu progress DUY NHẤT trong app: tiêu đề + "Bước X/Y" + thanh phẳng ngang
/// + dòng các bước nối bằng mũi tên. Dùng cho chờ duyệt hồ sơ (3 bước) và xử lý đơn (5 bước).
class StepProgressBar extends StatefulWidget {
  const StepProgressBar({
    super.key,
    required this.title,
    required this.current,
    required this.steps,
  });

  final String title;

  /// Bước hiện tại, tính từ 1.
  final int current;
  final List<String> steps;

  @override
  State<StepProgressBar> createState() => _StepProgressBarState();
}

class _StepProgressBarState extends State<StepProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fill;

  double get _target => (widget.current / widget.steps.length).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fill = Tween<double>(begin: 0, end: _target)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StepProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.steps.length != widget.steps.length) {
      _fill = Tween<double>(begin: _fill.value, end: _target)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.title, style: appText(18, weight: FontWeight.w800))),
            Text(
              'Bước ${widget.current}/${widget.steps.length}',
              style: appText(14, weight: FontWeight.w700, color: AppColors.textSub),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _fill,
            builder: (context, _) => LinearProgressIndicator(
              value: _fill.value,
              minHeight: 7,
              color: AppColors.ink,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.steps.join(' → '),
          style: appText(13, color: AppColors.textSub, height: 1.4),
        ),
      ],
    );
  }
}
