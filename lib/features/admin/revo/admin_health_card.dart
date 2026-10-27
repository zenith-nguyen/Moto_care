import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';
import 'revo_admin_style.dart';

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
    this.borderColor,
    this.responsiveTrailing = false,
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
  final Color? borderColor;
  final bool responsiveTrailing;
  final Color actionColor;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: revoCardDecoration(color: backgroundColor, border: borderColor),
    child: Material(
      color: backgroundColor ?? AdminTokens.card,
      borderRadius: borderColor == null ? revoCardRadius : null,
      shape: borderColor == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: revoCardRadius,
              side: BorderSide(color: borderColor!),
            ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trailingBelowTitle =
                responsiveTrailing &&
                constraints.maxWidth <
                    480 * MediaQuery.textScalerOf(context).scale(1);
            return Column(
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
                                  revoFont(
                                    color: color,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                          ),
                          if (trailing != null && !trailingBelowTitle) ...[
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
                if (trailing != null && trailingBelowTitle) ...[
                  Align(alignment: Alignment.centerRight, child: trailing!),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            );
          },
        ),
      ),
    ),
  );
}
