import 'package:flutter/material.dart';

import '../models/rescue_order.dart';

/// A compact navy summary of the customer's active order, shown on the home
/// screen. Ported from the REVO prototype; tapping opens tracking/details.
class ActiveOrderTrackingCard extends StatelessWidget {
  const ActiveOrderTrackingCard({
    super.key,
    required this.order,
    required this.onDetails,
  });

  final RescueOrder order;
  final VoidCallback onDetails;

  static const _navy = Color(0xFF0F172A);
  static const _amber = Color(0xFFF59E0B);
  static const _muted = Color(0xFFCBD5E1);
  static const _steps = [
    'Đã nhận đơn',
    'Thợ đang đến',
    'Đang sửa chữa',
    'Hoàn thành',
  ];

  int get _currentStep => switch (order.status) {
    RescueOrderStatus.pending || RescueOrderStatus.cancelled => 0,
    RescueOrderStatus.enRoute => 1,
    RescueOrderStatus.repairing => 2,
    RescueOrderStatus.completed => 3,
  };

  String get _status => switch (order.status) {
    RescueOrderStatus.pending =>
      order.hasProvider ? 'ĐÃ NHẬN ĐƠN' : 'ĐÃ GỬI YÊU CẦU',
    RescueOrderStatus.enRoute => 'THỢ ĐANG ĐẾN',
    RescueOrderStatus.repairing => 'ĐANG SỬA CHỮA',
    RescueOrderStatus.completed => 'ĐÃ HOÀN THÀNH',
    RescueOrderStatus.cancelled => 'ĐÃ HỦY',
  };

  String get _eta => switch (order.status) {
    RescueOrderStatus.pending =>
      order.hasProvider ? 'Đang cập nhật ETA' : 'Đang tìm thợ',
    RescueOrderStatus.enRoute => switch (order.etaMinutes) {
      null => 'Đang cập nhật ETA',
      0 => 'Thợ sắp đến',
      final minutes => 'Đến trong: $minutes phút',
    },
    RescueOrderStatus.repairing => 'Thợ đang sửa chữa',
    RescueOrderStatus.completed => 'Đã hoàn thành',
    RescueOrderStatus.cancelled => 'Đơn đã hủy',
  };

  TextStyle _text(double size, FontWeight weight, Color color) => TextStyle(
    fontFamily: 'Montserrat',
    fontSize: size,
    fontWeight: weight,
    letterSpacing: -0.3,
    height: 1.4,
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    final code = order.orderCode.startsWith('#')
        ? order.orderCode
        : '#${order.orderCode}';
    return Container(
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_rounded,
                              size: 19,
                              color: _muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _text(13, FontWeight.w600, _muted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _status,
                          style: _text(16, FontWeight.w700, Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    tooltip: 'Theo dõi đơn ${order.orderCode}',
                    onPressed: onDetails,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _navy,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 23),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 24,
                child: CustomPaint(
                  painter: _TrackingProgressPainter(
                    currentStep: _currentStep,
                    rightToLeft:
                        Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    Expanded(
                      child: Semantics(
                        label: 'Bước ${i + 1} trên 4',
                        selected: i == _currentStep,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            _steps[i],
                            textAlign: TextAlign.center,
                            style: _text(
                              11,
                              i == _currentStep
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              i <= _currentStep ? Colors.white : _muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Color(0x29394B65)),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final location = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _muted,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vị trí cứu hộ',
                              style: _text(11, FontWeight.w400, _muted),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              order.locationAddress.trim().isEmpty
                                  ? 'Đang cập nhật vị trí'
                                  : order.locationAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _text(12, FontWeight.w500, Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final eta = Text(
                    _eta,
                    textAlign: TextAlign.end,
                    style: _text(12, FontWeight.w600, _amber),
                  );
                  if (constraints.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(12) > 14.4) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        location,
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerRight, child: eta),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: location),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Align(alignment: Alignment.topRight, child: eta),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingProgressPainter extends CustomPainter {
  const _TrackingProgressPainter({
    required this.currentStep,
    required this.rightToLeft,
  });

  final int currentStep;
  final bool rightToLeft;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final segment = size.width / 4;
    final y = size.height / 2;
    double center(int step) => segment * (step + 0.5);
    if (rightToLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    for (var i = 0; i < 3; i++) {
      final start = center(i) + 11;
      final end = center(i + 1) - 11;
      paint.color = i < currentStep
          ? ActiveOrderTrackingCard._amber
          : const Color(0xFF475569);
      if (i < currentStep) {
        canvas.drawLine(Offset(start, y), Offset(end, y), paint);
      } else {
        for (var x = start; x < end; x += 9) {
          canvas.drawLine(
            Offset(x, y),
            Offset((x + 3).clamp(start, end), y),
            paint,
          );
        }
      }
    }
    for (var i = 0; i < 4; i++) {
      final point = Offset(center(i), y);
      paint
        ..color = i <= currentStep
            ? ActiveOrderTrackingCard._amber
            : const Color(0xFF64748B)
        ..style = i == currentStep ? PaintingStyle.stroke : PaintingStyle.fill;
      canvas.drawCircle(point, i == currentStep ? 8 : 4, paint);
      if (i == currentStep) {
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(point, 3, paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrackingProgressPainter oldDelegate) =>
      currentStep != oldDelegate.currentStep ||
      rightToLeft != oldDelegate.rightToLeft;
}
