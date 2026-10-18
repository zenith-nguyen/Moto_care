import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_finance_models.dart';
import 'admin_common.dart';

enum AdminBalanceFilter {
  collected('Khách chuyển', 'Tổng tiền khách chuyển', Icons.south_west_rounded),
  held('Revo giữ', 'Tiền Revo đang giữ', Icons.account_balance_wallet_outlined),
  credited('Ví thợ', 'Đã quyết toán ví thợ', Icons.build_outlined);

  const AdminBalanceFilter(this.label, this.title, this.icon);
  final String label;
  final String title;
  final IconData icon;

  int amount(AdminFinanceSnapshot data) => switch (this) {
    collected => data.collected,
    held => data.held,
    credited => data.credited,
  };
}

abstract final class AdminFinanceStyle {
  static const teal = Color(0xFF0D3B4C);
  static const caption = Color(0xFF8E8E93);
  static const escrowAsset = 'assets/images/Thẻ_visa_admin.png';
  static const surface = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(24)),
    boxShadow: [
      BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
  );

  static TextStyle text(double size, FontWeight weight, Color color) =>
      TextStyle(
        fontFamily: 'Montserrat',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );
}

class AdminBalanceCard extends StatelessWidget {
  const AdminBalanceCard({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelected,
  });

  final AdminFinanceSnapshot data;
  final AdminBalanceFilter selected;
  final ValueChanged<AdminBalanceFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final latest = data.latestTransactionAt;
    return Container(
      key: const ValueKey('admin-finance-balance-card'),
      decoration: AdminFinanceStyle.surface,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selected.title,
            key: const ValueKey('admin-finance-balance-title'),
            textAlign: TextAlign.center,
            style: AdminFinanceStyle.text(
              13,
              FontWeight.w500,
              AdminTokens.muted,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            label: '${selected.title}: ${adminMoney(selected.amount(data))}',
            child: ExcludeSemantics(
              child: AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  key: ValueKey((selected, selected.amount(data))),
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      adminMoney(selected.amount(data)),
                      style: AdminFinanceStyle.text(
                        30,
                        FontWeight.bold,
                        AdminFinanceStyle.teal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            latest == null
                ? 'Chưa có giao dịch'
                : 'Giao dịch gần nhất: ${DateFormat('dd/MM/yyyy • HH:mm').format(latest)}',
            textAlign: TextAlign.center,
            style: AdminFinanceStyle.text(
              11,
              FontWeight.w400,
              AdminFinanceStyle.caption,
            ),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final filter in AdminBalanceFilter.values) ...[
                    if (filter.index > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Semantics(
                        key: ValueKey('admin-finance-filter-${filter.name}'),
                        button: true,
                        selected: selected == filter,
                        label: filter.label,
                        onTap: () => onSelected(filter),
                        excludeSemantics: true,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: selected == filter
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: selected == filter
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0A0D3B4C),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => onSelected(filter),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 14,
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      filter.icon,
                                      size: 22,
                                      color: selected == filter
                                          ? AdminFinanceStyle.teal
                                          : AdminTokens.muted,
                                    ),
                                    const SizedBox(height: 7),
                                    Text(
                                      filter.label,
                                      textAlign: TextAlign.center,
                                      style: AdminFinanceStyle.text(
                                        11,
                                        FontWeight.w500,
                                        selected == filter
                                            ? AdminFinanceStyle.teal
                                            : AdminTokens.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminEscrowCard extends StatelessWidget {
  const AdminEscrowCard({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Tài khoản đối soát hệ thống',
        style: AdminFinanceStyle.text(15, FontWeight.bold, AdminTokens.text),
      ),
      const SizedBox(height: 14),
      Container(
        decoration: AdminFinanceStyle.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 464 / 293,
                child: FittedBox(
                  fit: BoxFit.cover,
                  // The supplied square image has margins around the card.
                  // Crop those margins at render time, preserving the asset.
                  child: SizedBox(
                    width: 464,
                    height: 293,
                    child: Stack(
                      children: [
                        Positioned(
                          left: -118,
                          top: -134,
                          width: 700,
                          height: 700,
                          child: Image.asset(
                            AdminFinanceStyle.escrowAsset,
                            semanticLabel:
                                'Thẻ tài khoản đối soát hệ thống Admin',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 17,
                  color: AdminFinanceStyle.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ví escrow hệ thống Admin',
                    style: AdminFinanceStyle.text(
                      11,
                      FontWeight.w500,
                      AdminTokens.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
