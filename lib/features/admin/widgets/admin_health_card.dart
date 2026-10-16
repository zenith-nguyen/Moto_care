import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';
import '../theme/admin_theme.dart';

/// Health-style hierarchy: colored category, insight, divider, then data.
class AdminHealthCard extends StatelessWidget {
  const AdminHealthCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.onOpen,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: AdminTheme.dashboardCardDecoration,
    child: Material(
      color: AdminTokens.card,
      borderRadius: AdminTheme.dashboardCardRadius,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (onOpen != null)
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: AdminTokens.muted,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}
