import 'package:flutter/material.dart';

import '../models/order_details.dart';
import '../theme/order_details_theme.dart';

class MechanicContactCard extends StatelessWidget {
  const MechanicContactCard({
    super.key,
    required this.details,
    required this.onChat,
    required this.onCall,
  });
  final OrderDetails details;
  final VoidCallback? onChat;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: OrderDetailsTheme.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 315 ||
            MediaQuery.textScalerOf(context).scale(13) > 17;
        final buttons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ContactButton(
              id: 'chat',
              tooltip: 'Nhắn tin cho thợ',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: onChat,
            ),
            const SizedBox(width: 8),
            _ContactButton(
              id: 'call',
              tooltip: 'Gọi điện cho thợ',
              icon: Icons.phone_outlined,
              onPressed: onCall,
            ),
          ],
        );
        final info = Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: OrderDetailsTheme.text,
              child: details.mechanicInitials.isEmpty
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                    )
                  : Text(
                      details.mechanicInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.mechanicName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    details.mechanicPlate,
                    style: const TextStyle(
                      color: OrderDetailsTheme.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact) ...[const SizedBox(width: 8), buttons],
          ],
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  info,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: buttons),
                ],
              )
            : info;
      },
    ),
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.id,
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });
  final String id;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: ValueKey('order-details-$id'),
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: OrderDetailsTheme.red,
      disabledForegroundColor: OrderDetailsTheme.muted,
      minimumSize: const Size(44, 44),
      side: const BorderSide(color: OrderDetailsTheme.line),
      shape: const CircleBorder(),
    ),
    icon: Icon(icon, size: 20),
  );
}
