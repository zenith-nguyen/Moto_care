import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/admin/models/admin_account_models.dart';
import 'package:revo/features/admin/models/admin_models.dart';
import 'package:revo/features/admin/providers/admin_account_provider.dart';
import 'package:revo/features/admin/providers/admin_providers.dart';
import 'package:revo/features/admin/services/admin_account_service.dart';
import 'package:revo/features/profile/services/profile_account_service.dart';

const _superAdmin = AdminSession(
  id: 'ADM-2026-88',
  name: 'Quản trị viên',
  email: 'admin@revo.vn',
  role: 'ADMIN',
  canManageAdmins: true,
);

class _AccountService extends SessionAdminAccountService {
  Object? error;
  Completer<void>? pending;
  int writes = 0;
  Future<void> save() async {
    writes++;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> saveProfile(AdminAccountProfile profile) => save();
  @override
  Future<void> saveSettings(AdminOperatingSettings settings) => save();
  @override
  Future<void> saveStaff(AdminStaffMember member) => save();
  @override
  Future<void> saveSupportRequest(AdminSupportRequest request) => save();
}

class _PasswordService implements ProfileAccountService {
  int calls = 0;
  String? current;
  String? next;
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls++;
    current = currentPassword;
    next = newPassword;
  }

  @override
  Future<void> deleteAccount(String userId) async =>
      throw UnimplementedError('Not used by Admin');
}

