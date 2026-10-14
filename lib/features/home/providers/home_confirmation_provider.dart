import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../models/home_service.dart';
import 'home_provider.dart';

typedef HomeConfirmationKey = (Object, HomeService);
typedef HomeConfirmationState = ({bool submitted, String? error});
final homeConfirmationProvider = NotifierProvider.autoDispose
    .family<
      HomeConfirmationController,
      HomeConfirmationState,
      HomeConfirmationKey
    >(HomeConfirmationController.new);

class HomeConfirmationController extends Notifier<HomeConfirmationState> {
  HomeConfirmationController(this.key);
  final HomeConfirmationKey key;
  @override
  HomeConfirmationState build() => (submitted: false, error: null);
  RescueOrder? submit() {
    if (state.submitted) return null;
    final vehicle = ref.read(defaultVehicleProvider);
    final location = ref.read(rescueLocationProvider);
    if (vehicle == null ||
        location == null ||
        location.address.trim().isEmpty ||
        key.$2.orderType == null) {
      return null;
    }
    try {
      final order = ref
          .read(activityProvider.notifier)
          .createOrder(
            serviceType: key.$2.orderType!,
            userVehicle: '${vehicle.name} (${vehicle.licensePlate})',
            locationAddress: location.address,
            locationLandmark: location.landmark,
            locationLatitude: location.latitude,
            locationLongitude: location.longitude,
          );
      state = (submitted: true, error: null);
      return order;
    } on StateError {
      state = (
        submitted: false,
        error: 'Bạn đang có đơn cứu hộ. Hãy kiểm tra trong Hoạt động.',
      );
      return null;
    }
  }
}
