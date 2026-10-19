import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_finance_models.dart';
import 'admin_common.dart';

enum AdminBalanceFilter {
  collected('Khách chuyển', 'Tổng tiền khách chuyển', Icons.download_rounded),
  held('Revo giữ', 'Tiền Revo đang giữ', Icons.account_balance_wallet_rounded),
  credited('Ví thợ', 'Đã quyết toán ví thợ', Icons.build_rounded);

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
  // Representative navy sampled from the lower face of the supplied card.
  static const navy = Color(0xFF253370);
  static const background = Color(0xFFF1F4F8);
  static const actionBackground = Color(0xFFE7EEF0);
  static const caption = Color(0xFF8E8E93);
  static const escrowAsset = 'assets/images/Thẻ_visa_admin.png';
  static const surface = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(24)),
    boxShadow: [
      BoxShadow(color: Color(0x050D1B35), blurRadius: 18, offset: Offset(0, 4)),
    ],
  );

  static TextStyle text(
    double size,
    FontWeight weight,
    Color color, {
    double letterSpacing = -0.2,
  }) => GoogleFonts.montserrat(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.5,
    letterSpacing: letterSpacing,
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
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selected.title,
            key: const ValueKey('admin-finance-balance-title'),
            textAlign: TextAlign.center,
            style: AdminFinanceStyle.text(
              13,
              FontWeight.w700,
              AdminTokens.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
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
                        34,
                        FontWeight.w800,
                        AdminFinanceStyle.navy,
                      ).copyWith(height: 1.2, letterSpacing: -0.5),
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
              color: AdminFinanceStyle.actionBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final filter in AdminBalanceFilter.values) ...[
                      if (filter.index > 0) const SizedBox(width: 8),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: selected == filter
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x17253370),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ]
                                  : const [
                                      BoxShadow(
                                        color: Color(0x040D1B35),
                                        blurRadius: 4,
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: () => onSelected(filter),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 80,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          filter.icon,
                                          size: 24,
                                          color: selected == filter
                                              ? AdminFinanceStyle.navy
                                              : AdminFinanceStyle.navy
                                                    .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          filter.label,
                                          textAlign: TextAlign.center,
                                          style: AdminFinanceStyle.text(
                                            11,
                                            selected == filter
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            selected == filter
                                                ? AdminFinanceStyle.navy
                                                : AdminTokens.muted,
                                            letterSpacing: -0.3,
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
                      ),
                    ],
                  ],
                ),
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
  Widget build(BuildContext context) => Container(
    decoration: AdminFinanceStyle.surface,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tài khoản đối soát hệ thống',
          style: AdminFinanceStyle.text(
            14,
            FontWeight.w700,
            AdminTokens.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 464 / 293,
            child: FittedBox(
              fit: BoxFit.cover,
              // Crop only the margins of the supplied square asset.
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
                        semanticLabel: 'Thẻ tài khoản đối soát hệ thống Admin',
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
              Icons.verified_user_rounded,
              size: 18,
              color: AdminFinanceStyle.navy,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ví escrow hệ thống Admin',
                style: AdminFinanceStyle.text(
                  11,
                  FontWeight.w400,
                  AdminTokens.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
