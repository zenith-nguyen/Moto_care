import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../orders/domain/order_status.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_operation_models.dart';
import '../presentation/admin_formatters.dart';
import 'revo_admin_style.dart';

/// Order detail fetched on demand from the real backend.
final adminOrderDetailProvider = FutureProvider.autoDispose
    .family<AdminOrderDetail, int>((ref, id) async {
      return ref.watch(adminRepositoryProvider).getOrderDetail(id);
    });

/// A coarse payment label derived from the real order status (the recent-orders
/// list does not carry a separate payment record).
String _paymentLabel(OrderStatus status) => switch (status) {
  OrderStatus.completed || OrderStatus.paid => 'Đã quyết toán',
  OrderStatus.awaitingPayment => 'Chờ quyết toán',
  OrderStatus.awaitingPrepayment => 'Chờ thanh toán',
  OrderStatus.refunded => 'Đã hoàn tiền',
  OrderStatus.refundPending => 'Chờ hoàn tiền',
  OrderStatus.cancelled => 'Đã hủy',
  _ => 'Chưa thanh toán',
};

Color _statusColor(OrderStatus status) => switch (status) {
  OrderStatus.completed => AdminTokens.success,
  OrderStatus.cancelled => AdminTokens.neutral,
  OrderStatus.pendingMatch ||
  OrderStatus.awaitingPrepayment => AdminTokens.warning,
  OrderStatus.refunded || OrderStatus.refundPending => AdminTokens.primaryRed,
  _ => AdminTokens.primaryBlue,
};

// ---------------------------------------------------------------------------
// LIST
// ---------------------------------------------------------------------------

class RevoAdminOrdersScreen extends ConsumerStatefulWidget {
  const RevoAdminOrdersScreen({super.key});

  @override
  ConsumerState<RevoAdminOrdersScreen> createState() =>
      _RevoAdminOrdersScreenState();
}

