import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import 'admin_dashboard_data.dart';
import 'admin_dashboard_highlights.dart';
import 'admin_dashboard_highlights_view.dart';
import 'admin_dashboard_queues.dart';
import 'admin_weather_card.dart';
import 'revo_admin_style.dart';

/// Admin dashboard (Tổng quan) in the REVO prototype look, wired to the real
/// backend (summary + timeseries + pending operations). Rendered inside
/// AdminShell, which supplies the bottom navigation.
class AdminRevoDashboardScreen extends ConsumerStatefulWidget {
  const AdminRevoDashboardScreen({super.key});

  @override
  ConsumerState<AdminRevoDashboardScreen> createState() =>
      _AdminRevoDashboardScreenState();
}

class _AdminRevoDashboardScreenState
    extends ConsumerState<AdminRevoDashboardScreen> {
  int _selectedFilterIndex = 0;
  String _period = '7 ngày';
  AdminDateRange? _custom;

  static const _filters = [
    'Tất cả',
    'SOS & Đơn hàng',
    'Thợ & Khách hàng',
    'Doanh thu & Dòng tiền',
    'Yêu cầu chờ xử lý',
  ];

  AdminDateRange get _range {
    if (_custom != null && _period == 'Tùy chọn') return _custom!;
    final now = DateTime.now();
    final days = _period == 'Hôm nay' ? 1 : (_period == '30 ngày' ? 30 : 7);
    return AdminDateRange(
      DateTime(now.year, now.month, now.day - days + 1),
      DateTime(now.year, now.month, now.day + 1),
    );
  }

  Future<void> _changePeriod(String? value) async {
    if (value == null || value == _period) return;
    if (value == 'Tùy chọn') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 1),
        lastDate: now,
        initialDateRange: DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        ),
      );
      if (!mounted || picked == null) return;
      setState(() {
        _custom = AdminDateRange(
          picked.start,
          DateTime(picked.end.year, picked.end.month, picked.end.day + 1),
        );
        _period = value;
      });
    } else {
      setState(() => _period = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHighlights = _selectedFilterIndex != 4;
    final highlights = showHighlights
        ? ref.watch(adminDashboardHighlightsProvider(_range))
        : null;
    return ColoredBox(
      color: AdminTokens.background,
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardHighlightsProvider(_range));
          ref.invalidate(adminUrgentOrdersProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopSection(),
                  const SizedBox(height: 4),
                  _FilterChips(
                    labels: _filters,
                    selectedIndex: _selectedFilterIndex,
                    onSelected: (i) => setState(() => _selectedFilterIndex = i),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (highlights != null)
                          highlights.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => _ErrorBox(
                              onRetry: () => ref.invalidate(
                                adminDashboardHighlightsProvider(_range),
                              ),
                            ),
                            data: (data) => AdminDashboardHighlightsView(
                              data: data,
                              period: _period,
                              onPeriodChanged: _changePeriod,
                              selectedFilterIndex: _selectedFilterIndex,
                            ),
                          ),
                        if (_selectedFilterIndex == 1) ...[
                          const SizedBox(height: 16),
                          const AdminDashboardUrgentOrders(),
                        ],
                        if (_selectedFilterIndex == 4)
                          const AdminDashboardMoneyRequests(),
                      ],
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
}

class _TopSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBFE1F6), Color(0xFFEAF4FC), Color(0xFFFFFFFF)],
        stops: [0, 0.6, 1],
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/admin/account'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AdminTokens.muted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Tổng quan',
                  textAlign: TextAlign.center,
                  style: revoFont(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Chưa có thông báo mới.')),
                    );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AdminTokens.text,
                      ),
                      Positioned(
                        top: 12,
                        right: 13,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AdminTokens.primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AdminWeatherCard(),
        ],
      ),
    ),
  );
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == i
                      ? const Color(0xFF14233B)
                      : AdminTokens.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selectedIndex == i
                        ? const Color(0xFF14233B)
                        : AdminTokens.border,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: revoFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selectedIndex == i
                        ? Colors.white
                        : AdminTokens.muted,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        const Icon(Icons.wifi_off_rounded, color: AdminTokens.muted, size: 40),
        const SizedBox(height: 12),
        Text(
          'Không tải được dữ liệu tổng quan.',
          textAlign: TextAlign.center,
          style: revoFont(fontSize: 13, color: AdminTokens.muted),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
