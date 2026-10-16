import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_common.dart';
import '../widgets/admin_order_card.dart';
import '../widgets/admin_order_common.dart';
import '../widgets/admin_page_header.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  late final TextEditingController _search;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(adminOrderFilterProvider).search,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _update({
    String? search,
    AdminOrderStatus? status,
    bool setStatus = false,
    AdminPaymentStatus? payment,
    bool setPayment = false,
    AdminDateRange? range,
    bool setRange = false,
  }) {
    final current = ref.read(adminOrderFilterProvider);
    ref
        .read(adminOrderFilterProvider.notifier)
        .update(
          AdminOrderFilter(
            search: search ?? current.search,
            status: setStatus ? status : current.status,
            payment: setPayment ? payment : current.payment,
            range: setRange ? range : current.range,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminOrderFilterProvider);
    return AdminPage(
      title: 'Quản lý đơn cứu hộ',
      header: const AdminPageHeader(title: 'Quản lý đơn cứu hộ', fontSize: 20),
      children: [
        AdminOrderSurface(
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (value) => _update(search: value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Tìm mã đơn, khách hàng hoặc thợ',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<AdminOrderStatus>(
                      key: ValueKey(filter.status),
                      initialValue: filter.status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái đơn',
                      ),
                      items: [
                        const DropdownMenuItem(child: Text('Tất cả đơn')),
                        for (final status in AdminOrderStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                      ],
                      onChanged: (value) =>
                          _update(status: value, setStatus: true),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<AdminPaymentStatus>(
                      key: ValueKey(filter.payment),
                      initialValue: filter.payment,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Thanh toán',
                      ),
                      items: [
                        const DropdownMenuItem(
                          child: Text('Tất cả thanh toán'),
                        ),
                        for (final status in AdminPaymentStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                      ],
                      onChanged: (value) =>
                          _update(payment: value, setPayment: true),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      filter.range == null
                          ? 'Khoảng ngày'
                          : adminRangeLabel(filter.range!),
                    ),
                    onPressed: () async {
                      final range = await pickAdminDateRange(
                        context,
                        ref.read(adminClockProvider)(),
                        initialRange: filter.range,
                      );
                      if (mounted && range != null) {
                        _update(range: range, setRange: true);
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      _search.clear();
                      ref
                          .read(adminOrderFilterProvider.notifier)
                          .update(const AdminOrderFilter());
                    },
                    child: const Text('Xóa bộ lọc'),
                  ),
                ],
              ),
            ],
          ),
        ),
        AdminAsyncSection(
          value: ref.watch(adminFilteredOrdersProvider),
          onRetry: () => ref.invalidate(adminOrdersProvider),
          isEmpty: (items) => items.isEmpty,
          builder: (orders) => AdminOrderCardList(orders: orders),
        ),
      ],
    );
  }
}
