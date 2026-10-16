import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../theme/admin_order_theme.dart';

class AdminOrderSurface extends StatelessWidget {
  const AdminOrderSurface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
  });
  final Widget child;
  final Color color;
  final double padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: AdminOrderTheme.radius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: color,
      borderRadius: AdminOrderTheme.radius,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    ),
  );
}

class AdminOrderStatusBadge extends StatelessWidget {
  const AdminOrderStatusBadge(this.status, {super.key});
  final AdminOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      AdminOrderStatus.completed => (
        const Color(0xFFE8F5E9),
        AdminTokens.success,
      ),
      AdminOrderStatus.cancelled => (
        AdminTokens.inactivePill,
        AdminTokens.inactivePillText,
      ),
      AdminOrderStatus.searching => (
        const Color(0xFFFFF4DE),
        AdminTokens.warning,
      ),
      _ => (AdminTokens.activePill, AdminTokens.primaryBlue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: AdminOrderTheme.value.copyWith(fontSize: 12, color: foreground),
      ),
    );
  }
}

class AdminOrderIdentity extends StatelessWidget {
  const AdminOrderIdentity({super.key, required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: [
      Text(order.id, style: AdminOrderTheme.title),
      AdminOrderStatusBadge(order.status),
    ],
  );
}
