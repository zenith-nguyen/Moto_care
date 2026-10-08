import '../../activity/models/rescue_order.dart';
import '../../home/models/rescue_location.dart';

class CheckoutState {
  const CheckoutState({
    this.location,
    this.payment = RescuePaymentMethod.cash,
    this.note = '',
    this.error,
    this.locationError,
    this.loadingLocation = false,
    this.submitting = false,
  });
  final RescueLocation? location;
  final RescuePaymentMethod payment;
  final String? error, locationError;
  final String note;
  final bool loadingLocation, submitting;
  CheckoutState copyWith({
    RescueLocation? location,
    RescuePaymentMethod? payment,
    String? note,
    String? error,
    bool clearError = false,
    String? locationError,
    bool clearLocationError = false,
    bool? loadingLocation,
    bool? submitting,
  }) => CheckoutState(
    location: location ?? this.location,
    payment: payment ?? this.payment,
    note: note ?? this.note,
    error: clearError ? null : error ?? this.error,
    locationError: clearLocationError
        ? null
        : locationError ?? this.locationError,
    loadingLocation: loadingLocation ?? this.loadingLocation,
    submitting: submitting ?? this.submitting,
  );
}
