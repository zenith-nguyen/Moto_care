import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../vehicle/providers/vehicle_provider.dart';
import '../data/rescue_request_catalog.dart';
export '../data/rescue_request_catalog.dart'
    show rescueVehicleTypes, incidentServiceTypes;

class RescueRequestDraft {
  const RescueRequestDraft({
    required this.serviceName,
    this.selectedOption = 0,
    this.vehicleType = 'Xe tay ga',
    this.photo,
    this.error,
    this.submitted = false,
  });
  final String serviceName, vehicleType;
  final int selectedOption;
  final Uint8List? photo;
  final String? error;
  final bool submitted;
  ({RescueServiceType type, List<RescueOption> options}) get configuration =>
      configurationFor(serviceName);
}

final rescueRequestProvider = NotifierProvider.autoDispose
    .family<RescueRequestController, RescueRequestDraft, (Object, String)>(
      RescueRequestController.new,
    );
final rescueRequestReadyProvider = Provider.autoDispose
    .family<bool, (Object, String)>((ref, key) {
      final draft = ref.watch(rescueRequestProvider(key));
      final location = ref.watch(rescueLocationProvider);
      return location != null &&
          location.address.trim().isNotEmpty &&
          ref.watch(defaultVehicleProvider) != null &&
          ref.watch(activityProvider).activeOrders.isEmpty &&
          !draft.submitted;
    });

class RescueRequestController extends Notifier<RescueRequestDraft> {
  RescueRequestController(this.key);
  final (Object, String) key;
  @override
  RescueRequestDraft build() => RescueRequestDraft(serviceName: key.$2);
  void _update({
    String? service,
    int? option,
    String? vehicleType,
    Uint8List? photo,
    bool replacePhoto = false,
    String? error,
    bool? submitted,
  }) => state = RescueRequestDraft(
    serviceName: service ?? state.serviceName,
    selectedOption: option ?? state.selectedOption,
    vehicleType: vehicleType ?? state.vehicleType,
    photo: replacePhoto ? photo : state.photo,
    error: error,
    submitted: submitted ?? state.submitted,
  );
  void selectService(String value) => _update(service: value, option: 0);
  void selectOption(int index) {
    if (index >= 0 && index < state.configuration.options.length) {
      _update(option: index);
    }
  }

  void selectVehicleType(String value) {
    if (rescueVehicleTypes.contains(value)) _update(vehicleType: value);
  }

  void attachPhoto(Uint8List? value) => _update(
    photo: value == null
        ? null
        : Uint8List.fromList(value).asUnmodifiableView(),
    replacePhoto: true,
  );
  RescueOrder? submit(String description) {
    if (state.submitted ||
        ref.read(activityProvider).activeOrders.isNotEmpty ||
        ref.read(defaultVehicleProvider) == null ||
        ref.read(rescueLocationProvider)?.address.trim().isNotEmpty != true) {
      return null;
    }
    final location = ref.read(rescueLocationProvider)!;
    final vehicle = ref.read(defaultVehicleProvider)!;
    final configuration = state.configuration;
    final option = configuration.options[state.selectedOption];
    try {
      final order = ref
          .read(activityProvider.notifier)
          .createOrder(
            serviceType: configuration.type,
            serviceOption: option.label,
            basePrice: option.price,
            vehicleType: state.vehicleType,
            incidentPhotoBytes: state.photo,
            userVehicle: '${vehicle.name} (${vehicle.licensePlate})',
            locationAddress: location.address,
            locationLandmark: location.landmark,
            locationLatitude: location.latitude,
            locationLongitude: location.longitude,
            incidentDescription: description,
          );
      _update(submitted: true);
      return order;
    } on StateError {
      _update(error: 'Bạn đang có đơn cứu hộ. Hãy kiểm tra trong Hoạt động.');
      return null;
    }
  }
}
