import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

/// A compact, stylised preview of the incident location on the order detail
/// screen. The real interactive map lives on the tracking screen, reached via
/// the "Xem bản đồ" action.
class OrderDetailsMapPreview extends StatelessWidget {
  const OrderDetailsMapPreview({
    super.key,
    required this.details,
    this.onTracking,
  });

  final OrderDetails details;
  final VoidCallback? onTracking;

  @override
  Widget build(BuildContext context) {
    final order = details.order;
    return Container(
      decoration: BoxDecoration(
        color: OrderDetailsTheme.primaryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OrderDetailsTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _StreetsPainter())),
            const Center(child: _IncidentPin()),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 14,
                      color: OrderDetailsTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: OrderDetailsTheme.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FilledButton.icon(
                key: const ValueKey('order-details-tracking'),
                onPressed: onTracking,
                style: FilledButton.styleFrom(
                  backgroundColor: OrderDetailsTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Xem bản đồ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentPin extends StatelessWidget {
  const _IncidentPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: OrderDetailsTheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: OrderDetailsTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: OrderDetailsTheme.text,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Vị trí sự cố',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 5),
        Offset(size.width, size.height * (i / 5 + .08)),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * i / 5, 0),
        Offset(size.width * (i / 5 - .08), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StreetsPainter oldDelegate) => false;
}
