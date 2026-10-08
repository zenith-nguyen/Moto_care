import '../../home/models/rescue_location.dart';

String? validateIncidentAddress(String? value) =>
    (value?.trim().length ?? 0) < 5
    ? 'Vui lòng nhập địa chỉ ít nhất 5 ký tự.'
    : null;
bool isValidRescueLocation(RescueLocation location) {
  final address = location.address.trim();
  if (address.length < 5 ||
      address.length > 240 ||
      location.landmark.trim().length > 240) {
    return false;
  }
  return (location.latitude == null) == (location.longitude == null) &&
      (location.latitude == null ||
          location.latitude!.isFinite && location.latitude!.abs() <= 90) &&
      (location.longitude == null ||
          location.longitude!.isFinite && location.longitude!.abs() <= 180);
}
