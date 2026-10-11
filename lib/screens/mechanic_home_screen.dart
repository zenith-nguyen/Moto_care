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
    await showIncomingOrder(context, appState.nextOffer());
    _offerOpen = false;
    if (mounted) _scheduleMatch(_nextMatchDelay);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = appState.profile;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(),
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 340,
                    child: Stack(
                      children: [
                        Positioned.fill(child: RadarMap(active: appState.isOnline)),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _MapPill(
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: appState.isOnline ? AppColors.success : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            label:
                                appState.isOnline ? 'Đã cập nhật · 2 phút trước' : 'Đã tắt định vị',
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _MapPill(
                            leading:
                                const Icon(Icons.arrow_upward, size: 18, color: AppColors.success),
                            label: formatVnd(appState.todayIncome),
                            big: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 312),
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 28),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                    ),
                    child: Column(
                      children: [
                        _StatsRow(),
                        const Divider(height: 32),
                        _RatingRow(rating: p.rating, count: p.ratingCount),
                        const Divider(height: 32),
                        _MatchingBlock(),
                        const Divider(height: 36),
                        const _WeatherRow(),
                        const Divider(height: 36),
                        const _TierCard(),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 312 - 80,
                    left: 0,
                    right: 0,
                    child: Center(child: _OnlineToggle()),
                  ),
                ],
              ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          AvatarCircle(initial: p.initial, size: 56),
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
                    Text(p.name, style: appText(19, weight: FontWeight.w800)),
                    StatusBadge.neutral('Hạng ${p.tierName}'),
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
                        style: appText(13.5, weight: FontWeight.w700, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            children: [
              RoundIconButton(
                icon: Icons.notifications_none,
                tooltip: 'Thông báo',
                size: 52,
                onTap: () => showAppSnack(context, 'Bạn có 1 thông báo mới từ MotoCare'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.leading, required this.label, this.big = false});
  final Widget leading;
  final String label;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: big ? 11 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Text(label, style: appText(big ? 16 : 13, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Nút tròn lớn bật/tắt nhận đơn.
class _OnlineToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final on = appState.isOnline;
    return Semantics(
      button: true,
      toggled: on,
      label: on ? 'Đang bật nhận đơn, chạm để tắt' : 'Đang tắt nhận đơn, chạm để bật',
      child: Material(
        color: on ? AppColors.ink : const Color(0xFF4B5563),
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => appState.setOnline(!on),
          child: SizedBox(
            width: 164,
            height: 164,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFF34D399) : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  on ? 'ĐANG BẬT' : 'ĐANG TẮT',
                  style: appText(21, weight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  on ? 'Chạm để tắt' : 'Chạm để bật',
                  style: appText(13.5, weight: FontWeight.w600, color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Expanded(
          child: Column(
            children: [
              Text(value, style: appText(26, weight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: appText(13.5, color: AppColors.textSub, height: 1.3),
              ),
            ],
          ),
        );
    Widget divider() => Container(width: 1, height: 52, color: AppColors.border);

    return IntrinsicHeight(
      child: Row(
        children: [
          stat('${appState.weekOrders}', 'Đơn hoàn thành\ntuần này'),
          divider(),
          stat(formatShortVnd(appState.weekIncome), 'Thu nhập\ntuần này'),
          divider(),
          stat(formatShortVnd(appState.weekWithdrawn), 'Đã rút\ntuần này'),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.count});
  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: 6),
          Text('$rating', style: appText(18, weight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text('đánh giá TB', style: appText(14, color: AppColors.textSub)),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.border,
          ),
          Text('$count', style: appText(18, weight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text('lượt đánh giá', style: appText(14, color: AppColors.textSub)),
        ],
      ),
    );
  }
}

/// Khối trạng thái ghép đơn tự động (không cho thợ tự chọn đơn).
class _MatchingBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final active = appState.activeOrder;
    final (icon, title, body) = active != null
        ? (
            Icons.two_wheeler,
            'Bạn đang xử lý đơn ${active.offer.code}',
            'Hoàn thành đơn hiện tại để tiếp tục nhận offer mới.',
          )
        : appState.isOnline
            ? (
                Icons.wifi_tethering,
                'Đang chờ đơn phù hợp',
                'MotoCare tự động ghép đơn gần bạn nhất, mỗi lần một offer. '
                    'Giữ ứng dụng mở để không bỏ lỡ thông báo.',
              )
            : (
                Icons.wifi_tethering_off,
                'Bạn đang tắt nhận đơn',
                'Chạm nút ĐANG TẮT phía trên để bật lại và nhận offer gần bạn.',
              );

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 28, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: appText(19, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: appText(15, color: AppColors.textSub, height: 1.45),
        ),
        if (active != null) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Tiếp tục đơn',
            height: 50,
            onPressed: () => openActiveOrder(context, active),
          ),
        ],
      ],
    );
  }
}

class _WeatherRow extends StatelessWidget {
  const _WeatherRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('${MockData.weatherTemp}°', style: appText(26, weight: FontWeight.w900)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MockData.weatherTitle, style: appText(16, weight: FontWeight.w700)),
              Text(MockData.weatherNote, style: appText(13.5, color: AppColors.textSub)),
            ],
          ),
        ),
        const Icon(Icons.wb_sunny_outlined, color: AppColors.textSub, size: 26),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard();

  @override
  Widget build(BuildContext context) {
    final p = appState.profile;
    return Row(
      children: [
        const IconCircle(icon: Icons.workspace_premium_outlined, size: 52),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hạng ${p.tierName} → Hạng ${p.nextTierName}',
                      style: appText(17, weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${p.tierOrders}/${p.nextTierTarget} đơn',
                    style: appText(14, weight: FontWeight.w700, color: AppColors.textSub),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: p.tierProgress,
                  minHeight: 7,
                  color: AppColors.ink,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Còn ${p.ordersToNextTier} đơn nữa trong 30 ngày để lên Hạng ${p.nextTierName}',
                style: appText(13.5, color: AppColors.textSub),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
