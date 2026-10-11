import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Tổng kết tuần (kiểu "Wrapped"): nền đen, hình tròn trang trí mờ, số thu nhập cực lớn.
class WeeklySummaryScreen extends StatelessWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = appState.profile;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // Hình tròn trang trí: chỉ dùng Opacity, không gradient.
          const _Dot(top: -80, right: -90, size: 320, color: AppColors.danger, opacity: 0.16),
          const _Dot(top: 300, right: 40, size: 90, color: AppColors.warning, opacity: 0.14),
          const _Dot(bottom: 120, left: -120, size: 300, color: AppColors.warning, opacity: 0.1),
          const _Dot(bottom: -60, right: -50, size: 200, color: AppColors.danger, opacity: 0.12),
          const _Dot(top: 120, left: 220, size: 10, color: Colors.white, opacity: 0.3),
          const _Dot(bottom: 300, left: 60, size: 8, color: Colors.white, opacity: 0.3),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Đóng',
                        iconSize: 26,
                        padding: const EdgeInsets.all(12),
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          'Tổng kết tuần của bạn',
                          style: appText(30,
                              weight: FontWeight.w800, color: Colors.white, height: 1.2),
                        ),
                        const SizedBox(height: 6),
                        Text(MockData.weekRange, style: appText(15, color: Colors.white54)),
                        const SizedBox(height: 40),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatVnd(MockData.lastWeekIncome),
                            style: appText(60,
                                weight: FontWeight.w900, color: Colors.white, letterSpacing: -2),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text('Thu nhập tuần này',
                                  style:
                                      appText(16, weight: FontWeight.w600, color: Colors.white70)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        _StatCard(
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.success,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${MockData.lastWeekOrders} ',
                                  style: appText(24, weight: FontWeight.w900, color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'đơn hoàn thành',
                                  style:
                                      appText(17, weight: FontWeight.w600, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _StatCard(
                          icon: Icons.star_rounded,
                          iconColor: AppColors.warning,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Đánh giá trung bình ',
                                  style:
                                      appText(17, weight: FontWeight.w600, color: Colors.white70),
                                ),
                                TextSpan(
                                  text: '${MockData.lastWeekRating}',
                                  style: appText(24, weight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _StatCard(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: AppColors.ink,
                          child: Text(
                            'Hạng ${p.tierName} — còn ${p.ordersToNextTier} đơn lên ${p.nextTierName}',
                            style: appText(17, weight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã tạo ảnh thành tích để chia sẻ')),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      icon: const Icon(Icons.ios_share, size: 22),
                      label: Text('Chia sẻ thành tích',
                          style: appText(16, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        appState.setTab(1);
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text('Xem chi tiết lịch sử',
                                style: appText(15, weight: FontWeight.w700, color: Colors.white70)),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.iconColor, required this.child});
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
