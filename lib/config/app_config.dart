import 'package:flutter/foundation.dart';

/// Opt in explicitly for a release demo; ordinary release builds fail closed
/// until real authentication/OTP/dispatch adapters are configured.
class AppConfig {
  AppConfig._();
  static const demoEnabled =
      bool.fromEnvironment('REVO_DEMO', defaultValue: !kReleaseMode);
  static const otpCooldown = Duration(seconds: 30);
  static const vehicleTypes = ['Xe máy', 'Xe tay ga', 'Ô tô'];
}
