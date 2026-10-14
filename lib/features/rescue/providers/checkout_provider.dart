import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../home/models/rescue_location.dart';
import '../../home/providers/home_provider.dart';
import '../../location/services/device_location_service.dart';
import '../../partner/providers/partner_provider.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/checkout_state.dart';
import '../models/marketplace_booking.dart';
import '../services/checkout_service.dart';

// A screen token isolates simultaneous routes and disposes their drafts on exit.
typedef CheckoutKey = (Object, MarketplaceBooking?);
final checkoutProvider = NotifierProvider.autoDispose
    .family<CheckoutController, CheckoutState, CheckoutKey>(
      CheckoutController.new,
    );
final checkoutQuoteProvider = Provider.autoDispose
    .family<CheckoutQuote, CheckoutKey>((ref, key) {
      final state = ref.watch(checkoutProvider(key));
      return ref
          .watch(checkoutServiceProvider)
          .quote(
            booking: key.$2,
            shops: ref.watch(partnerShopsProvider),
            location: state.location,
            note: state.note,
            hasVehicle: ref.watch(defaultVehicleProvider) != null,
            hasActiveOrder: ref.watch(activityProvider).activeOrders.isNotEmpty,
            submitting: state.submitting,
          );
    });

class CheckoutController extends Notifier<CheckoutState> {
  CheckoutController(this.key);
  final CheckoutKey key;
  int _addressRevision = 0;
  @override
  CheckoutState build() =>
      CheckoutState(location: ref.read(rescueLocationProvider));
  void editAddress(String value) {
    _addressRevision++;
    state = state.copyWith(
      location: RescueLocation(address: value.trim()),
      clearLocationError: true,
    );
  }

  void editNote(String value) => state = state.copyWith(note: value);
  void selectPayment(RescuePaymentMethod value) =>
      state = state.copyWith(payment: value);
  Future<void> locate() async {
    if (state.loadingLocation) return;
    final revision = _addressRevision;
    state = state.copyWith(loadingLocation: true, clearLocationError: true);
    try {
      final result = await ref
          .read(deviceLocationProvider)()
          .timeout(const Duration(seconds: 24));
      if (!ref.mounted || revision != _addressRevision) return;
      if (!ref.read(rescueLocationProvider.notifier).confirmLocation(result)) {
        throw const LocationLookupException(
          'Vị trí không hợp lệ. Hãy nhập địa chỉ sự cố.',
        );
      }
      state = state.copyWith(location: result);
    } on Exception catch (error) {
      if (ref.mounted && revision == _addressRevision) {
        state = state.copyWith(
          locationError: error is LocationLookupException
              ? error.message
              : 'Chưa lấy được GPS. Thử lại hoặc nhập địa chỉ sự cố.',
        );
      }
    } finally {
      if (ref.mounted) state = state.copyWith(loadingLocation: false);
    }
  }

  RescueOrder? placeOrder(int displayedTravelFee) {
    if (state.submitting) return null;
    final booking = key.$2;
    final quote = ref
        .read(checkoutServiceProvider)
        .quote(
          booking: key.$2,
          shops: ref.read(partnerShopsProvider),
          location: state.location,
          note: state.note,
          hasVehicle: ref.read(defaultVehicleProvider) != null,
          hasActiveOrder: ref.read(activityProvider).activeOrders.isNotEmpty,
          submitting: state.submitting,
        );
    final shop = quote.shop;
    final vehicle = ref.read(defaultVehicleProvider);
    final location = state.location;
    if (booking == null ||
        shop == null ||
        vehicle == null ||
        location == null ||
        !quote.validBooking ||
        !ref.read(rescueLocationProvider.notifier).confirmLocation(location)) {
      state = state.copyWith(error: 'Kiểm tra lại tiệm, xe và địa chỉ sự cố.');
      return null;
    }
    if (quote.travelFee != displayedTravelFee) {
      state = state.copyWith(
        error: 'Phí di chuyển đã thay đổi. Vui lòng kiểm tra tổng tiền và đặt lại.',
      );
      return null;
    }
    state = state.copyWith(submitting: true, clearError: true);
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
            incidentDescription: state.note.trim(),
            serviceOption: booking.items
                .map((item) => '${item.name} × ${item.quantity}')
                .join(', '),
            basePrice: booking.subtotal + quote.travelFee,
            travelFee: quote.travelFee,
            partnerId: shop.id,
            partnerName: shop.station.name,
            items: booking.items,
            paymentMethod: state.payment,
          );
      return order;
    } on StateError {
      state = state.copyWith(
        submitting: false,
        error: 'Bạn đang có đơn cứu hộ. Hãy hoàn tất hoặc hủy đơn trước khi đặt mới.',
      );
    } on ArgumentError {
      state = state.copyWith(
        submitting: false,
        error: 'Thông tin đơn chưa hợp lệ. Vui lòng kiểm tra lại.',
      );
    }
    return null;
  }
}
