import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'order_history_detail_screen.dart';

/// Total length of the celebration (see the timeline below).
const completionAnimationDuration = Duration(milliseconds: 850);

// Timeline, as fractions of the 850ms controller.
const _popEnd = .21; // 0-180ms: scale 0.65 -> 1.08
const _settleEnd = .42; // 180-360ms: bounce back to 1.0
const _burst = Interval(.21, .76); // 180-650ms
const _titleIn = Interval(.26, .61, curve: Curves.easeOutCubic); // 220-520ms
const _subtitleIn = Interval(.38, .73, curve: Curves.easeOutCubic); // 320-620ms
const _cardIn = Interval(.47, .82, curve: Curves.easeOut); // 400-700ms
const _buttonsIn = Interval(.65, 1, curve: Curves.easeOut); // 550-850ms

/// 0.65 -> 1.08 (ease-out) then 1.08 -> 1.0 (ease-out-back). Never exceeds 1.08.
class _PopScale extends Animatable<double> {
  const _PopScale();
  @override
  double transform(double t) {
    if (t <= _popEnd) {
      return 0.65 + .43 * Curves.easeOut.transform(t / _popEnd);
    }
    if (t <= _settleEnd) {
      final k = (t - _popEnd) / (_settleEnd - _popEnd);
      return 1.08 - .08 * Curves.easeOutBack.transform(k).clamp(0.0, 1.2);
    }
    return 1;
  }
}

class OrderCompletedScreen extends StatefulWidget {
  const OrderCompletedScreen({super.key, required this.item});
  final OrderHistoryItem item;
  @override
  State<OrderCompletedScreen> createState() => _OrderCompletedScreenState();
}

class _OrderCompletedScreenState extends State<OrderCompletedScreen>
    with SingleTickerProviderStateMixin {
  // Purely visual: it never touches the order, wallet or navigation, and runs
  // exactly once when the screen is first shown.
  late final AnimationController _c =
      AnimationController(vsync: this, duration: completionAnimationDuration);
  bool _started = false;

  OrderHistoryItem get item => widget.item;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1; // reduced motion: show the final state directly
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _reveal(Interval interval, double dy, Widget child) {
    final t = CurvedAnimation(parent: _c, curve: interval);
    return FadeTransition(
        opacity: t,
        child: AnimatedBuilder(
            animation: t,
            builder: (_, c) => Transform.translate(
                offset: Offset(0, dy * (1 - t.value)), child: c),
            child: child));
  }

  Widget _badge() {
    const size = 64.0;
    return Center(
        child: SizedBox(
            width: size,
            height: size,
            child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Celebration rays: gone from the tree once finished.
                  AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) => _c.value >= _burst.end
                          ? const SizedBox.shrink()
                          : IgnorePointer(
                              child: RepaintBoundary(
                                  child: CustomPaint(
                                      key: const ValueKey('completed-burst'),
                                      size: const Size(size, size),
                                      painter: _BurstPainter(
                                          _burst.transform(_c.value)))))),
                  FadeTransition(
                      opacity: CurvedAnimation(
                          parent: _c, curve: const Interval(0, _popEnd)),
                      child: ScaleTransition(
                          key: const ValueKey('completed-circle'),
                          scale: _c.drive(const _PopScale()),
                          child: Container(
                              width: size,
                              height: size,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary),
                              child: AnimatedBuilder(
                                  animation: _c,
                                  builder: (_, __) => CustomPaint(
                                      painter: _TickPainter(const Interval(
                                              .1, .45,
                                              curve: Curves.easeOut)
                                          .transform(_c.value))))))),
                ])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(title: ''),
              Expanded(
                child: ListView(
                  padding: AppSpace.pageInsets,
                  children: [
                    const SizedBox(height: 20),
                    _badge(),
                    const SizedBox(height: 20),
                    _reveal(
                        _titleIn,
                        8,
                        Text(
                          'Hoàn thành đơn hàng!',
                          textAlign: TextAlign.center,
                          style: appText(18, weight: FontWeight.w700),
                        )),
                    const SizedBox(height: 12),
                    _reveal(
                        _subtitleIn,
                        8,
                        Text(
                          'Cảm ơn bạn đã mang lại\ntrải nghiệm an toàn cho khách hàng.',
                          textAlign: TextAlign.center,
                          style: appText(12,
                              color: AppColors.textSub, height: 1.6),
                        )),
                    const SizedBox(height: 20),
                    _reveal(
                        _cardIn,
                        10,
                        SurfaceCard(
                          color: AppColors.light,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Thu nhập',
                                      style:
                                          appText(11, color: AppColors.textSub),
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      child: Text(
                                        formatVnd(item.earning),
                                        style: appText(20,
                                            weight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                color: AppColors.border,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Đánh giá',
                                      style:
                                          appText(11, color: AppColors.textSub),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${item.customerRating?.toStringAsFixed(1) ?? '—'} ',
                                          style: appText(20,
                                              weight: FontWeight.w700),
                                        ),
                                        const Icon(
                                          Icons.star_rounded,
                                          color: AppColors.warning,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              FadeTransition(
                  opacity: CurvedAnimation(parent: _c, curve: _buttonsIn),
                  child: Padding(
                    padding: AppSpace.footerInsets,
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: 'Xem chi tiết',
                          color: AppColors.primary,
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderHistoryDetailScreen(item: item),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlineActionButton(
                          label: 'Về trang chủ',
                          borderColor: AppColors.border,
                          onPressed: () {
                            appState.setTab(0);
                            Navigator.popUntil(context, (r) => r.isFirst);
                          },
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
}

/// White check mark drawn progressively (0..1).
class _TickPainter extends CustomPainter {
  const _TickPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final a = Offset(w * .30, w * .52);
    final b = Offset(w * .44, w * .66);
    final c = Offset(w * .71, w * .37);
    final first = (b - a).distance;
    final total = first + (c - b).distance;
    final len = total * progress;
    final path = Path()..moveTo(a.dx, a.dy);
    if (len <= first) {
      final p = a + (b - a) * (len / first);
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(b.dx, b.dy);
      final p = b + (c - b) * ((len - first) / (total - first));
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}

/// Eight short rays around the circle: move out ~26dp while fading to nothing.
class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t);
  final double t; // 0..1 over the burst window
  static const _colors = [
    Color(0xFF317CBB),
    Color(0xFF9CC8F3),
    Color(0xFF317CBB),
    Color(0xFF8FD9B8),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);
    final opacity = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4 + math.pi / 8;
      final dir = Offset(math.cos(angle), math.sin(angle));
      final start = size.width / 2 + 8 + 26 * ease;
      final end = start + 9;
      canvas.drawLine(
          center + dir * start,
          center + dir * end,
          Paint()
            ..color = _colors[i % _colors.length].withValues(alpha: opacity)
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
