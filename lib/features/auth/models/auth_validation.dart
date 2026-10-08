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

  static bool registrationPhone(String value) =>
      RegExp(r'^0?[1-9][0-9]{8}$').hasMatch(value);
  static bool hasMinLength(String value) => value.length >= 8;
  static bool hasMixedCase(String value) =>
      RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value);
  static bool hasNumber(String value) => RegExp(r'[0-9]').hasMatch(value);
  static bool hasSpecialCharacter(String value) =>
      RegExp(r'[^a-zA-Z0-9\s]').hasMatch(value);
  static bool registrationPassword(String value) =>
      hasMinLength(value) &&
      hasMixedCase(value) &&
      hasNumber(value) &&
      hasSpecialCharacter(value);
}
