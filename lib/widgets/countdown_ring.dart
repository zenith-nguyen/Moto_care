import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Vòng tròn đếm ngược vẽ bằng CircularProgressIndicator, số thời gian còn lại ở giữa.
/// Dùng cho popup offer 15s (đỏ) và chờ khách duyệt giá 10 phút (vàng cam).
class CountdownRing extends StatefulWidget {
  const CountdownRing({
    super.key,
    required this.total,
    required this.color,
    required this.labelBuilder,
    this.startedAt,
    this.size = 72,
    this.strokeWidth = 6,
    this.fontSize = 20,
    this.onFinished,
  });

  final Duration total;
  final Color color;
  final String Function(Duration remaining) labelBuilder;

  /// Mốc bắt đầu đếm (để tiếp tục đúng thời gian khi mở lại màn). Mặc định: lúc hiển thị.
  final DateTime? startedAt;
  final double size;
  final double strokeWidth;
  final double fontSize;
  final VoidCallback? onFinished;

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished?.call();
      });
    final elapsed =
        widget.startedAt == null ? Duration.zero : DateTime.now().difference(widget.startedAt!);
    final from = (elapsed.inMilliseconds / widget.total.inMilliseconds).clamp(0.0, 1.0);
    _controller.forward(from: from);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final fraction = 1 - _controller.value;
          // Làm tròn lên để "15s" hiển thị ngay từ đầu và về "0s" đúng lúc hết giờ.
          final remaining = Duration(
            seconds: (widget.total.inMilliseconds * fraction / 1000).ceil(),
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: fraction,
                strokeWidth: widget.strokeWidth,
                color: widget.color,
                backgroundColor: widget.color.withValues(alpha: 0.18),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  widget.labelBuilder(remaining),
                  style: appText(widget.fontSize, weight: FontWeight.w900, color: widget.color),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
