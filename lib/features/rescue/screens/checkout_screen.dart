import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/theme/home_theme.dart';
import '../../partner/widgets/marketplace_widgets.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/marketplace_booking.dart';
import '../providers/checkout_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.booking});
  final MarketplaceBooking? booking;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _draftKey = Object();
  CheckoutKey get _key => (_draftKey, widget.booking);
  CheckoutController get _controller =>
      ref.read(checkoutProvider(_key).notifier);

  @override
  void initState() {
    super.initState();
    final draft = ref.read(checkoutProvider(_key));
    _address.text = draft.location?.address ?? '';
    if (draft.location == null && widget.booking != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.locate());
      });
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _choosePayment() async {
    final result = await showModalBottomSheet<RescuePaymentMethod>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            for (final method in RescuePaymentMethod.values)
              ListTile(
                key: ValueKey('payment-${method.value}'),
                title: Text(method.label),
                subtitle: method == RescuePaymentMethod.cash
                    ? const Text('Thanh toán sau khi hoàn tất dịch vụ')
                    : const Text(
                        'Lưu lựa chọn trong phiên dùng thử; ví chưa kết nối',
                      ),
                leading: Icon(
                  method == ref.read(checkoutProvider(_key)).payment
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: HomeColors.red,
                ),
                onTap: () => Navigator.pop(context, method),
              ),
          ],
        ),
      ),
    );
    if (mounted && result != null) _controller.selectPayment(result);
  }

  void _placeOrder(int travelFee) {
    final order = _controller.placeOrder(travelFee);
    if (order != null) {
      context.pushReplacement(
        '/order-tracking?id=${Uri.encodeComponent(order.id)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final draft = ref.watch(checkoutProvider(_key));
    final quote = ref.watch(checkoutQuoteProvider(_key));
    final shop = quote.shop;
    ref.listen(checkoutProvider(_key), (previous, next) {
      if (previous?.location != next.location &&
          next.location != null &&
          _address.text.trim() != next.location!.address) {
        _address.text = next.location!.address;
      }
    });
    if (booking == null || shop == null) {
      return MarketplaceScaffold(
        title: 'Tóm tắt đơn hàng',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chưa có gói dịch vụ. Hãy chọn tiệm và dịch vụ trước.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.go('/partners?service=Tất%20cả%20dịch%20vụ'),
                  child: const Text('Chọn dịch vụ'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final vehicle = ref.watch(defaultVehicleProvider);
    final vehicles = ref.watch(vehicleProvider);
    final activeOrders = ref.watch(activityProvider).activeOrders;
    final distance = quote.distance;
    final travelFee = quote.travelFee;
    final total = quote.total;
    final canOrder = quote.canOrder;
    return MarketplaceScaffold(
      title: 'Tóm tắt đơn hàng',
      body: ListView(
        key: const ValueKey('checkout-scroll'),
        children: [
          MarketplaceSection(
            title: shop.station.name,
            children: [
              Text(
                'Cách bạn ≈ ${distance.toStringAsFixed(1)} km',
                style: const TextStyle(color: HomeColors.secondary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chế độ trải nghiệm: chưa điều phối thợ hoặc thu tiền.',
                style: TextStyle(color: HomeColors.secondary, fontSize: 12),
              ),
              if (!quote.validBooking)
                const Text(
                  'Tiệm hoặc gói dịch vụ không còn khả dụng. Hãy quay lại chọn gói.',
                  style: TextStyle(color: HomeColors.red),
                ),
            ],
          ),
          MarketplaceSection(
            title: 'Dịch vụ đã chọn',
            children: [
              for (final item in booking.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.build_circle_outlined,
                        color: HomeColors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Số lượng: ${item.quantity}  •  ${formatOrderPrice(item.unitPrice)} / dịch vụ',
                              style: const TextStyle(
                                color: HomeColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatOrderPrice(item.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          MarketplaceSection(
            title: 'Vị trí sự cố của bạn',
            children: [
              TextField(
                key: const ValueKey('checkout-address'),
                controller: _address,
                minLines: 1,
                maxLines: 3,
                maxLength: 240,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ sự cố',
                  prefixIcon: Icon(Icons.location_on, color: HomeColors.red),
                ),
                onChanged: _controller.editAddress,
              ),
              if (draft.location?.hasCoordinates ?? false)
                Text(
                  'GPS: ${draft.location!.latitude!.toStringAsFixed(6)}, ${draft.location!.longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: HomeColors.secondary,
                    fontSize: 12,
                  ),
                ),
              if (draft.locationError != null)
                Text(
                  draft.locationError!,
                  style: const TextStyle(color: HomeColors.red),
                ),
              TextButton.icon(
                onPressed: draft.loadingLocation ? null : _controller.locate,
                icon: const Icon(Icons.my_location, color: HomeColors.red),
                label: Text(
                  draft.loadingLocation
                      ? 'Đang lấy vị trí...'
                      : 'Lấy vị trí GPS hiện tại',
                ),
              ),
              TextField(
                key: const ValueKey('checkout-note'),
                controller: _note,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú cho thợ',
                  hintText: 'Mốc dễ tìm, tình trạng xe...',
                ),
                onChanged: _controller.editNote,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('checkout-vehicle-${vehicle?.id}'),
                initialValue: vehicle?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Xe cần cứu hộ',
                  prefixIcon: Icon(Icons.two_wheeler, color: HomeColors.red),
                ),
                items: [
                  for (final saved in vehicles)
                    DropdownMenuItem(
                      value: saved.id,
                      child: Text(
                        '${saved.name} (${saved.licensePlate})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) {
                    ref.read(vehicleProvider.notifier).setDefault(id);
                  }
                },
              ),
              if (vehicles.isEmpty)
                TextButton(
                  onPressed: () => context.push('/xe-cua-toi'),
                  child: const Text('Thêm xe của tôi'),
                ),
            ],
          ),
          MarketplaceSection(
            title: 'Thông tin thanh toán',
            children: [
              ListTile(
                key: const ValueKey('checkout-payment'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: HomeColors.red,
                ),
                title: Text(draft.payment.label),
                subtitle: const Text('Phương thức thanh toán'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _choosePayment,
              ),
            ],
          ),
          MarketplaceSection(
            title: 'Chi tiết giá',
            children: [
              _PriceLine('Tổng tạm tính', booking.subtotal),
              _PriceLine('Phí di chuyển/cứu hộ', travelFee),
              const Divider(height: 28),
              _PriceLine('Tổng cộng', total, prominent: true),
              const SizedBox(height: 12),
              const Text(
                'Phí di chuyển được ước tính theo khoảng cách tham khảo.',
                style: TextStyle(color: HomeColors.secondary, fontSize: 12),
              ),
            ],
          ),
          if (activeOrders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bạn đang có đơn cứu hộ. Hãy hoàn tất hoặc hủy đơn trước khi đặt mới.',
                    style: TextStyle(color: HomeColors.red),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      '/chi-tiet-don-hang?id=${Uri.encodeComponent(activeOrders.first.id)}',
                    ),
                    child: const Text('Xem đơn đang diễn ra'),
                  ),
                ],
              ),
            ),
          if (draft.error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                draft.error!,
                style: const TextStyle(color: HomeColors.red),
              ),
            ),
        ],
      ),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                formatOrderPrice(total),
                key: const ValueKey('checkout-total'),
                style: const TextStyle(
                  color: HomeColors.red,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('marketplace-place-order'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: canOrder ? () => _placeOrder(travelFee) : null,
            child: Text(
              draft.submitting ? 'ĐANG ĐẶT ĐƠN...' : 'ĐẶT ĐƠN CỨU HỘ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.label, this.price, {this.prominent = false});
  final String label;
  final int price;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: prominent ? 18 : 15,
            fontWeight: prominent ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
        Text(
          formatOrderPrice(price),
          style: TextStyle(
            color: prominent ? HomeColors.red : HomeColors.text,
            fontSize: prominent ? 22 : 15,
            fontWeight: prominent ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
