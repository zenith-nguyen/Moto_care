import 'package:flutter/material.dart';

import '../theme/order_tracking_theme.dart';

class OrderTrackingHeader extends StatelessWidget {
  const OrderTrackingHeader({super.key, required this.onBack, this.onDetails});
  final VoidCallback onBack;
  final VoidCallback? onDetails;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _HeaderButton(
            label: 'Quay lại',
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Theo dõi trực tiếp',
              textAlign: TextAlign.center,
              style: CustomerOrderTheme.text(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          onDetails == null
              ? const SizedBox(width: 44)
              : _HeaderButton(
                  label: 'Chi tiết đơn hàng',
                  icon: Icons.receipt_long_outlined,
                  onPressed: onDetails!,
                ),
        ],
      ),
    ),
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shadowColor: const Color(0x0A000000),
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    ),
  );
}
