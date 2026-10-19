import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';
import '../theme/admin_theme.dart';

/// Health-style hierarchy: colored category, insight, divider, then data.
class AdminHealthCard extends StatelessWidget {
  const AdminHealthCard({
    super.key,
    required this.title,
    required this.color,
    required this.child,
    this.icon,
    this.onOpen,
    this.backgroundColor,
    this.titleStyle,
    this.trailing,
    this.actionColor = AdminTokens.muted,
  });

  final String title;
  final IconData? icon;
  final Color color;
  final Widget child;
  final VoidCallback? onOpen;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final Color actionColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: AdminTheme.dashboardCardDecoration.copyWith(
      color: backgroundColor,
    ),
    child: Material(
      color: backgroundColor ?? AdminTokens.card,
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
                      if (icon != null) ...[
                        Icon(icon, size: 22, color: color),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style:
                              titleStyle ??
                              GoogleFonts.montserrat(
                                color: color,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ] else if (onOpen != null)
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: actionColor,
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