class _RevoAdminOrdersScreenState extends ConsumerState<RevoAdminOrdersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  OrderStatus? _status;
  String? _payment;
  DateTimeRange? _range;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(AdminRecentOrder o) {
    if (_status != null && o.status != _status) return false;
    if (_payment != null && _paymentLabel(o.status) != _payment) return false;
    if (_range != null) {
      final day = DateTime(
        o.createdAt.year,
        o.createdAt.month,
        o.createdAt.day,
      );
      if (day.isBefore(_range!.start) || day.isAfter(_range!.end)) return false;
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      final hay = '${o.code} ${o.customerId} ${o.providerId ?? ''}'
          .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    return true;
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _searchController.clear();
      _status = null;
      _payment = null;
      _range = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOperationsControllerProvider);
    return ColoredBox(
      color: AdminTokens.background,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 14,
              16,
              4,
            ),
            child: Text(
              'Quản lý đơn cứu hộ',
              textAlign: TextAlign.center,
              style: revoFont(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AdminTokens.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Retry(
                message: 'Không tải được danh sách đơn.',
                onRetry: () =>
                    ref.invalidate(adminOperationsControllerProvider),
              ),
              data: (data) {
                final all = data.recentOrders;
                final orders = all.where(_matches).toList(growable: false);
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(adminOperationsControllerProvider.notifier)
                      .refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      _FilterCard(
                        searchController: _searchController,
                        status: _status,
                        payment: _payment,
                        onSearch: (v) => setState(() => _search = v),
                        onStatus: (v) => setState(() => _status = v),
                        onPayment: (v) => setState(() => _payment = v),
                        onPickRange: _pickRange,
                        onClear: _clearFilters,
                      ),
                      const SizedBox(height: 16),
                      if (orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              all.isEmpty
                                  ? 'Chưa có đơn nào.'
                                  : 'Không có đơn khớp bộ lọc.',
                              style: revoFont(
                                fontSize: 13,
                                color: AdminTokens.muted,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final order in orders) ...[
                          _OrderCard(order: order),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(
        () => _range = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        ),
      );
    }
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.searchController,
    required this.status,
    required this.payment,
    required this.onSearch,
    required this.onStatus,
    required this.onPayment,
    required this.onPickRange,
    required this.onClear,
  });

  final TextEditingController searchController;
  final OrderStatus? status;
  final String? payment;
  final ValueChanged<String> onSearch;
  final ValueChanged<OrderStatus?> onStatus;
  final ValueChanged<String?> onPayment;
  final VoidCallback onPickRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const payments = [
      'Đã quyết toán',
      'Chờ quyết toán',
      'Chờ thanh toán',
      'Đã hoàn tiền',
      'Chờ hoàn tiền',
      'Chưa thanh toán',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: revoCardDecoration(color: AdminTokens.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearch,
            style: revoFont(fontSize: 13, color: AdminTokens.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Tìm mã đơn, khách hàng hoặc thợ',
              hintStyle: revoFont(fontSize: 13, color: AdminTokens.muted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AdminTokens.muted,
              ),
              filled: true,
              fillColor: AdminTokens.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<OrderStatus?>(
            label: 'TRẠNG THÁI ĐƠN',
            value: status,
            display: (s) => s == null ? 'Tất cả đơn' : adminOrderStatusLabel(s),
            items: <OrderStatus?>[null, ...OrderStatus.values],
            onChanged: onStatus,
          ),
          const SizedBox(height: 12),
          _LabeledDropdown<String?>(
            label: 'THANH TOÁN',
            value: payment,
            display: (p) => p ?? 'Tất cả thanh toán',
            items: <String?>[null, ...payments],
            onChanged: onPayment,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPickRange,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: const Text('Khoảng ngày'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTokens.text,
                  side: const BorderSide(color: AdminTokens.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                child: Text(
                  'Xóa bộ lọc',
                  style: revoFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminTokens.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.display,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final String Function(T) display;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AdminTokens.card,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: revoFont(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AdminTokens.muted,
            letterSpacing: 0.2,
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            isDense: true,
            icon: const Icon(Icons.expand_more_rounded, size: 20),
            style: revoFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AdminTokens.text,
            ),
            items: [
              for (final item in items)
                DropdownMenuItem<T>(value: item, child: Text(display(item))),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final AdminRecentOrder order;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: revoCardDecoration(color: AdminTokens.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.code,
                  style: revoFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  adminOrderStatusLabel(order.status),
                  style: revoFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 26, color: AdminTokens.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardField(
                  label: 'Khách hàng',
                  value: 'Khách #${order.customerId}',
                ),
              ),
              Expanded(
                child: _CardField(
                  label: 'Thợ phân công',
                  value: order.providerId == null
                      ? 'Chưa phân công'
                      : 'Thợ #${order.providerId}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardField(
                  label: 'Giá cuối',
                  value: formatAdminMoney(
                    order.finalPrice ?? order.estimatedPrice,
                  ),
                  valueColor: AdminTokens.text,
                  sub: 'Tạm tính: ${formatAdminMoney(order.estimatedPrice)}',
                ),
              ),
              Expanded(
                child: _CardField(
                  label: 'Thanh toán',
                  value: _paymentLabel(order.status),
                  valueColor: _statusColor(order.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CardField(
            label: 'Thời gian tạo',
            value: formatAdminDateTime(order.createdAt),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/admin/orders/${order.id}'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Chi tiết'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminTokens.text,
                side: const BorderSide(color: AdminTokens.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.value,
    this.valueColor,
    this.sub,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: revoFont(fontSize: 12, color: AdminTokens.muted)),
      const SizedBox(height: 4),
      Text(
        value,
        style: revoFont(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: valueColor ?? AdminTokens.text,
          letterSpacing: -0.2,
        ),
      ),
      if (sub != null) ...[
        const SizedBox(height: 2),
        Text(sub!, style: revoFont(fontSize: 11, color: AdminTokens.muted)),
      ],
    ],
  );
}

// ---------------------------------------------------------------------------
// DETAIL
// ---------------------------------------------------------------------------

class RevoAdminOrderDetailScreen extends ConsumerWidget {
  const RevoAdminOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminOrderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: AdminTokens.background,
      appBar: AppBar(
        backgroundColor: AdminTokens.background,
        foregroundColor: AdminTokens.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Chi tiết đơn',
          style: revoFont(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AdminTokens.text,
          ),
        ),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Retry(
          message: 'Không tải được chi tiết đơn.',
          onRetry: () => ref.invalidate(adminOrderDetailProvider(orderId)),
        ),
        data: (order) => _DetailBody(order: order),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.order});

  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AdminTokens.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AdminTokens.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã đơn hàng:',
                    style: revoFont(fontSize: 11, color: AdminTokens.muted),
                  ),
                  Text(
                    order.code,
                    style: revoFont(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AdminTokens.text,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                adminOrderStatusLabel(order.status),
                style: revoFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _OrderStepper(status: order.status),
        const SizedBox(height: 20),
        _Section(
          title: 'Thông tin chi tiết',
          child: Column(
            children: [
              _KvRow(label: 'Khách hàng', value: order.customer?.name ?? '—'),
              _KvRow(
                label: 'Địa chỉ cứu hộ',
                value: order.customer?.address ?? '—',
              ),
              _KvRow(
                label: 'Số điện thoại',
                value: order.customer?.phone ?? '—',
              ),
              _KvRow(label: 'Loại sự cố', value: order.incidentType ?? '—'),
              _KvRow(
                label: 'Giá dịch vụ',
                value: formatAdminMoney(
                  order.finalPrice ?? order.estimatedPrice,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Thông tin Thợ cứu hộ',
          child: order.provider == null
              ? Text(
                  'Chưa phân công thợ.',
                  style: revoFont(fontSize: 13, color: AdminTokens.muted),
                )
              : Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: AdminTokens.card,
                      child: Icon(
                        Icons.person_rounded,
                        color: AdminTokens.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.provider?.name ?? 'Thợ',
                            style: revoFont(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AdminTokens.text,
                            ),
                          ),
                          if (order.provider?.phone != null)
                            Text(
                              order.provider!.phone!,
                              style: revoFont(
                                fontSize: 13,
                                color: AdminTokens.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Chi tiết giá',
          child: Column(
            children: [
              _KvRow(
                label: 'Tạm tính',
                value: formatAdminMoney(order.estimatedPrice),
              ),
              _KvRow(
                label: 'Phụ phí',
                value: formatAdminMoney(order.extraCost),
              ),
              _KvRow(
                label: 'Giảm giá',
                value: formatAdminMoney(order.discountAmount),
              ),
              if (order.finalPrice != null)
                _KvRow(
                  label: 'Giá cuối',
                  value: formatAdminMoney(order.finalPrice!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Thời gian',
          child: _KvRow(
            label: 'Tạo lúc',
            value: formatAdminDateTime(order.createdAt),
          ),
        ),
      ],
    );
  }
}

class _OrderStepper extends StatelessWidget {
  const _OrderStepper({required this.status});

  final OrderStatus status;

  int get _completed {
    switch (status) {
      case OrderStatus.awaitingPrepayment:
      case OrderStatus.pendingMatch:
      case OrderStatus.offered:
        return 1;
      case OrderStatus.accepted:
        return 2;
      case OrderStatus.arrived:
      case OrderStatus.inProgress:
      case OrderStatus.awaitingPriceApproval:
      case OrderStatus.priceDisputed:
      case OrderStatus.awaitingPayment:
        return 3;
      case OrderStatus.paid:
      case OrderStatus.completed:
      case OrderStatus.refundPending:
      case OrderStatus.refunded:
        return 4;
      case OrderStatus.cancelled:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Đã tạo', 'Thợ nhận', 'Bắt đầu', 'Hoàn thành'];
    const pending = Color(0xFFD1D1D6);
    final completed = _completed;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 26,
                color: i < completed ? AdminTokens.text : pending,
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i + 1 < completed ? AdminTokens.text : pending,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: revoFont(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AdminTokens.text,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: revoCardDecoration(color: AdminTokens.card),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: revoFont(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AdminTokens.text,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: revoFont(fontSize: 13, color: AdminTokens.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: revoFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AdminTokens.text,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AdminTokens.muted,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: revoFont(fontSize: 13, color: AdminTokens.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
