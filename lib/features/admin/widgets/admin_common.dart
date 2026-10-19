import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../theme/admin_typography.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import 'admin_date_range_picker_dialog.dart';
import 'admin_page_header.dart';

String adminMoney(int value) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
).format(value);
String adminDate(DateTime value) =>
    DateFormat('dd/MM/yyyy HH:mm').format(value);
String adminRangeLabel(AdminDateRange range) =>
    '${DateFormat('dd/MM').format(range.start)} – ${DateFormat('dd/MM').format(range.end.subtract(const Duration(days: 1)))}';

Future<AdminDateRange?> pickAdminDateRange(
  BuildContext context,
  DateTime now, {
  AdminDateRange? initialRange,
}) async {
  final firstDate = DateTime(now.year - 1, now.month, now.day);
  final lastDate = DateUtils.dateOnly(now);
  DateTime clamp(DateTime date) => date.isBefore(firstDate)
      ? firstDate
      : date.isAfter(lastDate)
      ? lastDate
      : DateUtils.dateOnly(date);
  final selected = await showDialog<DateTimeRange>(
    context: context,
    builder: (_) => AdminDateRangePickerDialog(
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: now,
      initialDateRange: initialRange == null
          ? null
          : DateTimeRange(
              start: clamp(initialRange.start),
              end: clamp(
                DateTime(
                  initialRange.end.year,
                  initialRange.end.month,
                  initialRange.end.day - 1,
                ),
              ),
            ),
    ),
  );
  return selected == null
      ? null
      : AdminDateRange(
          selected.start,
          DateTime(selected.end.year, selected.end.month, selected.end.day + 1),
        );
}

class AdminStateView extends StatelessWidget {
  const AdminStateView({
    super.key,
    required this.title,
    required this.icon,
    this.description,
    this.onRetry,
  });
  const AdminStateView.empty({super.key})
    : title = 'Không có dữ liệu',
      icon = Icons.inbox_outlined,
      description = 'Chưa có mục nào trong danh sách hoặc bộ lọc này.',
      onRetry = null;
  const AdminStateView.forbidden({super.key})
    : title = 'Bạn không có quyền truy cập khu vực này',
      icon = Icons.lock_outline,
      description = 'Vui lòng đăng nhập bằng tài khoản có quyền ADMIN.',
      onRetry = null;
  final String title;
  final IconData icon;
  final String? description;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminTokens.primaryBlue.withValues(alpha: .06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AdminTokens.muted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AdminTypography.cardTitle,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: AdminTypography.body,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại / Retry'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class AdminAsyncSection<T> extends ConsumerWidget {
  const AdminAsyncSection({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final bool Function(T)? isEmpty;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adminSessionProvider)?.isAdmin != true) {
      return const AdminStateView.forbidden();
    }
    return value.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu…'),
            ],
          ),
        ),
      ),
      error: (error, stack) => error is AdminException && error.forbidden
          ? const AdminStateView.forbidden()
          : AdminStateView(
              title: 'Không thể tải dữ liệu',
              icon: Icons.wifi_off_rounded,
              description: error is AdminException
                  ? error.message
                  : 'Lỗi kết nối. Vui lòng thử lại.',
              onRetry: onRetry,
            ),
      data: (data) => isEmpty?.call(data) == true
          ? const AdminStateView.empty()
          : builder(data),
    );
  }
}

class AdminPageTitle extends StatelessWidget {
  const AdminPageTitle({
    super.key,
    required this.title,
    this.showNotifications = false,
    this.centerTitle = false,
    this.fontSize = 22,
    this.leading,
  });

  final String title;
  final bool showNotifications;
  final bool centerTitle;
  final double fontSize;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => AdminPageHeader(
    title: title,
    showNotifications: showNotifications,
    centerTitle: centerTitle,
    fontSize: fontSize,
    leading: leading,
  );
}

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.header,
  });
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? header;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: PageStorageKey(title),
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
      16,
      MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
      24 + MediaQuery.paddingOf(context).bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header ?? AdminPageTitle(title: title),
        if (trailing != null) ...[const SizedBox(height: 16), trailing!],
        const SizedBox(height: 20),
        for (final child in children) ...[child, const SizedBox(height: 20)],
      ],
    ),
  );
}

