abstract final class ProfileValidation {
  static String normalizePhone(String value) {
    final phone = value.trim().replaceAll(RegExp(r'[\s.()\-]'), '');
    return phone.startsWith('+84') ? '0${phone.substring(3)}' : phone;
  }

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Vui lòng nhập họ tên';
    if (name.length > 80) return 'Họ tên tối đa 80 ký tự';
    return null;
  }

  static String? phone(String? value, {bool optional = false}) {
    final raw = value?.trim() ?? '';
    if (optional && raw.isEmpty) return null;
    if (raw.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^(0[35789]\d{8}|02\d{9})$').hasMatch(normalizePhone(raw))) {
      return 'Nhập SĐT Việt Nam hợp lệ (0… hoặc +84…)';
    }
    return null;
  }

  static String? currentPassword(String? value) =>
      value == null || value.isEmpty ? 'Nhập mật khẩu hiện tại' : null;
  static String? newPassword(String? value, String current) {
    if (value == null || value.length < 8 || value.length > 128) {
      return 'Mật khẩu phải có từ 8 đến 128 ký tự';
    }
    if (value.trim().isEmpty) {
      return 'Mật khẩu không được chỉ chứa khoảng trắng';
    }
    if (value == current) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
    return null;
  }

  static String? confirmPassword(String? value, String password) =>
      value != password ? 'Mật khẩu nhập lại không khớp' : null;
}
