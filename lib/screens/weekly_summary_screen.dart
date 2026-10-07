import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Mở màn "Tổng kết tuần" toàn màn hình (fade + trượt nhẹ).
/// Demo: gọi từ nút test ở Trang chủ / Ví (thực tế sẽ tự bật cuối tuần).
Future<void> showWeeklySummary(BuildContext context) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const WeeklySummaryScreen(),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Màn 6 — Tổng kết tuần kiểu "Wrapped": nền tối, hình tròn trang trí, số lớn đếm lên.
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _share() {
    final state = AppScope.read(context);
    final tier = state.profile.tier;
    final next = tier.next;
    final remaining = tier.ordersToNext(state.profile.totalOrders);
    final text = 'Tuần ${MockData.weekRange} trên MotoCare: '
        '${formatVnd(MockData.weekIncome)} thu nhập, '
        '${MockData.weekOrders} đơn hoàn thành, '
        'đánh giá ${MockData.weekAvgRating.toStringAsFixed(1)}/5. '
        '${next == null ? tier.title : '${tier.title} — còn $remaining đơn lên ${next.name}'}.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã sao chép thành tích — dán vào Zalo/Facebook để chia sẻ.')));
  }

  void _openHistory() {
    AppScope.read(context).setTab(1); // sang tab Ví (lịch sử giao dịch)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tier = state.profile.tier;
    final next = tier.next;
    final remaining = tier.ordersToNext(state.profile.totalOrders);
    final tierLine =
        next == null ? tier.title : '${tier.title} — còn $remaining đơn lên ${next.name}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.wrappedBg,
        body: Stack(
          children: [
            const Positioned.fill(child: _Decorations()),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _CloseButton(onTap: () => Navigator.of(context).pop()),
                          ),
                          const SizedBox(height: 16),
                          _Reveal(
                            controller: _intro,
                            begin: 0.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tổng kết tuần của bạn',
                                    style: appText(27, weight: FontWeight.w800, color: Colors.white, height: 1.2)),
                                const SizedBox(height: 6),
                                Text(MockData.weekRange,
                                    style: appText(14.5, color: Colors.white.op(0.7))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          _Reveal(
                            controller: _intro,
                            begin: 0.12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                      begin: 0, end: MockData.weekIncome.toDouble()),
                                  duration: const Duration(milliseconds: 1600),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) => FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatVnd(value.round()),
                                      style: appText(52, weight: FontWeight.w800, color: Colors.white, height: 1.1),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Thu nhập tuần này',
                                        style: appText(14, weight: FontWeight.w600, color: Colors.white.op(0.75))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          _Reveal(
                            controller: _intro,
                            begin: 0.28,
                            child: _WrappedCard(
                              icon: Icons.check_circle_outline,
                              iconColor: AppColors.success,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text: '${MockData.weekOrders}',
                                        style: appText(20, weight: FontWeight.w800, color: Colors.white)),
                                    TextSpan(
                                        text: ' đơn hoàn thành',
                                        style: appText(15, weight: FontWeight.w600, color: Colors.white.op(0.85))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Reveal(
                            controller: _intro,
                            begin: 0.40,
                            child: _WrappedCard(
                              icon: Icons.star_rounded,
                              iconColor: AppColors.warning,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                              text: 'Đánh giá trung bình ',
                                              style: appText(15, weight: FontWeight.w600, color: Colors.white.op(0.85))),
                                          TextSpan(
                                              text: MockData.weekAvgRating.toStringAsFixed(1),
                                              style: appText(20, weight: FontWeight.w800, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Reveal(
                            controller: _intro,
                            begin: 0.52,
                            child: _WrappedCard(
                              icon: Icons.military_tech_outlined,
                              iconColor: AppColors.primary,
                              child: Text(
                                tierLine,
                                style: appText(15, weight: FontWeight.w700, color: Colors.white, height: 1.3),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          _Reveal(
                            controller: _intro,
                            begin: 0.64,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton.icon(
                                    onPressed: _share,
                                    icon: const Icon(Icons.share_outlined, size: 20),
                                    label: Text('Chia sẻ thành tích',
                                        style: appText(15, weight: FontWeight.w700, color: Colors.white)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: Colors.white.op(0.45), width: 1.4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.md)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _openHistory,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Xem chi tiết lịch sử',
                                          style: appText(13.5, weight: FontWeight.w600, color: Colors.white.op(0.8))),
                                      const SizedBox(width: 6),
                                      Icon(Icons.arrow_forward, size: 16, color: Colors.white.op(0.8)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Hiệu ứng xuất hiện lần lượt (fade + trượt lên) theo Interval.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.controller, required this.begin, required this.child});

  final Animation<double> controller;
  final double begin; // 0..1
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final end = (begin + 0.36).clamp(0.0, 1.0).toDouble();
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Đóng',
      child: Material(
        color: Colors.white.op(0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.close, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Card nhỏ nền trắng mờ trên nền tối.
class _WrappedCard extends StatelessWidget {
  const _WrappedCard({required this.icon, required this.iconColor, required this.child});

  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.op(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.op(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.op(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Hình tròn trang trí (màu đặc + opacity) và các chấm rải rác. Không dùng gradient.
class _Decorations extends StatelessWidget {
  const _Decorations();

  static const List<_Dot> _dots = [
    _Dot(0.12, 0.16, 6, Colors.white, 0.35),
    _Dot(0.30, 0.08, 4, AppColors.warning, 0.8),
    _Dot(0.62, 0.20, 5, Colors.white, 0.3),
    _Dot(0.88, 0.34, 4, AppColors.warning, 0.7),
    _Dot(0.08, 0.46, 5, AppColors.primary, 0.8),
    _Dot(0.93, 0.58, 6, Colors.white, 0.28),
    _Dot(0.20, 0.70, 4, Colors.white, 0.35),
    _Dot(0.74, 0.80, 5, AppColors.primary, 0.7),
    _Dot(0.45, 0.92, 4, AppColors.warning, 0.7),
    _Dot(0.06, 0.88, 6, Colors.white, 0.25),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -70,
              top: -60,
              child: _Circle(size: 260, color: AppColors.primary.op(0.28)),
            ),
            Positioned(
              right: 40,
              top: 150,
              child: _Circle(size: 56, color: AppColors.warning.op(0.22)),
            ),
            Positioned(
              left: -90,
              bottom: 90,
              child: _Circle(size: 240, color: AppColors.warning.op(0.14)),
            ),
            Positioned(
              right: -30,
              bottom: -40,
              child: _Circle(size: 140, color: AppColors.primary.op(0.18)),
            ),
            for (final d in _dots)
              Positioned(
                left: w * d.x,
                top: h * d.y,
                child: _Circle(size: d.size, color: d.color.op(d.opacity)),
              ),
          ],
        );
      },
    );
  }
}

class _Dot {
  const _Dot(this.x, this.y, this.size, this.color, this.opacity);
  final double x;
  final double y;
  final double size;
  final Color color;
  final double opacity;
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
