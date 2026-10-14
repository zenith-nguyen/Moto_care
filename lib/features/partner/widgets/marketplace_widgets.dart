import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

class MarketplaceScaffold extends StatelessWidget {
  const MarketplaceScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomBar,
    this.onBack,
  });
  final String title;
  final Widget body;
  final Widget? bottomBar;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Theme(
    data: HomeTheme.light,
    child: Scaffold(
      backgroundColor: HomeColors.surface,
      appBar: AppBar(
        toolbarHeight:
            56 + (MediaQuery.textScalerOf(context).scale(20) / 20 - 1) * 44,
        leading: BackButton(onPressed: onBack),
        title: Text(
          title,
          maxLines: 2,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: body,
        ),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: HomeColors.surface,
                border: Border(top: BorderSide(color: HomeColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: bottomBar,
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}

class MarketplaceSection extends StatelessWidget {
  const MarketplaceSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: HomeColors.background, width: 8),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}

class VerifiedPartnerBadge extends StatelessWidget {
  const VerifiedPartnerBadge({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.verified_rounded, size: 14, color: HomeColors.red),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          'Đã xác thực MotoCare',
          style: TextStyle(
            color: HomeColors.red,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onChanged,
  });
  final int quantity;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        tooltip: 'Bớt',
        onPressed: quantity == 0 ? null : () => onChanged(quantity - 1),
        icon: const Icon(Icons.remove_circle_outline, color: HomeColors.red),
      ),
      Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
      IconButton(
        tooltip: 'Thêm',
        onPressed: quantity >= 9 ? null : () => onChanged(quantity + 1),
        icon: const Icon(Icons.add_circle, color: HomeColors.red),
      ),
    ],
  );
}
