import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ui.dart';

/// Card khách hàng trong các bước xử lý đơn: avatar chữ cái, tên, xe · biển số, nút hành động.
class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.actions = const [],
    this.shadow = true,
  });

  final String name;
  final String subtitle;
  final List<Widget> actions;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        AvatarCircle(initials: _initials, dark: false, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: appText(17, weight: FontWeight.w600, height: 1.2)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: appText(13, color: AppColors.textSub, height: 1.3),
              ),
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 8), a],
      ],
    );
    return shadow
        ? ShadowCard(padding: const EdgeInsets.fromLTRB(16, 14, 14, 14), child: row)
        : SurfaceCard(padding: const EdgeInsets.fromLTRB(16, 14, 14, 14), child: row);
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Dòng sự cố: icon tia sét + tên sự cố + (tuỳ chọn) giá bên phải.
class IssueRow extends StatelessWidget {
  const IssueRow({super.key, required this.issue, this.subtitle, this.trailing});

  final String issue;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const IconCircle(
          icon: Icons.bolt_outlined,
          size: 44,
          background: Colors.white,
          color: AppColors.ink,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(issue, style: appText(17, weight: FontWeight.w600)),
              if (subtitle != null)
                Text(subtitle!, style: appText(13, color: AppColors.textSub, height: 1.3)),
            ],
          ),
        ),
        if (trailing != null) Text(trailing!, style: appText(18, weight: FontWeight.w700)),
      ],
    );
  }
}
