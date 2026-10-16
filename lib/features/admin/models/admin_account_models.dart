import 'dart:typed_data';

class AdminAccountProfile {
  const AdminAccountProfile({
    required this.name,
    required this.email,
    this.phone = '',
  });
  final String name;
  final String email;
  final String phone;
}

class AdminOperatingSettings {
  const AdminOperatingSettings({
    this.feePercent = 10,
    this.weatherFactor = 1.2,
    this.sosFactor = 1.5,
    this.sosSound = true,
    this.sandbox = true,
  });
  final double feePercent;
  final double weatherFactor;
  final double sosFactor;
  final bool sosSound;
  final bool sandbox;

  AdminOperatingSettings copyWith({
    double? feePercent,
    double? weatherFactor,
    double? sosFactor,
    bool? sosSound,
    bool? sandbox,
  }) => AdminOperatingSettings(
    feePercent: feePercent ?? this.feePercent,
    weatherFactor: weatherFactor ?? this.weatherFactor,
    sosFactor: sosFactor ?? this.sosFactor,
    sosSound: sosSound ?? this.sosSound,
    sandbox: sandbox ?? this.sandbox,
  );
}

enum AdminStaffRole {
  admin('Quản trị viên'),
  shiftStaff('Nhân viên ca trực');

  const AdminStaffRole(this.label);
  final String label;
}

class AdminStaffMember {
  const AdminStaffMember({
    required this.id,
    required this.name,
    required this.email,
    this.role = AdminStaffRole.shiftStaff,
    this.onDuty = true,
  });
  final String id;
  final String name;
  final String email;
  final AdminStaffRole role;
  final bool onDuty;
  AdminStaffMember copyWith({AdminStaffRole? role, bool? onDuty}) =>
      AdminStaffMember(
        id: id,
        name: name,
        email: email,
        role: role ?? this.role,
        onDuty: onDuty ?? this.onDuty,
      );
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.target,
    required this.at,
  });
  final String actorId;
  final String actorName;
  final String action;
  final String target;
  final DateTime at;
}

class AdminLoginEntry {
  const AdminLoginEntry({
    required this.device,
    required this.description,
    required this.at,
    this.current = false,
  });
  final String device;
  final String description;
  final DateTime at;
  final bool current;
}

class AdminSupportRequest {
  const AdminSupportRequest({
    required this.id,
    required this.subject,
    required this.message,
    required this.at,
  });
  final String id;
  final String subject;
  final String message;
  final DateTime at;
}

class AdminAccountState {
  const AdminAccountState({
    required this.profile,
    required this.settings,
    required this.staff,
    required this.logins,
    this.avatarBytes,
    this.requests = const [],
    this.busy = false,
  });
  final AdminAccountProfile profile;
  final AdminOperatingSettings settings;
  final List<AdminStaffMember> staff;
  final List<AdminLoginEntry> logins;
  final Uint8List? avatarBytes;
  final List<AdminSupportRequest> requests;
  final bool busy;
  AdminAccountState copyWith({
    AdminAccountProfile? profile,
    AdminOperatingSettings? settings,
    List<AdminStaffMember>? staff,
    Uint8List? avatarBytes,
    List<AdminSupportRequest>? requests,
    bool? busy,
  }) => AdminAccountState(
    profile: profile ?? this.profile,
    settings: settings ?? this.settings,
    staff: staff ?? this.staff,
    logins: logins,
    avatarBytes: avatarBytes ?? this.avatarBytes,
    requests: requests ?? this.requests,
    busy: busy ?? this.busy,
  );
}

class AdminAccountResult {
  const AdminAccountResult(this.success, [this.message]);
  final bool success;
  final String? message;
}