void main() {
  ProviderContainer container({
    AdminSession session = _superAdmin,
    _AccountService? service,
    ProfileAccountService? passwordService,
  }) {
    final result = ProviderContainer(
      overrides: [
        adminSessionProvider.overrideWith(
          () => AdminSessionController(initialSession: session),
        ),
        adminClockProvider.overrideWithValue(() => DateTime(2026, 10, 15, 10)),
        adminAccountServiceProvider.overrideWithValue(
          service ?? _AccountService(),
        ),
        if (passwordService != null)
          profileAccountServiceProvider.overrideWithValue(passwordService),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  test('Profile validation, normalization and saving preserve the auth session and order repository', () async {
    final c = container();
    final actor = c.read(adminSessionProvider);
    final repository = c.read(adminRepositoryProvider);
    final controller = c.read(adminAccountProvider.notifier);
    expect(
      (await controller.updateProfile(
        const AdminAccountProfile(name: '', email: 'bad'),
      )).success,
      false,
    );
    expect(c.read(adminAuditTrailProvider), isEmpty);
    expect(
      (await controller.updateProfile(
        const AdminAccountProfile(
          name: '  Điều phối viên  ',
          email: 'admin@revo.vn',
          phone: '+84 901 234 567',
        ),
      )).success,
      true,
    );
    expect(c.read(adminAccountProvider).profile.name, 'Điều phối viên');
    expect(c.read(adminAccountProvider).profile.phone, '0901234567');
    expect(c.read(adminSessionProvider), same(actor));
    expect(c.read(adminRepositoryProvider), same(repository));
    expect(
      c.read(adminAuditTrailProvider).single.action,
      'Cập nhật hồ sơ quản trị',
    );
  });

  test('Failed configuration writes preserve settings and can be retried without duplicate audit entries', () async {
    final service = _AccountService()
      ..error = const AdminException('Mất kết nối');
    final c = container(service: service);
    final before = c.read(adminAccountProvider).settings;
    final draft = before.copyWith(
      feePercent: 15,
      weatherFactor: 1.4,
      sandbox: false,
    );
    final controller = c.read(adminAccountProvider.notifier);
    expect((await controller.updateSettings(draft)).message, 'Mất kết nối');
    expect(c.read(adminAccountProvider).settings, same(before));
    expect(c.read(adminAccountProvider).busy, false);
    expect(c.read(adminAuditTrailProvider), isEmpty);
    service.error = null;
    expect((await controller.updateSettings(draft)).success, true);
    expect(c.read(adminAccountProvider).settings.sandbox, false);
    expect(c.read(adminAccountProvider).settings.feePercent, 15);
    expect(c.read(adminAuditTrailProvider), hasLength(1));
    expect(
      (await controller.updateSettings(
        draft.copyWith(weatherFactor: double.nan),
      )).success,
      false,
    );
    expect(service.writes, 2);
  });

  test('A regular Admin cannot grant privileges, edit fees or disable Sandbox but can choose SOS sound', () async {
    final service = _AccountService();
    final c = container(
      service: service,
      session: const AdminSession(
        id: 'regular',
        name: 'Admin',
        email: 'admin@example.test',
        role: 'ADMIN',
      ),
    );
    final controller = c.read(adminAccountProvider.notifier);
    final settings = c.read(adminAccountProvider).settings;
    expect(
      (await controller.updateSettings(settings.copyWith(sandbox: false)))
          .success,
      false,
    );
    expect(
      (await controller.updateSettings(settings.copyWith(feePercent: 20)))
          .success,
      false,
    );
    expect(
      (await controller.updateStaff(
        c
            .read(adminAccountProvider)
            .staff
            .first
            .copyWith(role: AdminStaffRole.shiftStaff),
      )).success,
      false,
    );
    expect(service.writes, 0);
    expect(
      (await controller.updateSettings(settings.copyWith(sosSound: false)))
          .success,
      true,
    );
    expect(c.read(adminAccountProvider).settings.sosSound, false);
    expect(c.read(adminSessionProvider)!.isSuperAdmin, false);
  });

  test('Super Admin changes roster roles and duty state without changing their own verified authority', () async {
    final c = container();
    final controller = c.read(adminAccountProvider.notifier);
    final member = c.read(adminAccountProvider).staff.last;
    expect(
      (await controller.updateStaff(
        member.copyWith(role: AdminStaffRole.admin, onDuty: true),
      )).success,
      true,
    );
    expect(c.read(adminAccountProvider).staff.last.role, AdminStaffRole.admin);
    expect(c.read(adminAccountProvider).staff.last.onDuty, true);
    expect(c.read(adminAuditTrailProvider).single.target, member.id);
    expect(c.read(adminSessionProvider), same(_superAdmin));
  });

  test('Concurrent writes are blocked and a signed-out session cannot receive a late update', () async {
    final service = _AccountService()..pending = Completer<void>();
    final c = container(service: service);
    final controller = c.read(adminAccountProvider.notifier);
    final draft = c
        .read(adminAccountProvider)
        .settings
        .copyWith(feePercent: 20);
    final pending = controller.updateSettings(draft);
    expect(c.read(adminAccountProvider).busy, true);
    expect((await controller.updateSettings(draft)).success, false);
    c.read(adminSessionProvider.notifier).signOut();
    expect(c.read(adminAccountProvider).profile.email, isEmpty);
    service.pending!.complete();
    expect((await pending).success, false);
    expect(c.read(adminAccountProvider).settings.feePercent, 10);
    expect(c.read(adminAuditTrailProvider), isEmpty);
    expect(c.read(adminAccountProvider).busy, false);
  });

  test('Password changes use the auth boundary and never enter profile or audit data', () async {
    final auth = _PasswordService();
    final c = container(passwordService: auth);
    final controller = c.read(adminAccountProvider.notifier);
    final current = List.filled(12, 'a').join();
    final replacement = List.filled(14, 'b').join();
    expect((await controller.changePassword(current, current)).success, false);
    expect(auth.calls, 0);
    expect(
      (await controller.changePassword(current, replacement)).success,
      true,
    );
    expect(auth.current, current);
    expect(auth.next, replacement);
    final audit = c.read(adminAuditTrailProvider).single;
    expect(audit.action, 'Đổi mật khẩu');
    expect('${audit.action} ${audit.target}', isNot(contains(replacement)));
  });

  test('Missing auth service reports an error without recording a successful password change', () async {
    final c = container();
    final result = await c
        .read(adminAccountProvider.notifier)
        .changePassword(
          List.filled(12, 'a').join(),
          List.filled(12, 'b').join(),
        );
    expect(result.success, false);
    expect(result.message, contains('chưa sẵn sàng'));
    expect(c.read(adminAuditTrailProvider), isEmpty);
  });

  test('Support requests require content and remain available during the session, then clear on logout', () async {
    final c = container();
    final controller = c.read(adminAccountProvider.notifier);
    expect((await controller.requestSupport('Lỗi', 'ngắn')).success, false);
    expect(
      (await controller.requestSupport(
        'Lỗi đối soát',
        'Không mở được bảng đối soát hôm nay.',
      )).success,
      true,
    );
    expect(c.read(adminAccountProvider).requests.single.id, 'HT-0001');
    c.read(adminSessionProvider.notifier).signOut();
    expect(c.read(adminAccountProvider).requests, isEmpty);
    expect(c.read(adminAuditTrailProvider), isEmpty);
  });
}
