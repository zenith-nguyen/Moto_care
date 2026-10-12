import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/map_views.dart';
import '../widgets/ui.dart';
import 'incoming_order_popup.dart';
import 'order_received_screen.dart';

/// Trang chủ Thợ. Không có danh sách đơn để tự chọn: khi đang bật, MotoCare tự ghép
/// đơn gần nhất và đẩy popup offer (mock: sau vài giây ở Trang chủ).
class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  static const _firstMatchDelay = Duration(seconds: 5);
  static const _nextMatchDelay = Duration(seconds: 12);

  Timer? _matchTimer;
  bool _offerOpen = false;

  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChanged);
    _scheduleMatch(_firstMatchDelay);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChanged);
    _matchTimer?.cancel();
    super.dispose();
  }

  bool get _canMatch => appState.isOnline && appState.activeOrder == null && !_offerOpen;

  void _onStateChanged() {
    if (!_canMatch) {
      _matchTimer?.cancel();
    } else if (!(_matchTimer?.isActive ?? false)) {
      _scheduleMatch(_firstMatchDelay);
    }
  }

  void _scheduleMatch(Duration delay) {
    _matchTimer?.cancel();
    if (!_canMatch) return;
    _matchTimer = Timer(delay, _deliverOffer);
  }

  Future<void> _deliverOffer() async {
    if (!mounted || !_canMatch) return;
    // Chỉ hiện offer khi thợ đang ở Trang chủ (không che màn khác).
    final visible = appState.tabIndex == 0 && (ModalRoute.of(context)?.isCurrent ?? false);
    if (!visible) {
      _scheduleMatch(const Duration(seconds: 3));
      return;
    }
    _offerOpen = true;
    // Offer thứ hai mô phỏng mất kết nối tạm thời trước khi hiện đơn.
    final reconnecting = appState.offerSeq == 1;
    await showIncomingOrder(context, appState.nextOffer(), reconnecting: reconnecting);
    _offerOpen = false;
    if (mounted) _scheduleMatch(_nextMatchDelay);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = appState.profile;
        final online = appState.isOnline;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _Header(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: online ? AppColors.success : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: online ? 'GPS · 2 phút trước' : 'Đã tắt định vị',
                      labelStyle: appText(14, weight: FontWeight.w500, color: AppColors.textSub),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Pill(
                    leading: const Icon(Icons.arrow_upward, size: 16, color: AppColors.success),
                    label: formatVnd(appState.todayIncome),
                    labelStyle: appText(15, weight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.soft,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Stack(
                    children: [
                      Positioned.fill(child: RadarMap(active: online)),
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: MapChip(label: 'Bán kính hoạt động · ${p.radiusKm} km'),
                      ),
                      Positioned(
                        right: 14,
                        top: 14,
                        child: RoundIconButton(
                          icon: Icons.navigation_outlined,
                          tooltip: 'Về vị trí của tôi',
                          white: true,
                          onTap: () => showAppSnack(context, 'Đã định vị lại vị trí của bạn'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(child: _OnlineToggle(online: online)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  online ? 'Đang nhận đơn' : 'Tạm nghỉ — không nhận đơn',
                  style: appText(
                    16.5,
                    weight: FontWeight.w600,
                    color: online ? AppColors.success : AppColors.textSub,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _StatCard(value: '${appState.weekOrders}', label: 'Đơn / tuần'),
                  const SizedBox(width: 10),
                  _StatCard(value: formatShortVnd(appState.weekIncome), label: 'Thu nhập tuần'),
                  const SizedBox(width: 10),
                  _StatCard(value: formatShortVnd(appState.weekWithdrawn), label: 'Đã rút tuần'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star_outline_rounded, color: AppColors.warning, size: 26),
                  const SizedBox(width: 6),
                  Text('${p.rating}', style: appText(16, weight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'đánh giá TB · ${p.ratingCount} lượt',
                      style: appText(14.5, color: AppColors.textSub),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MatchingCard(),
              const SizedBox(height: 14),
              const _WeatherCard(),
              const SizedBox(height: 14),
              const _TierCard(),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = appState.profile;
    return Row(
      children: [
        AvatarCircle(initials: p.initials, size: 60),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(p.name, style: appText(20, weight: FontWeight.w600)),
                  StatusBadge.neutral('Hạng ${p.tierName}', icon: Icons.workspace_premium_outlined),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Đã duyệt & xác minh',
                      overflow: TextOverflow.ellipsis,
                      style: appText(13.5, weight: FontWeight.w600, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        RoundIconButton(
          icon: Icons.notifications_none,
          tooltip: 'Thông báo',
          size: 52,
          onTap: () => showAppSnack(context, 'Bạn chưa có thông báo mới'),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.leading, required this.label, required this.labelStyle});
  final Widget leading;
  final String label;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 10),
          Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle)),
        ],
      ),
    );
  }
}

/// Nút tròn lớn bật/tắt nhận đơn (xanh khi bật, xám khi tắt).
class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : const Color(0xFF6B7280);
    return Semantics(
      button: true,
      toggled: online,
      label: online ? 'Đang bật nhận đơn, chạm để tắt' : 'Đang tắt nhận đơn, chạm để bật',
      child: GestureDetector(
        onTap: () => appState.setOnline(!online),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 36,
                spreadRadius: 4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                online ? 'ĐANG BẬT' : 'ĐANG TẮT',
                style: appText(22, weight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                online ? 'Chạm để tắt' : 'Chạm để bật',
                style: appText(14, weight: FontWeight.w500, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: appText(22, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appText(13, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khối trạng thái ghép đơn tự động (không cho thợ tự chọn đơn).
class _MatchingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final active = appState.activeOrder;
    final (title, body) = active != null
        ? (
            'Bạn đang xử lý đơn ${active.offer.code}',
            'Hoàn thành đơn hiện tại để tiếp tục nhận offer mới.',
          )
        : appState.isOnline
            ? (
                'Đang chờ đơn phù hợp…',
                'Hệ thống tự ghép đơn gần bạn nhất, không cần chọn tay',
              )
            : (
                'Bạn đang tắt nhận đơn',
                'Chạm nút ĐANG TẮT phía trên để bật lại và nhận offer gần bạn.',
              );

    return SurfaceCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 28),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: appText(16.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(body, style: appText(14, color: AppColors.textSub, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (active != null) ...[
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Tiếp tục đơn',
              height: 48,
              onPressed: () => openActiveOrder(context, active),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: AppColors.warningDark, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockData.weatherTitle,
                  style: appText(16.5, weight: FontWeight.w600, color: AppColors.warningDark),
                ),
                const SizedBox(height: 2),
                Text(
                  MockData.weatherNote,
                  style: appText(14,
                      weight: FontWeight.w500, color: AppColors.warningDark, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard();

  @override
  Widget build(BuildContext context) {
    final p = appState.profile;
    return SurfaceCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hạng ${p.tierName} → Hạng ${p.nextTierName}',
                  style: appText(16.5, weight: FontWeight.w600),
                ),
              ),
              Text(
                '${p.tierOrders}/${p.nextTierTarget} đơn',
                style: appText(14, weight: FontWeight.w600, color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          Text(
            'Còn ${p.ordersToNextTier} đơn nữa trong 30 ngày',
            style: appText(14, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
