import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/widgets/order_summary.dart';
import '../../home/models/rescue_location.dart';
import '../../home/providers/home_provider.dart';
import '../../home/theme/home_theme.dart';
import '../../location/services/device_location_service.dart';
import '../../partner/providers/partner_provider.dart';
import '../../partner/widgets/marketplace_widgets.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../../voucher/providers/voucher_provider.dart';
import '../models/marketplace_booking.dart';
import '../widgets/checkout_voucher_sheet.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.booking});
  final MarketplaceBooking? booking;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _address = TextEditingController();
  final _note = TextEditingController();
  RescueLocation? _location;
  RescuePaymentMethod _payment = RescuePaymentMethod.cash;
  String? _voucherCode;
  String? _error;
  String? _locationError;
  bool _loadingLocation = false;
  bool _submitting = false;
  int _addressRevision = 0;

  @override
  void initState() {
    super.initState();
    _location = ref.read(rescueLocationProvider);
    _address.text = _location?.address ?? '';
    if (_location == null && widget.booking != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_locate());
      });
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_loadingLocation) return;
    final revision = _addressRevision;
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final result = await ref
          .read(deviceLocationProvider)()
          .timeout(const Duration(seconds: 24));
      if (!mounted || revision != _addressRevision) return;
      if (!ref.read(rescueLocationProvider.notifier).confirmLocation(result)) {
        throw const LocationLookupException(
          'Vị trí không hợp lệ. Hãy nhập địa chỉ sự cố.',
        );
      }
      setState(() {
        _location = result;
        _address.text = result.address;
      });
    } on Exception catch (error) {
      if (mounted && revision == _addressRevision) {
        setState(
          () => _locationError = error is LocationLookupException
              ? error.message
              : 'Chưa lấy được GPS. Thử lại hoặc nhập địa chỉ sự cố.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
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
                  method == _payment
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
    if (mounted && result != null) setState(() => _payment = result);
  }

  Future<void> _chooseVoucher(MarketplaceBooking booking) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CheckoutVoucherSheet(booking: booking),
    );
    if (mounted && code != null) {
      setState(() => _voucherCode = code == 'none' ? null : code);
    }
  }

  void _placeOrder(MarketplaceBooking booking, int travelFee) {
    if (_submitting) return;
    final currentShops = ref
        .read(partnerShopsProvider)
        .where((shop) => shop.id == booking.partnerId);
    final shop = currentShops.isEmpty ? null : currentShops.first;
    final vehicle = ref.read(defaultVehicleProvider);
    final location = _location;
    final offers = ref
        .read(voucherProvider)
        .where((offer) => offer.code == _voucherCode);
    final voucher = offers.isEmpty ? null : offers.first;
    final discount = booking.discountFor(
      voucher,
      ref.read(voucherClockProvider)(),
    );
    if (_voucherCode != null && discount == 0) {
      setState(() => _error = 'Voucher không còn hợp lệ. Vui lòng chọn lại.');
      return;
    }
    if (shop == null ||
        vehicle == null ||
        location == null ||
        !booking.isValidFor(shop) ||
        !ref.read(rescueLocationProvider.notifier).confirmLocation(location)) {
      setState(() => _error = 'Kiểm tra lại tiệm, xe và địa chỉ sự cố.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    if (MarketplaceBooking.travelFee(
          stationDistanceKm(shop.station, location),
        ) !=
        travelFee) {
      setState(() {
        _submitting = false;
        _error = 'Phí di chuyển đã thay đổi. Vui lòng kiểm tra tổng tiền và đặt lại.';
      });
      return;
    }
    _addressRevision++;
    try {
      final order = ref
          .read(activityProvider.notifier)
          .createOrder(
            serviceType: booking.items.first.serviceType,
            userVehicle: '${vehicle.name} (${vehicle.licensePlate})',
            locationAddress: location.address,
            locationLandmark: location.landmark,
            locationLatitude: location.latitude,
            locationLongitude: location.longitude,
            incidentDescription: _note.text.trim(),
            serviceOption: booking.items
                .map((item) => '${item.name} × ${item.quantity}')
                .join(', '),
            basePrice: booking.subtotal + travelFee,
            travelFee: travelFee,
            discount: discount,
            partnerId: shop.id,
            partnerName: shop.station.name,
            items: booking.items,
            paymentMethod: _payment,
            voucherCode: _voucherCode ?? '',
          );
      if (_voucherCode != null) {
        ref.read(voucherProvider.notifier).markUsed(_voucherCode!);
      }
      context.pushReplacement(
        '/order-tracking?id=${Uri.encodeComponent(order.id)}',
      );
    } on StateError {
      setState(() {
        _submitting = false;
        _error = 'Bạn đang có đơn cứu hộ. Hãy hoàn tất hoặc hủy đơn trước khi đặt mới.';
      });
    } on ArgumentError {
      setState(() {
        _submitting = false;
        _error = 'Thông tin đơn chưa hợp lệ. Vui lòng kiểm tra lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final matches = ref
        .watch(partnerShopsProvider)
        .where((shop) => shop.id == booking?.partnerId);
    final shop = matches.isEmpty ? null : matches.first;
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
    final voucherMatches = ref
        .watch(voucherProvider)
        .where((offer) => offer.code == _voucherCode);
    final voucher = voucherMatches.isEmpty ? null : voucherMatches.first;
    final discount = booking.discountFor(
      voucher,
      ref.read(voucherClockProvider)(),
    );
    final distance = stationDistanceKm(shop.station, _location);
    final travelFee = MarketplaceBooking.travelFee(distance);
    final total = booking.subtotal + travelFee - discount;
    final validAddress =
        _address.text.trim().length >= 5 && _address.text.trim().length <= 240;
    final canOrder =
        !_submitting &&
        booking.isValidFor(shop) &&
        vehicle != null &&
        validAddress &&
        _note.text.length <= 500 &&
        activeOrders.isEmpty;
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
              if (!booking.isValidFor(shop))
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
                onChanged: (value) => setState(() {
                  _addressRevision++;
                  _location = RescueLocation(address: value.trim());
                  _locationError = null;
                }),
              ),
              if (_location?.hasCoordinates ?? false)
                Text(
                  'GPS: ${_location!.latitude!.toStringAsFixed(6)}, ${_location!.longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: HomeColors.secondary,
                    fontSize: 12,
                  ),
                ),
              if (_locationError != null)
                Text(
                  _locationError!,
                  style: const TextStyle(color: HomeColors.red),
                ),
              TextButton.icon(
                onPressed: _loadingLocation ? null : _locate,
                icon: const Icon(Icons.my_location, color: HomeColors.red),
                label: Text(
                  _loadingLocation
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
                onChanged: (_) => setState(() {}),
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
                title: Text(_payment.label),
                subtitle: const Text('Phương thức thanh toán'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _choosePayment,
              ),
              ListTile(
                key: const ValueKey('checkout-voucher'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.local_offer_outlined,
                  color: HomeColors.red,
                ),
                title: Text(_voucherCode ?? 'Thêm mã giảm giá / Voucher'),
                subtitle: _voucherCode != null && discount == 0
                    ? const Text(
                        'Voucher không còn hợp lệ',
                        style: TextStyle(color: HomeColors.red),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _chooseVoucher(booking),
              ),
            ],
          ),
          MarketplaceSection(
            title: 'Chi tiết giá',
            children: [
              _PriceLine('Tổng tạm tính', booking.subtotal),
              _PriceLine('Phí di chuyển/cứu hộ', travelFee),
              _PriceLine('Giảm giá voucher', -discount),
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
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _error!,
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
            onPressed: canOrder ? () => _placeOrder(booking, travelFee) : null,
            child: Text(
              _submitting ? 'ĐANG ĐẶT ĐƠN...' : 'ĐẶT ĐƠN CỨU HỘ',
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
