abstract final class VehicleValidation {
  static String normalizePlate(String plate) =>
      plate.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  static String plateKey(String plate) =>
      normalizePlate(plate).replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập tên xe.';
    if (text.length > 80) return 'Tên xe tối đa 80 ký tự.';
    return null;
  }

  static String? licensePlate(String? value) {
    final text = normalizePlate(value ?? '');
    if (text.isEmpty) return 'Vui lòng nhập biển số xe.';
    if (text.length > 20 ||
        !RegExp(r'^[A-Z0-9.\- ]+$').hasMatch(text) ||
        !RegExp(r'\d').hasMatch(text) ||
        plateKey(text).length < 5) {
      return 'Vui lòng kiểm tra lại biển số ghi trên xe.';
    }
    return null;
  }
}
