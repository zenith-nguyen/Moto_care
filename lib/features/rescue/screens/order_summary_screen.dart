import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/providers/home_discovery_provider.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/marketplace_booking.dart';
import '../providers/checkout_provider.dart';
import '../theme/order_summary_theme.dart';
import '../widgets/order_summary_sections.dart';

class OrderSummaryScreen extends ConsumerStatefulWidget {
  const OrderSummaryScreen({super.key, this.booking});
  final MarketplaceBooking? booking;

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  final _address = TextEditingController();
  final _addressFocus = FocusNode();
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
    _addressFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _choosePayment() async {
    final selected = ref.read(checkoutProvider(_key)).payment;
    final result = await showModalBottomSheet<RescuePaymentMethod>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Theme(
        data: OrderSummaryTheme.light,
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const OrderSummaryHeading('Phương thức thanh toán'),
              for (final method in [
                RescuePaymentMethod.cash,
                RescuePaymentMethod.momo,
                RescuePaymentMethod.vnpay,
              ])
                ListTile(
                  key: ValueKey('payment-${method.value}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(orderPaymentLabel(method)),
                  subtitle: Text(
                    method == RescuePaymentMethod.cash
                        ? 'Thanh toán sau khi hoàn tất dịch vụ'
                        : 'Lưu phương thức cho đơn cứu hộ',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    method == selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: OrderSummaryColors.red,
                  ),
                  onTap: () => Navigator.pop(context, method),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) _controller.selectPayment(result);
  }

  void _placeOrder(int travelFee) {
    FocusManager.instance.primaryFocus?.unfocus();
    final order = _controller.placeOrder(travelFee);
    if (order != null) {
      context.pushReplacement(
        '/order-tracking?id=${Uri.encodeComponent(order.id)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutProvider(_key));
    final quote = ref.watch(checkoutQuoteProvider(_key));
    ref.listen(checkoutProvider(_key), (previous, next) {
      final address = next.location?.address ?? '';
      if (_address.text != address) _address.text = address;
    });
    final booking = widget.booking;
    final shop = quote.shop;
    final vehicle = ref.watch(defaultVehicleProvider);
    final vehicles = ref.watch(vehicleProvider);
    final activeOrders = ref.watch(activityProvider).activeOrders;
    final photo = shop == null
        ? null
        : ref.watch(homeStationDetailsProvider)[shop.id]?.imageAsset;
    final scale = MediaQuery.textScalerOf(context).scale(20) / 20;

    return Theme(
      data: OrderSummaryTheme.light,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 56 + (scale - 1) * 44,
          leading: BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/partners'),
          ),
          title: const Text(
            'Tóm tắt đơn hàng',
            maxLines: 2,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: booking == null || shop == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text(
                        'Chưa có gói dịch vụ. Hãy chọn tiệm và dịch vụ trước.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/partners'),
                        child: const Text('Chọn tiệm cứu hộ'),
                      ),
                    ],
                  )
                : ListView(
                    key: const ValueKey('checkout-scroll'),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      OrderMechanicCard(
                        name: shop.station.name,
                        distance: quote.distance,
                        imageAsset: photo,
                      ),
                      const SizedBox(height: 16),
                      OrderAccidentLocationCard(
                        addressController: _address,
                        addressFocus: _addressFocus,
                        location: draft.location,
                        loading: draft.loadingLocation,
                        error: draft.locationError,
                        onChanged: _controller.editAddress,
                        onLocate: () => unawaited(_controller.locate()),
                      ),
                      const SizedBox(height: 20),
                      OrderPriceBreakdown(booking: booking, quote: quote),
                      const SizedBox(height: 20),
                      OrderPaymentCard(
                        payment: draft.payment,
                        onChoose: _choosePayment,
                      ),
                      const SizedBox(height: 20),
                      OrderSummaryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const OrderSummaryHeading('Xe cần cứu hộ'),
                            DropdownButtonFormField<String>(
                              key: ValueKey('checkout-vehicle-${vehicle?.id}'),
                              initialValue: vehicle?.id,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              items: [
                                for (final saved in vehicles)
                                  DropdownMenuItem(
                                    value: saved.id,
                                    child: Text(
                                      '${saved.name} • ${saved.licensePlate}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (id) {
                                if (id != null) {
                                  ref
                                      .read(vehicleProvider.notifier)
                                      .setDefault(id);
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
                      ),
                      const SizedBox(height: 20),
                      const OrderSummaryHeading('Ghi chú cho thợ'),
                      TextField(
                        key: const ValueKey('checkout-note'),
                        controller: _note,
                        maxLength: 500,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Mô tả thêm tình trạng xe (VD: Xe SH bị thủng bánh sau)...',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: OrderSummaryColors.muted,
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: OrderSummaryColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: OrderSummaryColors.border,
                            ),
                          ),
                        ),
                        onChanged: _controller.editNote,
                      ),
                      if (!quote.validBooking)
                        const Text(
                          'Giỏ dịch vụ đã thay đổi hoặc tiệm đang đóng cửa. Hãy quay lại chọn dịch vụ.',
                        ),
                      if (activeOrders.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Bạn đang có đơn cứu hộ. Hoàn tất hoặc hủy đơn trước khi đặt mới.',
                        ),
                        TextButton(
                          onPressed: () => context.push(
                            '/order-details?id=${Uri.encodeComponent(activeOrders.first.id)}',
                          ),
                          child: const Text('Xem đơn đang diễn ra'),
                        ),
                      ],
                      if (draft.error != null)
                        Text(
                          draft.error!,
                          style: const TextStyle(color: OrderSummaryColors.red),
                        ),
                    ],
                  ),
          ),
        ),
        bottomNavigationBar: booking == null || shop == null
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                const Text(
                                  'Tổng thanh toán',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  formatOrderPrice(quote.total),
                                  key: const ValueKey('checkout-total'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: OrderSummaryColors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              key: const ValueKey('marketplace-place-order'),
                              style: FilledButton.styleFrom(
                                backgroundColor: OrderSummaryColors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: quote.canOrder
                                  ? () => _placeOrder(quote.travelFee)
                                  : null,
                              child: Text(
                                draft.submitting
                                    ? 'ĐANG ĐẶT ĐƠN...'
                                    : 'XÁC NHẬN ĐẶT ĐƠN CỨU HỘ',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
