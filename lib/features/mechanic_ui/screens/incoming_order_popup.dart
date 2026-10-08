import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common_widgets.dart';

/// Kết quả của popup nổ đơn.
enum IncomingOrderResult { accepted, rejected, timeout }

/// Mở popup "Nổ đơn khẩn cấp" đè lên Trang chủ (nền tối phía sau).
/// Trả về kết quả; hết 15 giây tự đóng với [IncomingOrderResult.timeout].
Future<IncomingOrderResult?> showIncomingOrderPopup(
  BuildContext context,
  OrderRequest order,
) {
  return showModalBottomSheet<IncomingOrderResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.op(0.68),
    builder: (_) => IncomingOrderPopup(order: order),
  );
}

class IncomingOrderPopup extends StatefulWidget {
  const IncomingOrderPopup({super.key, required this.order});
  final OrderRequest order;

  @override
  State<IncomingOrderPopup> createState() => _IncomingOrderPopupState();
}

class _IncomingOrderPopupState extends State<IncomingOrderPopup>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 15;

  late final AnimationController _countdown;
  bool _photoOpen = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _countdown =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: _totalSeconds),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _finish(IncomingOrderResult.timeout);
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  /// Đóng popup đúng 1 lần (nút bấm, nút Back hoặc hết giờ).
  void _finish(IncomingOrderResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    _countdown.stop();
    final navigator = Navigator.of(context);
    // Nếu đang xem ảnh toàn màn hình thì đóng ảnh trước, rồi mới đóng popup.
    if (_photoOpen) navigator.pop();
    navigator.pop(result);
  }

  Future<void> _openPhoto() async {
    _photoOpen = true;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng ảnh',
      barrierColor: Colors.black.op(0.92),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => _PhotoViewer(order: widget.order),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    _photoOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return PopScope(
      canPop: false,
      // Nút Back của Android = từ chối đơn
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(IncomingOrderResult.rejected);
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge + tiêu đề + vòng đếm ngược
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const UrgentBadge(),
                          const SizedBox(height: 12),
                          Text(
                            order.headline,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: appText(
                              19,
                              weight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CountdownRing(
                      controller: _countdown,
                      totalSeconds: _totalSeconds,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Địa điểm + khoảng cách
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${order.address} (Cách bạn ${formatKm(order.distanceKm)})',
                        style: appText(
                          14.5,
                          weight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ảnh hiện trường (bấm để phóng to)
                _PhotoThumbnail(onTap: _openPhoto),
                const SizedBox(height: 14),

                // Thu nhập nhận được
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thu nhập nhận được',
                        style: appText(13, color: AppColors.textSub),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatVnd(order.earning),
                        style: appText(
                          36,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Chiết khấu sàn: ${formatVnd(order.platformFee)}',
                        style: appText(
                          13,
                          color: AppColors.textSub,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2 nút hành động
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () =>
                              _finish(IncomingOrderResult.rejected),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textSub,
                            side: const BorderSide(color: AppColors.disabled),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            'TỪ CHỐI',
                            style: appText(
                              14,
                              weight: FontWeight.w700,
                              color: AppColors.textSub,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () =>
                              _finish(IncomingOrderResult.accepted),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            'CHẤP NHẬN ĐƠN',
                            style: appText(
                              16,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vòng đếm ngược 15s: CircularProgressIndicator đỏ + số giây ở giữa.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.controller, required this.totalSeconds});

  final AnimationController controller;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final remaining = math.max(
          0,
          math.min(
            totalSeconds,
            (totalSeconds * (1 - controller.value)).ceil(),
          ),
        );
        return Semantics(
          label: 'Còn $remaining giây để phản hồi',
          child: SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: 1 - controller.value,
                    strokeWidth: 6,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$remaining',
                      style: appText(24, weight: FontWeight.w800, height: 1),
                    ),
                    Text(
                      'giây',
                      style: appText(
                        10.5,
                        color: AppColors.textSub,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Xem ảnh hiện trường toàn màn hình',
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: 104,
              height: 76,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ScenePhoto(borderRadius: AppRadius.sm),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.op(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.zoom_out_map,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ảnh hiện trường',
                style: appText(14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Khách gửi lúc báo sự cố. Bấm vào ảnh để xem toàn màn hình.',
                style: appText(12.5, color: AppColors.textSub, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Xem ảnh toàn màn hình (zoom bằng 2 ngón tay).
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.order});
  final OrderRequest order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: const ScenePhoto(borderRadius: AppRadius.md),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 12,
              child: CircleIconButton(
                icon: Icons.close,
                tooltip: 'Đóng ảnh',
                background: Colors.white.op(0.16),
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Text(
                'Ảnh hiện trường — ${order.headline}',
                textAlign: TextAlign.center,
                style: appText(13.5, color: Colors.white.op(0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
