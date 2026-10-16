import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';

/// Six Admin destinations, including direct access to the account.
class AdminFloatingBottomNav extends StatelessWidget {
  const AdminFloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.requestIcon,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget requestIcon;

  static const labels = [
    'Tổng quan',
    'Đơn hàng',
    'Duyệt thợ',
    'Tài chính',
    'Xử lý yêu cầu',
    'Tài khoản',
  ];
  static const _icons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.verified_user_outlined,
    Icons.account_balance_outlined,
    Icons.assignment_outlined,
    Icons.manage_accounts_outlined,
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AdminTokens.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
          BoxShadow(color: Color(0x08000000), blurRadius: 4),
        ],
      ),
      child: Material(
        color: AdminTokens.surface,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: selectedIndex == i,
                      label: labels[i],
                      child: Tooltip(
                        message: labels[i],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onSelected(i),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: selectedIndex == i
                                  ? AdminTokens.activePill
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 10,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: 23,
                                    color: selectedIndex == i
                                        ? AdminTokens.primaryBlue
                                        : AdminTokens.muted,
                                  ),
                                  child: i == 4 ? requestIcon : Icon(_icons[i]),
                                ),
                                const SizedBox(height: 5),
                                ExcludeSemantics(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: MediaQuery.textScalerOf(
                                        context,
                                      ).scale(30),
                                    ),
                                    child: Text(
                                      i == 4 ? 'Xử lý\nyêu cầu' : labels[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: selectedIndex == i ? 12 : 11,
                                        fontWeight: selectedIndex == i
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        height: 1.25,
                                        color: selectedIndex == i
                                            ? AdminTokens.primaryBlue
                                            : AdminTokens.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
