import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';
import '../models/admin_dashboard_models.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_dashboard_highlights.dart';
import '../widgets/admin_dashboard_queues.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _scrollController = ScrollController();
  int _selectedFilterIndex = 0;
  String _period = '7 ngày';
  AdminDateRange? _custom;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectFilter(int index) {
    setState(() => _selectedFilterIndex = index);
    _scrollController.jumpTo(0);
  }

  AdminDateRange get _range {
    if (_custom != null && _period == 'Tùy chọn') return _custom!;
    final now = ref.read(adminClockProvider)();
    final days = _period == 'Hôm nay' ? 1 : (_period == '30 ngày' ? 30 : 7);
    return AdminDateRange(
      DateTime(now.year, now.month, now.day - days + 1),
      DateTime(now.year, now.month, now.day + 1),
    );
  }

  Future<void> _changePeriod(String? value) async {
    if (value == null || value == _period) return;
    if (value == 'Tùy chọn') {
      final selected = await pickAdminDateRange(
        context,
        ref.read(adminClockProvider)(),
        initialRange: _range,
      );
      if (!mounted || selected == null) return;
      setState(() {
        _custom = selected;
        _period = value;
      });
    } else {
      setState(() => _period = value);
    }
  }

  void _invalidateDashboard(AdminDateRange range) {
    ref.invalidate(adminSummaryProvider(range));
    ref.invalidate(adminTimeseriesProvider(range));
    ref.invalidate(
      adminTimeseriesProvider(AdminDashboardHighlights.previousRange(range)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return RefreshIndicator(
      onRefresh: () async {
        _invalidateDashboard(range);
        ref.invalidate(adminOrdersProvider);
        ref.invalidate(adminRefundsProvider);
        ref.invalidate(adminDisputesProvider);
        ref.invalidate(adminWithdrawalsProvider);
        // Async sections own error/retry presentation, including refresh errors.
        try {
          await ref.read(adminDashboardHighlightsProvider(range).future);
        } catch (_) {
          // Keep the section's error state visible after the gesture finishes.
        }
      },
      child: SingleChildScrollView(
        key: const PageStorageKey('admin-health-dashboard'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AdminPageTitle(title: 'Tổng quan'),
                const SizedBox(height: 16),
                _DashboardFilters(
                  selectedIndex: _selectedFilterIndex,
                  onSelected: _selectFilter,
                ),
                const SizedBox(height: 16),
                if (_selectedFilterIndex != 4) ...[
                  _DashboardPeriodSelector(
                    period: _period,
                    range: range,
                    onPeriodChanged: _changePeriod,
                  ),
                  const SizedBox(height: 20),
                  AdminAsyncSection(
                    value: ref.watch(adminDashboardHighlightsProvider(range)),
                    onRetry: () => _invalidateDashboard(range),
                    isEmpty: (data) => data.isEmpty,
                    builder: (data) => AdminDashboardHighlightsView(
                      data: data,
                      period: _period == 'Tùy chọn' ? 'Đã chọn' : _period,
                      selectedFilterIndex: _selectedFilterIndex,
                    ),
                  ),
                ],
                if (_selectedFilterIndex == 1) ...[
                  const SizedBox(height: 16),
                  const AdminDashboardUrgentOrders(),
                ],
                if (_selectedFilterIndex == 4)
                  const AdminDashboardMoneyRequests(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardFilters extends StatelessWidget {
  const _DashboardFilters({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = [
    'Tất cả',
    'SOS & Đơn hàng',
    'Thợ & Khách hàng',
    'Doanh thu & Dòng tiền',
    'Yêu cầu chờ xử lý',
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey('admin-dashboard-filters'),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < _labels.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == _labels.length - 1 ? 0 : 8),
            child: ChoiceChip(
              key: ValueKey('admin-dashboard-filter-$i'),
              label: Text(_labels[i]),
              selected: selectedIndex == i,
              onSelected: (_) => onSelected(i),
              showCheckmark: false,
              selectedColor: AdminTokens.text,
              backgroundColor: AdminTokens.inactivePill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              labelStyle: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: selectedIndex == i
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: selectedIndex == i
                    ? Colors.white
                    : AdminTokens.inactivePillText,
              ),
            ),
          ),
      ],
    ),
  );
}

class _DashboardPeriodSelector extends StatelessWidget {
  const _DashboardPeriodSelector({
    required this.period,
    required this.range,
    required this.onPeriodChanged,
  });
  final String period;
  final AdminDateRange range;
  final ValueChanged<String?> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: [
      Text(
        adminRangeLabel(range),
        style: const TextStyle(fontSize: 11, color: AdminTokens.muted),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: AdminTheme.dashboardCardDecoration,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: period,
            isDense: true,
            borderRadius: AdminTheme.dashboardCardRadius,
            dropdownColor: AdminTokens.surface,
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AdminTokens.text,
            ),
            items: [
              for (final item in ['Hôm nay', '7 ngày', '30 ngày', 'Tùy chọn'])
                DropdownMenuItem(value: item, child: Text(item)),
            ],
            onChanged: onPeriodChanged,
          ),
        ),
      ),
    ],
  );
}
