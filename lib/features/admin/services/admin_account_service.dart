import '../models/admin_account_models.dart';

/// Inject an authenticated backend adapter when the account/configuration APIs
/// are available. The default implementation is session-only like AdminRepository.
abstract interface class AdminAccountService {
  Future<void> saveProfile(AdminAccountProfile profile);
  Future<void> saveSettings(AdminOperatingSettings settings);
  Future<void> saveStaff(AdminStaffMember member);
  Future<void> saveSupportRequest(AdminSupportRequest request);
}

class SessionAdminAccountService implements AdminAccountService {
  const SessionAdminAccountService();
  Future<void> _save() =>
      Future<void>.delayed(const Duration(milliseconds: 150));
  @override
  Future<void> saveProfile(AdminAccountProfile profile) => _save();
  @override
  Future<void> saveSettings(AdminOperatingSettings settings) => _save();
  @override
  Future<void> saveStaff(AdminStaffMember member) => _save();
  @override
  Future<void> saveSupportRequest(AdminSupportRequest request) => _save();
}
