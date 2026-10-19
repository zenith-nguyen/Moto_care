import '../models/models.dart';

abstract class OtpService {
  void bind(OrderOffer offer);
  String? demoCodeFor(String orderId);
  Future<bool> verify(String orderId, String code);
  Future<void> resend(String orderId, OtpChannel channel);
}

/// Local only: never sends an SMS/email or contacts a third-party service.
class DemoOtpService implements OtpService {
  DemoOtpService({this.latency = const Duration(milliseconds: 600)});
  final Duration latency;
  final Map<String, String> _codes = {};
  @override
  void bind(OrderOffer offer) =>
      _codes.putIfAbsent(offer.orderId, () => offer.verificationCode);
  @override
  String? demoCodeFor(String orderId) => _codes[orderId];
  @override
  Future<bool> verify(String orderId, String code) async {
    await Future<void>.delayed(latency);
    return RegExp(r'^\d{4}$').hasMatch(code) && _codes[orderId] == code;
  }

  @override
  Future<void> resend(String orderId, OtpChannel channel) async {
    await Future<void>.delayed(latency);
    if (!_codes.containsKey(orderId)) {
      throw StateError('Không tìm thấy mã của đơn này.');
    }
  }
}

/// A real backend adapter must replace this implementation before production.
class UnconfiguredOtpService implements OtpService {
  @override
  void bind(OrderOffer offer) {}
  @override
  String? demoCodeFor(String orderId) => null;
  @override
  Future<bool> verify(String orderId, String code) async =>
      throw StateError('Dịch vụ xác nhận chưa được cấu hình.');
  @override
  Future<void> resend(String orderId, OtpChannel channel) async =>
      throw StateError('Dịch vụ gửi mã chưa được cấu hình.');
}
