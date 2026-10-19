import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

enum AppStatusKind { offline, gpsOff, expired, loading, empty }

class AppStatusView extends StatelessWidget {
  const AppStatusView(
      {super.key,
      required this.kind,
      this.onAction,
      this.compact = false,
      this.message});
  final AppStatusKind kind;
  final VoidCallback? onAction;
  final bool compact;
  final String? message;
  static const _content = {
    AppStatusKind.offline: (
      Icons.wifi_off_rounded,
      'Mất kết nối mạng',
      'Vui lòng kiểm tra kết nối và thử lại.',
      'Thử lại',
      AppColors.danger
    ),
    AppStatusKind.gpsOff: (
      Icons.location_off_outlined,
      'GPS đang tắt',
      'Bật định vị để tiếp tục nhận đơn gần bạn.',
      'Bật định vị',
      AppColors.danger
    ),
    AppStatusKind.expired: (
      Icons.event_busy_outlined,
      'Đơn đã hết hạn',
      'Đơn này đã hết thời gian xử lý.',
      'Quay lại',
      AppColors.danger
    ),
    AppStatusKind.loading: (
      Icons.timelapse_outlined,
      'Đang xử lý',
      'Vui lòng đợi trong giây lát…',
      '',
      AppColors.primary
    ),
    AppStatusKind.empty: (
      Icons.inbox_outlined,
      'Không có dữ liệu',
      'Chưa có đơn hàng nào trong danh sách.',
      'Về trang chủ',
      AppColors.primary
    ),
  };
  @override
  Widget build(BuildContext context) {
    final c = _content[kind]!;
    final icon = Icon(c.$1, size: compact ? 19 : 32, color: c.$5);
    if (compact) {
      final card = SurfaceCard(
          color: Colors.white,
          radius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.$5.withValues(alpha: .7))),
                child: icon),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(c.$2, style: appText(12, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(message ?? c.$3,
                      style: appText(11, color: AppColors.textSub)),
                ])),
            if (onAction != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textSub),
          ]));
      return onAction == null
          ? card
          : InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(12),
              child: card);
    }
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: c.$5.withValues(alpha: .08),
                      shape: BoxShape.circle),
                  child: Center(child: icon)),
              const SizedBox(height: 24),
              Text(c.$2, style: appText(17, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(message ?? c.$3,
                  textAlign: TextAlign.center,
                  style: appText(12, color: AppColors.textSub)),
              if (onAction != null && c.$4.isNotEmpty) ...[
                const SizedBox(height: 28),
                PrimaryButton(label: c.$4, onPressed: onAction),
              ],
            ])));
  }
}
