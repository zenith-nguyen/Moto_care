import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common_widgets.dart';
import '../widgets/radar_map.dart';
import '../widgets/tier_progress_card.dart';
import '../widgets/urgent_order_chip.dart';
import '../widgets/weather_banner.dart';
import 'incoming_order_popup.dart';
import 'mechanic_active_order_screen.dart';
import 'weekly_summary_screen.dart';

/// Màn 1 — Trang chủ Thợ.
class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  bool _popupOpen = false;

  /// Mở popup nổ đơn rồi xử lý kết quả (nhận -> sang màn thực hiện đơn).
  Future<void> _openIncoming(OrderRequest order) async {
    final state = AppScope.read(context);
    if (!state.isOnline) {
      showAppSnack(context, 'Bạn đang tạm nghỉ — bật "Đang nhận đơn" để nhận đơn mới.');
      return;
    }
    if (_popupOpen) return;
    _popupOpen = true;
    final result = await showIncomingOrderPopup(context, order);
    _popupOpen = false;
    if (!mounted) return;

    if (result == IncomingOrderResult.accepted) {
      state.removeNearby(order);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MechanicActiveOrderScreen(order: order),
        ),
      );
    } else if (result == IncomingOrderResult.rejected) {
      state.removeNearby(order);
      showAppSnack(context, 'Đã từ chối — đơn được chuyển cho thợ khác.');
    } else if (result == IncomingOrderResult.timeout) {
      state.removeNearby(order);
      showAppSnack(context, 'Hết thời gian phản hồi — đơn đã chuyển cho thợ khác.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(state: state),
              const SizedBox(height: _HomeHeader.belowStats),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TierProgressCard(
                      tier: profile.tier,
                      totalOrders: profile.totalOrders,
                      onLongPress: state.cycleTierDemo,
                    ),
                    if (state.isRainIncoming) ...[
                      const SizedBox(height: 12),
                      const WeatherBanner(),
                    ],
                    const SizedBox(height: 20),
                    SectionTitle(
                      'Khu vực hoạt động',
                      trailing: Text(
                        state.isOnline ? 'Đang quét đơn...' : 'Đã tắt',
                        style: appText(12.5,
                            weight: FontWeight.w600,
                            color: state.isOnline ? AppColors.primaryDark : AppColors.textSub),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RadarMap(
                      active: state.isOnline,
                      radiusKm: MockData.activeRadiusKm,
                      orders: state.nearbyOrders,
                    ),
                    const SizedBox(height: 20),
                    SectionTitle(
                      'Đơn khẩn cấp gần bạn',
                      trailing: Text('${state.nearbyOrders.length} đơn',
                          style: appText(12.5, weight: FontWeight.w600, color: AppColors.textSub)),
                    ),
                    const SizedBox(height: 10),
                    _OrderModeToggle(
                      mode: state.orderMode,
                      onChanged: state.setOrderMode,
                    ),
                    const SizedBox(height: 12),
                    if (state.orderMode == OrderMode.auto)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'Chế độ tự động: đơn khẩn cấp sẽ nổ thẳng lên màn hình và bạn có 15 giây để phản hồi. '
                          'Dùng "Giả lập nổ đơn" bên dưới để xem thử.',
                          style: appText(13, color: AppColors.textSub, height: 1.4),
                        ),
                      ),
                  ],
                ),
              ),
              if (state.orderMode == OrderMode.manual)
                _NearbyOrdersList(
                  orders: state.nearbyOrders,
                  onTap: _openIncoming,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: _DemoTools(
                  onSimulate: () => _openIncoming(state.nextIncomingOrder()),
                  onWeekly: () => showWeeklySummary(context),
                  onToggleRain: () => state.setRain(!state.isRainIncoming),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header đen + card thống kê nổi đè mép dưới.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state});
  final AppState state;

  static const double statsHeight = 92;
  static const double overlap = 46;

  /// Khoảng trống cần chừa phía dưới Stack (phần card nhô ra ngoài header).
  static const double belowStats = statsHeight - overlap + 16;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final profile = state.profile;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, top + 14, 16, overlap + 20),
          decoration: const BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(
            children: [
              AvatarCircle(initial: profile.initial, size: 52, borderColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appText(17, weight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    if (profile.verified) const VerifiedBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _OnlineSwitch(
                isOnline: state.isOnline,
                onChanged: state.setOnline,
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -(statsHeight - overlap),
          height: statsHeight,
          child: _StatsCard(state: state),
        ),
      ],
    );
  }
}