class AdminCard extends StatelessWidget {
  const AdminCard({super.key, required this.child, this.title});
  final Widget child;
  final String? title;
  @override
  Widget build(BuildContext context) => Material(
    color: AdminTokens.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppCardLayout.radius),
      side: const BorderSide(color: AdminTokens.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppCardLayout.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: AdminTypography.cardTitle),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    ),
  );
}

Color adminReviewColor(AdminReviewStatus status) => switch (status) {
  AdminReviewStatus.pending => AdminTokens.warning,
  AdminReviewStatus.approved => AdminTokens.success,
  AdminReviewStatus.rejected => AdminTokens.primaryRed,
};
Color adminOrderColor(AdminOrderStatus status) => switch (status) {
  AdminOrderStatus.completed => AdminTokens.success,
  AdminOrderStatus.cancelled => AdminTokens.neutral,
  AdminOrderStatus.searching => AdminTokens.warning,
  _ => AdminTokens.primaryBlue,
};

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip(
    this.label, {
    super.key,
    this.color = AdminTokens.primaryBlue,
  });
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: AdminTypography.status.copyWith(color: color)),
  );
}

class AdminField {
  const AdminField(this.label, this.value);
  final String label;
  final Widget value;
  factory AdminField.text(String label, String value) =>
      AdminField(label, Text(value));
}

class AdminRecord {
  const AdminRecord({
    required this.title,
    required this.fields,
    this.actions = const [],
  });
  final String title;
  final List<AdminField> fields;
  final List<Widget> actions;
}

/// Tables on wide screens; labeled, wrapping cards on compact screens.
class AdminRecordList extends StatelessWidget {
  const AdminRecordList({super.key, required this.records});
  final List<AdminRecord> records;
  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const AdminStateView.empty();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.2) {
          return AdminCard(
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(
                    AdminTokens.background,
                  ),
                  dataRowMinHeight: 72,
                  dataRowMaxHeight: 120,
                  columns: [
                    const DataColumn(label: Text('Mã / Hồ sơ')),
                    for (final field in records.first.fields)
                      DataColumn(label: Text(field.label)),
                    if (records.any((r) => r.actions.isNotEmpty))
                      const DataColumn(label: Text('Thao tác')),
                  ],
                  rows: [
                    for (final record in records)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(record.title, style: AdminTypography.status),
                          ),
                          for (final field in record.fields)
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 200,
                                ),
                                child: field.value,
                              ),
                            ),
                          if (records.any((r) => r.actions.isNotEmpty))
                            DataCell(
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: record.actions,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final record in records)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminCard(
                  title: record.title,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 14,
                        children: [
                          for (final field in record.fields)
                            SizedBox(
                              width: constraints.maxWidth < 450
                                  ? constraints.maxWidth - 34
                                  : (constraints.maxWidth - 50) / 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.label,
                                    style: AdminTypography.label.copyWith(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  field.value,
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (record.actions.isNotEmpty) ...[
                        const Divider(height: 28),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: record.actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AdminMetricGrid extends StatelessWidget {
  const AdminMetricGrid({super.key, required this.metrics});
  final List<AdminMetric> metrics;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final minWidth = scale > 1.2 ? 250.0 : 205.0;
      final columns = (constraints.maxWidth / minWidth).floor().clamp(1, 5);
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < metrics.length; i++)
            SizedBox(
              width: width,
              child: AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      metrics[i].isMoney
                          ? Icons.account_balance_wallet_outlined
                          : Icons.insights_outlined,
                      color: metrics[i].isMoney
                          ? AdminTokens.primaryBlue
                          : AdminTokens.muted,
                      size: 22,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      metrics[i].isMoney
                          ? adminMoney(metrics[i].value)
                          : NumberFormat.decimalPattern('vi_VN')
                                .format(metrics[i].value),
                      style: AdminTypography.pageTitle.copyWith(fontSize: 23),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metrics[i].label,
                      style: AdminTypography.label.copyWith(
                        fontSize: 13,
                        color: const Color(0xA3000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
