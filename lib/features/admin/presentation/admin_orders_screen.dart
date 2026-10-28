import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../orders/domain/order_status.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_operation_models.dart';
import '../revo/revo_admin_style.dart';
import 'admin_formatters.dart';

/// Admin rescue-orders list, wired to the real AdminOperationsController
/// (GET /admin/orders). Presentation re-skin to the REVO prototype: in-page
/// header, search + status filter + date-range filter, and rich order cards.
///
/// All filtering is CLIENT-SIDE over the already-loaded order list. No API,
/// controller, repository or model changes. Only fields that exist on
/// [AdminRecentOrder] are rendered. The list carries no payment-status field,
/// so the prototype's payment dropdown is intentionally omitted rather than
/// fabricating a financial state.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final TextEditingController _search = TextEditingController();
  String _searchTerm = '';
  OrderStatus? _status;
  DateTimeRange? _range;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _hasFilters =>
      _searchTerm.trim().isNotEmpty || _status != null || _range != null;

  void _resetFilters() {
    _search.clear();
    setState(() {
      _searchTerm = '';
      _status = null;
      _range = null;
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
    );
    if (!mounted || picked == null) return;
    setState(() => _range = picked);
  }

  List<AdminRecentOrder> _applyFilters(List<AdminRecentOrder> orders) {
    final term = _searchTerm.trim().toLowerCase();
    final range = _range;
    DateTime? start;
    DateTime? end;
    if (range != null) {
      start = DateTime(range.start.year, range.start.month, range.start.day);
      end = DateTime(range.end.year, range.end.month, range.end.day);
    }
    return orders.where((order) {
      if (_status != null && order.status != _status) return false;
      if (start != null && end != null) {
        final local = order.createdAt.toLocal();
        final day = DateTime(local.year, local.month, local.day);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }
      if (term.isNotEmpty) {
        final haystack =
            '${order.code} ${order.customerId} ${order.providerId ?? ''}'
                .toLowerCase();
        if (!haystack.contains(term)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOperationsControllerProvider);
    return ColoredBox(
      color: _OrdersTheme.background,
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminOperationsControllerProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top + 12),
                    _Header(
                      onRefresh: () => ref
                          .read(adminOperationsControllerProvider.notifier)
                          .refresh(),
                    ),
                    const SizedBox(height: 20),
                    _Filters(
                      searchController: _search,
                      status: _status,
                      range: _range,
                      hasFilters: _hasFilters,
                      onSearch: (value) => setState(() => _searchTerm = value),
                      onStatus: (value) => setState(() => _status = value),
                      onDateRange: _pickRange,
                      onReset: _resetFilters,
                    ),
                    const SizedBox(height: 20),
                    state.when(
                      loading: () => const _Loading(),
                      error: (error, _) => _ErrorState(
                        message: '$error',
                        onRetry: () =>
                            ref.invalidate(adminOperationsControllerProvider),
                      ),
                      data: (data) {
                        final orders = data.recentOrders;
                        if (orders.isEmpty) {
                          return const _Empty(
                            message: 'Chưa có đơn cứu hộ nào.',
                          );
                        }
                        final filtered = _applyFilters(orders);
                        if (filtered.isEmpty) {
                          return const _Empty(
                            message: 'Không tìm thấy đơn phù hợp bộ lọc.',
                          );
                        }
                        return _OrderCardList(orders: filtered);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Quản lý đơn cứu hộ',
          style: revoFont(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _OrdersTheme.heading,
            letterSpacing: -0.3,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Tải lại',
        onPressed: onRefresh,
        color: _OrdersTheme.secondary,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.status,
    required this.range,
    required this.hasFilters,
    required this.onSearch,
    required this.onStatus,
    required this.onDateRange,
    required this.onReset,
  });

  final TextEditingController searchController;
  final OrderStatus? status;
  final DateTimeRange? range;
  final bool hasFilters;
  final ValueChanged<String> onSearch;
  final ValueChanged<OrderStatus?> onStatus;
  final VoidCallback onDateRange;
  final VoidCallback onReset;

  String _rangeLabel(DateTimeRange value) =>
      '${_dayMonth(value.start)} – ${_dayMonth(value.end)}';

  @override
  Widget build(BuildContext context) => Container(
    decoration: _OrdersTheme.cardDecoration,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearch,
          style: _OrdersTheme.input,
          decoration: InputDecoration(
            hintText: 'Tìm mã đơn, mã khách hàng hoặc mã thợ',
            hintStyle: _OrdersTheme.input.copyWith(color: _OrdersTheme.muted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 20,
              color: _OrdersTheme.muted,
            ),
            filled: true,
            fillColor: _OrdersTheme.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _OrdersTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _OrdersTheme.brand),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _StatusDropdown(value: status, onChanged: onStatus),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(range == null ? 'Khoảng ngày' : _rangeLabel(range!)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _OrdersTheme.text,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                side: const BorderSide(color: _OrdersTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: _OrdersTheme.action,
              ),
              onPressed: onDateRange,
            ),
            TextButton(
              onPressed: hasFilters ? onReset : null,
              style: TextButton.styleFrom(
                foregroundColor: _OrdersTheme.brand,
                minimumSize: const Size(0, 44),
                textStyle: _OrdersTheme.action,
              ),
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final OrderStatus? value;
  final ValueChanged<OrderStatus?> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: _OrdersTheme.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: DropdownButtonFormField<OrderStatus>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
      iconEnabledColor: _OrdersTheme.secondary,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      style: _OrdersTheme.selection,
      decoration: InputDecoration(
        labelText: 'TRẠNG THÁI ĐƠN',
        labelStyle: _OrdersTheme.filterLabel,
        // InputDecorator scales a floating label to 75%; render it at 10 px.
        floatingLabelStyle: _OrdersTheme.filterLabel.copyWith(
          fontSize: 10 / .75,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      items: [
        const DropdownMenuItem(child: Text('Tất cả đơn')),
        for (final status in OrderStatus.values)
          DropdownMenuItem(
            value: status,
            child: Text(adminOrderStatusLabel(status)),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}

class _OrderCardList extends StatelessWidget {
  const _OrderCardList({required this.orders});

  final List<AdminRecentOrder> orders;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 900 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.2
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 14,
        children: [
          for (final order in orders)
            SizedBox(
              width: width,
              child: _OrderCard(
                key: ValueKey('admin-order-card-${order.id}'),
                order: order,
              ),
            ),
        ],
      );
    },
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({super.key, required this.order});

  final AdminRecentOrder order;

  void _open(BuildContext context) => context.push('/admin/orders/${order.id}');

  @override
  Widget build(BuildContext context) {
    final hasProvider = order.providerId != null;
    final hasFinal = order.finalPrice != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Container(
          decoration: _OrdersTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(order.code, style: _OrdersTheme.title),
                  _StatusBadge(order.status),
                ],
              ),
              const Divider(height: 25, color: _OrdersTheme.divider),
              _FieldRow(
                left: _OrderField('Khách hàng', 'Khách #${order.customerId}'),
                right: _OrderField(
                  'Thợ phân công',
                  hasProvider ? 'Thợ #${order.providerId}' : 'Chưa phân công',
                  valueStyle: hasProvider
                      ? null
                      : _OrdersTheme.value.copyWith(
                          color: _OrdersTheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              _FieldRow(
                left: _OrderField(
                  'Giá cuối',
                  hasFinal ? formatAdminMoney(order.finalPrice!) : 'Chưa chốt',
                  note: 'Tạm tính: ${formatAdminMoney(order.estimatedPrice)}',
                  valueStyle: _OrdersTheme.value.copyWith(
                    color: hasFinal
                        ? _OrdersTheme.heading
                        : _OrdersTheme.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                right: _OrderField(
                  'Thời gian tạo',
                  formatAdminDateTime(order.createdAt),
                  valueStyle: _OrdersTheme.input.copyWith(
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _open(context),
                  style: TextButton.styleFrom(
                    backgroundColor: _OrdersTheme.background,
                    foregroundColor: _OrdersTheme.text,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: _OrdersTheme.action,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Chi tiết'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
          210) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 12), right],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      );
    },
  );
}

class _OrderField extends StatelessWidget {
  const _OrderField(this.label, this.value, {this.note, this.valueStyle});

  final String label;
  final String value;
  final String? note;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _OrdersTheme.label),
      const SizedBox(height: 2),
      Text(value, style: valueStyle ?? _OrdersTheme.value),
      if (note != null) ...[
        const SizedBox(height: 2),
        Text(note!, style: _OrdersTheme.label.copyWith(fontSize: 10)),
      ],
    ],
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        adminOrderStatusLabel(status),
        style: _OrdersTheme.action.copyWith(color: foreground),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải danh sách đơn…'),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _OrdersTheme.cardDecoration,
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 16),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 44, color: _OrdersTheme.muted),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: _OrdersTheme.value.copyWith(color: _OrdersTheme.secondary),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    decoration: _OrdersTheme.cardDecoration,
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, color: _OrdersTheme.muted, size: 40),
        const SizedBox(height: 12),
        Text(
          'Không tải được danh sách đơn: $message',
          textAlign: TextAlign.center,
          style: _OrdersTheme.value.copyWith(color: _OrdersTheme.secondary),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

String _dayMonth(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}';

(Color, Color) _statusColors(OrderStatus status) => switch (status) {
  OrderStatus.completed ||
  OrderStatus.paid => (const Color(0xFFECFDF5), _OrdersTheme.success),
  OrderStatus.cancelled ||
  OrderStatus.refunded => (_OrdersTheme.divider, _OrdersTheme.secondary),
  OrderStatus.priceDisputed => (const Color(0xFFFEF2F2), _OrdersTheme.error),
  OrderStatus.awaitingPrepayment ||
  OrderStatus.pendingMatch ||
  OrderStatus.offered ||
  OrderStatus.awaitingPriceApproval ||
  OrderStatus.awaitingPayment ||
  OrderStatus.refundPending => (const Color(0xFFFFFBEB), _OrdersTheme.warning),
  _ => (const Color(0xFFEFF6FF), _OrdersTheme.brand),
};

/// Presentation tokens scoped to the admin order list, mirroring the REVO
/// prototype's order-directory styling. Montserrat comes from [revoFont]
/// (the app bundles Montserrat as a fontFamily), so no extra font dependency.
abstract final class _OrdersTheme {
  static const brand = AdminTokens.primaryBlue; // #317CBB
  static const background = Color(0xFFF8FAFC);
  static const heading = Color(0xFF0F172A);
  static const text = Color(0xFF1E293B);
  static const secondary = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFF1F5F9);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFF43F5E);

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: divider),
    boxShadow: const [
      BoxShadow(color: Color(0x1494A3B8), blurRadius: 18, offset: Offset(0, 4)),
    ],
  );

  static final title = revoFont(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: heading,
    letterSpacing: -0.3,
    height: 1.4,
  );
  static final label = revoFont(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: muted,
    height: 1.5,
  );
  static final value = revoFont(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.5,
  );
  static final action = value.copyWith(height: 1.4);
  static final input = revoFont(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: text,
    height: 1.5,
  );
  static final selection = value.copyWith(fontSize: 14);
  static final filterLabel = revoFont(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: muted,
    letterSpacing: 0.3,
    height: 1.5,
  );
}
