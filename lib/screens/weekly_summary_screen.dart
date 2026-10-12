import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/income_chart.dart';
import '../widgets/ui.dart';

/// Tổng kết tuần: nền trắng phẳng, các card số liệu xếp liền mạch (không còn khung đen che lấp).
class WeeklySummaryScreen extends StatelessWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final p = appState.profile;
            return Column(
              children: [
                ScreenHeader(
                  title: 'Tổng kết tuần',
                  subtitle: MockData.weekRange,
                  showBack: false,
                  trailing: RoundIconButton(
                    icon: Icons.close,
                    tooltip: 'Đóng',
                    size: 48,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      ShadowCard(
                        padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thu nhập tuần này',
                                    style: appText(14.5, color: AppColors.textSub),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      formatVnd(appState.weekIncome),
                                      style:
                                          appText(30, weight: FontWeight.w700, letterSpacing: -0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            StatusBadge.neutral(
                              'Hạng ${p.tierName}',
                              icon: Icons.workspace_premium_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _MetricCard(
                            icon: Icons.layers_outlined,
                            value: '${appState.weekOrders} đơn',
                            label: 'Hoàn thành',
                          ),
                          const SizedBox(width: 12),
                          const _MetricCard(
                            icon: Icons.star_outline_rounded,
                            value: '${MockData.weekRating} ★',
                            label: 'Đánh giá TB',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _MetricCard(
                            icon: Icons.workspace_premium_outlined,
                            value: p.tierName,
                            label: 'Hạng thợ',
                            color: AppColors.textSub,
                          ),
                          const SizedBox(width: 12),
                          const _MetricCard(
                            icon: Icons.schedule,
                            value: MockData.weekActiveHours,
                            label: 'Hoạt động',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShadowCard(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const IconCircle(
                                  icon: Icons.workspace_premium_outlined,
                                  size: 52,
                                  background: AppColors.warningSoft,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Tiến độ lên Hạng ${p.nextTierName}',
                                    style: appText(16, weight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  '${p.tierOrders}/${p.nextTierTarget} đơn',
                                  style: appText(14,
                                      weight: FontWeight.w600, color: AppColors.warning),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: p.tierProgress,
                                minHeight: 7,
                                color: AppColors.warning,
                                backgroundColor: AppColors.border,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                text: 'Hoàn thành thêm ',
                                children: [
                                  TextSpan(
                                    text: '${p.ordersToNextTier} đơn',
                                    style: appText(14, weight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: ' nữa trong tháng này để lên hạng'),
                                ],
                              ),
                              style: appText(14, color: AppColors.textSub, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ShadowCard(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Thu nhập theo ngày',
                                    style: appText(15.5, weight: FontWeight.w600),
                                  ),
                                ),
                                Text.rich(
                                  TextSpan(
                                    text: 'Cao nhất: ',
                                    style: appText(13, color: AppColors.textSub),
                                    children: [
                                      TextSpan(
                                        text: formatVnd(appState.highestDayIncome),
                                        style: appText(13, weight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            IncomeLineChart(
                              values: appState.last7Days,
                              lineColor: AppColors.danger,
                              areaColor: AppColors.dangerSoft.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Chia sẻ thành tích',
                        icon: Icons.share_outlined,
                        color: AppColors.danger,
                        onPressed: () => showAppSnack(context, 'Đã tạo ảnh thành tích để chia sẻ'),
                      ),
                      MutedTextButton(
                        label: 'Xem chi tiết lịch sử',
                        color: AppColors.textSub,
                        onPressed: () {
                          appState.setTab(1);
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SurfaceCard(
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconCircle(
              icon: icon,
              size: 48,
              background: Colors.white,
              color: color == AppColors.ink ? AppColors.ink : color,
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: appText(20, weight: FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 2),
            Text(label, style: appText(13.5, color: AppColors.textSub)),
          ],
        ),
      ),
    );
  }
}
