enum AppRole {
  customer('CUSTOMER'),
  provider('PROVIDER'),
  admin('ADMIN');

  const AppRole(this.wireValue);

  final String wireValue;

  static AppRole fromWire(Object? raw) {
    return values.firstWhere(
      (role) => role.wireValue == raw,
      orElse: () => throw FormatException('Unsupported user role: $raw'),
    );
  }
}

enum AppUserStatus {
  active('ACTIVE'),
  pendingApproval('PENDING_APPROVAL'),
  suspended('SUSPENDED');

  const AppUserStatus(this.wireValue);

  final String wireValue;

  static AppUserStatus fromWire(Object? raw) {
    return values.firstWhere(
      (status) => status.wireValue == raw,
      orElse: () => throw FormatException('Unsupported user status: $raw'),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final AppRole role;
  final AppUserStatus status;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    final phone = json['phone'];
    if (id is! int || name is! String) {
      throw const FormatException('Invalid user response.');
    }
    if (email != null && email is! String) {
      throw const FormatException('Invalid user email.');
    }
    if (phone != null && phone is! String) {
      throw const FormatException('Invalid user phone.');
    }

    return AppUser(
      id: id,
      name: name,
      email: email as String?,
      phone: phone as String?,
      role: AppRole.fromWire(json['role']),
      status: AppUserStatus.fromWire(json['status']),
    );
  }
}