class _OnlineSwitch extends StatelessWidget {
  const _OnlineSwitch({required this.isOnline, required this.onChanged});

  final bool isOnline;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: isOnline,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.online,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.disabled,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.online : AppColors.disabled,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'Đang nhận đơn' : 'Tạm nghỉ',
              style: appText(11.5, weight: FontWeight.w600, color: Colors.white.op(0.9)),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Doanh thu hôm nay',
              value: Text(formatVnd(state.todayRevenue),
                  style: appText(17, weight: FontWeight.w800)),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatItem(
              label: 'Đơn hoàn thành',
              value: Text('${state.todayOrders}', style: appText(17, weight: FontWeight.w800)),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatItem(
              label: 'Đánh giá',
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(state.profile.rating.toStringAsFixed(1),
                      style: appText(17, weight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: value),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: appText(11.5, color: AppColors.textSub, height: 1.25),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: AppColors.border);
}

/// Chọn chế độ nhận đơn: tự động (nổ đơn) hoặc tự chọn từ danh sách.
class _OrderModeToggle extends StatelessWidget {
  const _OrderModeToggle({required this.mode, required this.onChanged});

  final OrderMode mode;
  final ValueChanged<OrderMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              label: 'Tự động nhận đơn',
              selected: mode == OrderMode.auto,
              onTap: () => onChanged(OrderMode.auto),
            ),
          ),
          Expanded(
            child: _ModeSegment(
              label: 'Tự chọn đơn',
              selected: mode == OrderMode.manual,
              onTap: () => onChanged(OrderMode.manual),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: appText(13,
                weight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSub),
          ),
        ),
      ),
    );
  }
}

/// ListView ngang các đơn khẩn cấp gần đó.
class _NearbyOrdersList extends StatelessWidget {
  const _NearbyOrdersList({required this.orders, required this.onTap});

  final List<OrderRequest> orders;
  final ValueChanged<OrderRequest> onTap;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Chưa có đơn khẩn cấp nào quanh bạn. Đơn mới sẽ hiện ở đây.',
            textAlign: TextAlign.center,
            style: appText(13.5, color: AppColors.textSub),
          ),
        ),
      );
    }
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => UrgentOrderChip(
          order: orders[i],
          onTap: () => onTap(orders[i]),
        ),
      ),
    );
  }
}

/// Khu vực nút test để demo nhanh trên lớp (không phải tính năng thật).
class _DemoTools extends StatelessWidget {
  const _DemoTools({
    required this.onSimulate,
    required this.onWeekly,
    required this.onToggleRain,
  });

  final VoidCallback onSimulate;
  final VoidCallback onWeekly;
  final VoidCallback onToggleRain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: AppColors.textSub),
              const SizedBox(width: 6),
              Text('Công cụ demo', style: appText(12.5, weight: FontWeight.w700, color: AppColors.textSub)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DemoButton(label: 'Giả lập nổ đơn', icon: Icons.bolt_outlined, onTap: onSimulate),
              _DemoButton(label: 'Tổng kết tuần', icon: Icons.insights_outlined, onTap: onWeekly),
              _DemoButton(label: 'Bật/tắt cảnh báo mưa', icon: Icons.thunderstorm_outlined, onTap: onToggleRain),
            ],
          ),
          const SizedBox(height: 8),
          Text('Mẹo: bấm giữ vào card hạng để xem các hạng khác.',
              style: appText(11.5, color: AppColors.textSub)),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: appText(12.5, weight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}
