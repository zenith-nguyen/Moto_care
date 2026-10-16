import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import 'admin_common.dart';

/// Offline coordinate preview; deliberately never requests native map access.
class AdminOrderMap extends StatelessWidget {
  const AdminOrderMap({super.key, required this.order});
  final AdminOrder order;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: const Color(0xFFEAF0F4),
          height: 240,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final customer = order.customerPosition;
              final provider = order.providerPosition;
              final minLat =
                  math.min(customer.$1, provider?.$1 ?? customer.$1) - .003;
              final maxLat =
                  math.max(customer.$1, provider?.$1 ?? customer.$1) + .003;
              final minLng =
                  math.min(customer.$2, provider?.$2 ?? customer.$2) - .003;
              final maxLng =
                  math.max(customer.$2, provider?.$2 ?? customer.$2) + .003;
              Offset project((double, double) p) => Offset(
                24 +
                    (constraints.maxWidth - 48) *
                        (p.$2 - minLng) /
                        (maxLng - minLng),
                24 + 190 * (1 - (p.$1 - minLat) / (maxLat - minLat)),
              );
              Widget pin((double, double) p, String label, Color color) {
                final point = project(p);
                return Positioned(
                  left: point.dx - 17,
                  top: point.dy - 34,
                  child: Semantics(
                    label: label,
                    child: Icon(Icons.location_on, color: color, size: 34),
                  ),
                );
              }

              return Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _RoadPainter()),
                  ),
                  pin(customer, 'Vị trí khách hàng', AdminTokens.primaryRed),
                  if (provider != null)
                    pin(
                      provider,
                      'Vị trí thợ gần nhất',
                      AdminTokens.primaryBlue,
                    ),
                  const Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: AdminStatusChip(
                      'Bản đồ minh họa • Sandbox',
                      color: AdminTokens.neutral,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text('Khách (đỏ): ${order.address}'),
      Text(
        '${order.customerPosition.$1.toStringAsFixed(5)}, ${order.customerPosition.$2.toStringAsFixed(5)}',
      ),
      const SizedBox(height: 8),
      if (order.providerPosition case final position?) ...[
        Text(
          'Thợ (xanh): ${position.$1.toStringAsFixed(5)}, ${position.$2.toStringAsFixed(5)}',
        ),
        Text(
          'Ghi nhận gần nhất: ${order.locationUpdatedAt == null ? 'Chưa ghi nhận' : adminDate(order.locationUpdatedAt!)}',
        ),
      ] else
        const Text('Chưa có vị trí thợ.'),
    ],
  );
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12;
    for (var i = 0; i < 6; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x + 55, size.height), road);
    }
    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 25), road);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => false;
}
