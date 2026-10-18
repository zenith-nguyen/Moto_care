import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/admin_common.dart';
import '../../widgets/admin_finance_cards.dart';
import '../../widgets/admin_invoice_activity.dart';

class AdminFinanceScreen extends ConsumerStatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  ConsumerState<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends ConsumerState<AdminFinanceScreen> {
  AdminBalanceFilter _selected = AdminBalanceFilter.collected;

  void _retry() {
    final now = ref.read(adminClockProvider)();
    ref.invalidate(
      adminSummaryProvider(
        AdminDateRange(DateTime(2000), DateTime(now.year + 1)),
      ),
    );
    ref.invalidate(adminReconciliationProvider);
    ref.invalidate(adminFinanceProvider);
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF8F9FA),
    child: AdminPage(
      title: 'Thanh toán & đối soát',
      children: [
        AdminAsyncSection(
          value: ref.watch(adminFinanceProvider),
          onRetry: _retry,
          isEmpty: (data) => data.isEmpty,
          builder: (data) => LayoutBuilder(
            builder: (context, constraints) {
              final balance = AdminBalanceCard(
                data: data,
                selected: _selected,
                onSelected: (value) => setState(() => _selected = value),
              );
              final wide =
                  constraints.maxWidth >= 900 &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: balance),
                        const SizedBox(width: 24),
                        const Expanded(child: AdminEscrowCard()),
                      ],
                    )
                  else ...[
                    balance,
                    const SizedBox(height: 24),
                    const AdminEscrowCard(),
                  ],
                  const SizedBox(height: 24),
                  AdminInvoiceActivity(invoices: data.invoices),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}
