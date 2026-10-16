import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_common.dart';

class AdminReconciliationScreen extends ConsumerWidget {
  const AdminReconciliationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(adminClockProvider)();
    final range = AdminDateRange(DateTime(2000), DateTime(now.year + 1));

    return AdminPage(
      title: 'Thanh toán & đối soát',
      children: [
        AdminAsyncSection(
          value: ref.watch(adminSummaryProvider(range)),
          onRetry: () => ref.invalidate(adminSummaryProvider(range)),
          isEmpty: (summary) => summary.metrics.every((m) => m.value == 0),
          builder: (summary) {
            final money = summary.metrics.skip(9).toList();
            const labels = [
              'Khách chuyển',
              'Revo đang giữ',
              'Đã hoàn khách',
              'Đã quyết toán ví thợ',
              'Đang khóa chờ rút',
              'Đã rút',
            ];
            return AdminMetricGrid(
              metrics: List.generate(
                6,
                (i) => AdminMetric(labels[i], money[i].value, isMoney: true),
              ),
            );
          },
        ),
        const Text(
          'Tiền đang giữ = tổng thu − tổng hoàn − tổng cộng ví thợ. Số dư ví mở đầu sandbox được ghi riêng trong lịch sử ví.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in AdminMatchStatus.values)
              AdminStatusChip(status.label, color: _matchColor(status)),
          ],
        ),
        AdminAsyncSection(
          value: ref.watch(adminReconciliationProvider),
          onRetry: () => ref.invalidate(adminReconciliationProvider),
          isEmpty: (items) => items.isEmpty,
          builder: (items) => AdminRecordList(
            records: [
              for (final row in items)
                AdminRecord(
                  title: row.order.id,
                  fields: [
                    AdminField.text(
                      'Payment ID',
                      row.order.paymentId ?? 'Không có',
                    ),
                    AdminField.text(
                      'Tiền đơn',
                      adminMoney(
                        row.order.finalPrice ?? row.order.estimatedPrice,
                      ),
                    ),
                    AdminField.text(
                      'Tổng thu',
                      adminMoney(row.order.collected),
                    ),
                    AdminField.text(
                      'Tổng hoàn',
                      adminMoney(row.order.refunded),
                    ),
                    AdminField.text(
                      'Tổng cộng ví thợ',
                      adminMoney(row.order.credited),
                    ),
                    AdminField(
                      'Trạng thái',
                      AdminStatusChip(
                        row.status.label,
                        color: _matchColor(row.status),
                      ),
                    ),
                    AdminField.text('Lý do / Ghi chú', row.reason ?? '—'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  static Color _matchColor(AdminMatchStatus status) => switch (status) {
    AdminMatchStatus.matched => AdminTokens.success,
    AdminMatchStatus.pending => AdminTokens.warning,
    AdminMatchStatus.anomaly => AdminTokens.primaryRed,
    AdminMatchStatus.excluded => AdminTokens.neutral,
  };
}
