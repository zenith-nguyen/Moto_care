abstract final class AuthValidation {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?[0-9]{9,15}$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email';
    return _email.hasMatch(email) ? null : 'Email không hợp lệ';
  }

  static String? loginIdentifier(String? value) {
    final identifier = value?.trim() ?? '';
    if (identifier.isEmpty) {
      return 'Vui lòng nhập email hoặc số điện thoại';
    }
    return _email.hasMatch(identifier) || _phone.hasMatch(identifier)
        ? null
        : 'Email hoặc số điện thoại không hợp lệ';
  }
}
