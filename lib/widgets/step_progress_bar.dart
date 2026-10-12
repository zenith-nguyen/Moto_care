import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kiểu progress DUY NHẤT trong app: nhãn "Bước X/Y" + thanh phẳng ngang + dòng các bước
/// nối bằng dấu mũi tên "›" (bước đã qua đậm, bước chưa tới nhạt).
/// Dùng cho chờ duyệt hồ sơ (3 bước) và xử lý đơn (5 bước).
class StepProgressBar extends StatefulWidget {
  const StepProgressBar({
    super.key,
    required this.current,
    required this.steps,
    this.accent = AppColors.ink,
    this.centeredSteps = false,
  });

  /// Bước hiện tại, tính từ 1.
  final int current;
  final List<String> steps;

  /// Màu thanh + chữ các bước đã qua (đen mặc định, nâu vàng ở màn chờ duyệt).
  final Color accent;
  final bool centeredSteps;

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
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.steps.length; i++) {
      final reached = i < widget.current;
      if (i > 0) {
        spans.add(TextSpan(text: ' › ', style: appText(13, color: AppColors.textMuted)));
      }
      spans.add(TextSpan(
        text: widget.steps[i],
        style: appText(
          13,
          weight: reached ? FontWeight.w600 : FontWeight.w500,
          color: reached ? widget.accent : AppColors.textMuted,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước ${widget.current}/${widget.steps.length}',
          style: appText(15, weight: FontWeight.w600, color: widget.accent),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _fill,
            builder: (context, _) => LinearProgressIndicator(
              value: _fill.value,
              minHeight: 7,
              color: widget.accent,
              backgroundColor: const Color(0xFFE9E9EC),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(children: spans),
            textAlign: widget.centeredSteps ? TextAlign.center : TextAlign.start,
          ),
        ),
      ],
    );
  }
}
