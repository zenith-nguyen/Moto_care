import '../domain/admin_operation_models.dart';

/// Display model for the provider-approval screens in the REVO prototype look.
///
/// The identity fields the backend provides (id, name, email, phone, status)
/// are REAL; the richer KYC fields the prototype shows (vehicle, plate, CCCD,
/// skills, address, registration time) are DEMO placeholders derived
/// deterministically from the provider id. The founder approved demo CCCD /
/// phone data; nothing here is presented as verified.
class ProviderProfileView {
  const ProviderProfileView({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicle,
    required this.plate,
    required this.registeredAt,
    required this.address,
    required this.citizenIdMasked,
    required this.status,
  });

  final int id;
  final String code;
  final String name;
  final String email;
  final String phone;
  final String vehicle;
  final String plate;
  final DateTime registeredAt;
  final String address;
  final String citizenIdMasked;
  final ProviderApprovalStatus status;

  /// CCCD is never verified in this demo flow.
  bool get identityVerified => false;

  factory ProviderProfileView.fromApplication(
    PendingProviderApplication application,
  ) {
    final id = application.id;
    final phone =
        application.phone ??
        '0900 000 ${(100 + id).toString().padLeft(3, '0')}';
    final slug = _slug(application.name);
    final email = application.email ?? '$slug@example.test';
    final vehicle =
        '${_vehicles[id % _vehicles.length]} • '
        '${_kits[id % _kits.length]}';
    final plate =
        '59-X${(id % 9) + 1} '
        '${(101 + id).toString()}.${((id % 89) + 10).toString()}';
    final registeredAt = DateTime(
      2026,
      10,
      27,
      9 + (id % 8),
      (id * 7) % 60,
    ).subtract(Duration(days: id % 18));

    return ProviderProfileView(
      id: id,
      code: 'P-$id',
      name: application.name,
      email: email,
      phone: phone,
      vehicle: vehicle,
      plate: plate,
      registeredAt: registeredAt,
      address: _addresses[id % _addresses.length],
      citizenIdMasked: '079xxxxxxxxx',
      status: application.approvalStatus,
    );
  }

  static const _vehicles = [
    'Honda Wave',
    'Yamaha Sirius',
    'Honda Blade',
    'Honda Vision',
    'Yamaha Jupiter',
  ];
  static const _kits = [
    'Bộ dụng cụ cứu hộ',
    'Bình kích điện',
    'Máy bơm lốp mini',
    'Bộ vá lốp lưu động',
  ];
  static const _addresses = [
    '12 Nguyễn Huệ, Q.1, TP.HCM',
    '45 Lê Lợi, Q.1, TP.HCM',
    '88 Cách Mạng Tháng 8, Q.3, TP.HCM',
    '21 Phan Xích Long, Q. Phú Nhuận, TP.HCM',
    '7 Nguyễn Thị Minh Khai, Q.1, TP.HCM',
  ];

  static String _slug(String name) {
    final ascii = name
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'đ'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return ascii.isEmpty ? 'tho' : ascii;
  }
}
