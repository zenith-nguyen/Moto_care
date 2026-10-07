import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/home/theme/home_theme.dart';
import 'package:moto_care/features/auth/screens/login_screen.dart';
import 'package:moto_care/features/home/models/home_user.dart';
import 'package:moto_care/features/home/screens/trang_chu.dart';
import 'package:moto_care/features/profile/models/user_profile.dart';
import 'package:moto_care/features/profile/providers/profile_provider.dart';
import 'package:moto_care/features/profile/screens/thong_tin_ca_nhan_screen.dart';
import 'package:moto_care/features/profile/services/profile_account_service.dart';
import 'package:moto_care/features/profile/services/profile_device_service.dart';
import 'package:moto_care/features/profile/widgets/profile_edit_sheet.dart';

import 'fixtures/user_profile_fixture.dart';

class _Device extends ProfileDeviceService {
  bool authenticated = true;
  bool cancelPhoto = false;
  bool recoverPhoto = false;
  String? error;
  int authCalls = 0;
  Completer<bool>? pendingAuth;

  @override
  Future<bool> authenticate() async {
    authCalls++;
    if (error != null) throw ProfileDeviceException(error!);
    return pendingAuth == null ? authenticated : await pendingAuth!.future;
  }

  @override
  Future<Uint8List?> pickAvatar() async {
    if (error != null) throw ProfileDeviceException(error!);
    return cancelPhoto
        ? null
        : (await rootBundle.load('assets/images/Logo_motocare.png')).buffer
              .asUint8List();
  }

  @override
  Future<Uint8List?> recoverAvatar() =>
      recoverPhoto ? pickAvatar() : Future.value(null);
}

class _Account extends ProfileAccountService {
  int changes = 0;
  int deletions = 0;
  String? error;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changes++;
    if (error != null) throw ProfileAccountException(error!);
  }

  @override
  Future<void> deleteAccount(String userId) async {
    deletions++;
    if (error != null) throw ProfileAccountException(error!);
  }
}

Future<GoRouter> _open(
  WidgetTester tester, {
  UserProfile profile = profileFixture,
  _Device? device,
  ProfileAccountService? account,
  bool home = false,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialUserProfileProvider.overrideWithValue(profile),
        profileDeviceServiceProvider.overrideWithValue(device ?? _Device()),
        if (account != null)
          profileAccountServiceProvider.overrideWithValue(account),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  router.go(
    home ? '/trang-chu' : '/thong-tin-ca-nhan',
    extra: home
        ? const HomeUser(
            displayName: 'Nguyễn Văn An',
            memberId: 'member-001',
            membershipLabel: 'Thành viên Vàng',
          )
        : null,
  );
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _edit(
  WidgetTester tester, {
  String name = 'Nguyễn An',
  String phone = '+84 900 000 003',
}) async {
  await _tap(tester, find.text('Chỉnh sửa hồ sơ'));
  await _enter(tester, 'profile-name', name);
  await _enter(tester, 'profile-phone', phone);
  await _enter(tester, 'profile-contact-phone', '0900000004');
  await _enter(tester, 'profile-medical-note', 'Lưu ý khi hỗ trợ');
  await _tap(tester, find.text('Lưu thay đổi'));
}

void main() {
  testWidgets(
    'Profile renders all requested information with the shared light theme',
    (tester) async {
      await _open(tester);
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor,
        HomeColors.background,
      );
      for (final label in [
        'Nguyễn Văn An',
        '0900000001',
        'Thành viên Vàng',
        'Cứu hộ khẩn cấp',
        '0900000002',
        'Dị ứng penicillin',
        'Phương tiện & Địa chỉ',
        'Xe tay ga • Honda Vision',
        '59-X1 123.45',
        'Lốp không săm',
        'Quận 3, TP. Hồ Chí Minh',
        'Quận 1, TP. Hồ Chí Minh',
        'Tài khoản & Bảo mật',
        'FaceID / Vân tay',
        'an@example.com',
        'Đăng xuất',
        'Xóa tài khoản',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Account opens the profile, edits persist and home receives the updated name',
    (tester) async {
      final router = await _open(tester, home: true);
      await _tap(tester, find.text('Tài khoản'));
      await _tap(tester, find.byTooltip('Chỉnh sửa tài khoản'));
      expect(router.state.uri.path, '/thong-tin-ca-nhan');
      expect(find.byType(ThongTinCaNhanScreen), findsOneWidget);
      await _edit(tester);
      expect(
        _container(tester).read(profileProvider).profile.phoneNumber,
        '0900000003',
      );
      await _tap(tester, find.text('Trang chủ'));
      expect(find.text('Chào Nguyễn An'), findsOneWidget);
      await _tap(tester, find.text('Tài khoản'));
      await _tap(tester, find.byTooltip('Chỉnh sửa tài khoản'));
      expect(find.text('Nguyễn An'), findsOneWidget);
      expect(find.text('0900000003'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Invalid phone keeps the edit sheet open and cancel preserves the profile',
    (tester) async {
      await _open(tester);
      await _edit(tester, phone: '123');
      expect(find.byType(ProfileEditSheet), findsOneWidget);
      expect(
        find.text('Nhập SĐT Việt Nam hợp lệ (0… hoặc +84…)'),
        findsOneWidget,
      );
      expect(
        _container(tester).read(profileProvider).profile,
        same(profileFixture),
      );
      await _tap(tester, find.byTooltip('Đóng chỉnh sửa'));
      expect(find.byType(ProfileEditSheet), findsNothing);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
    },
  );

  testWidgets('Emergency contact and medical note can be cleared', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('Chỉnh sửa'));
    await _enter(tester, 'profile-contact-phone', '');
    await _enter(tester, 'profile-medical-note', '');
    await _tap(tester, find.text('Lưu thay đổi'));
    final profile = _container(tester).read(profileProvider).profile;
    expect(profile.emergencyContactPhone, isEmpty);
    expect(profile.medicalNote, isEmpty);
  });

  testWidgets(
    'Avatar selection, cancel and permission failure preserve expected state',
    (tester) async {
      final device = _Device();
      await _open(tester, device: device);
      await _tap(tester, find.byTooltip('Sửa ảnh đại diện'));
      await tester.runAsync(() async {});
      await tester.pumpAndSettle();
      final selected = _container(tester).read(profileProvider).avatarBytes;
      expect(selected, isNotNull);
      expect(find.byType(Image), findsOneWidget);
      device.cancelPhoto = true;
      await _tap(tester, find.byTooltip('Sửa ảnh đại diện'));
      expect(
        _container(tester).read(profileProvider).avatarBytes,
        same(selected),
      );
      device.error = 'Không thể mở thư viện ảnh';
      await _tap(tester, find.byTooltip('Sửa ảnh đại diện'));
      expect(find.text('Không thể mở thư viện ảnh'), findsOneWidget);
      expect(
        _container(tester).read(profileProvider).avatarBytes,
        same(selected),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Biometric authentication protects edits and canceled disabling retains the preference',
    (tester) async {
      final device = _Device();
      await _open(tester, device: device);
      await _tap(
        tester,
        find.byKey(const ValueKey('profile-biometric-switch')),
      );
      expect(device.authCalls, 1);
      expect(_container(tester).read(profileProvider).biometricEnabled, isTrue);
      await _tap(tester, find.text('Chỉnh sửa hồ sơ'));
      expect(device.authCalls, 2);
      expect(find.byType(ProfileEditSheet), findsOneWidget);
      await _tap(tester, find.byTooltip('Đóng chỉnh sửa'));
      device.authenticated = false;
      await _tap(
        tester,
        find.byKey(const ValueKey('profile-biometric-switch')),
      );
      expect(_container(tester).read(profileProvider).biometricEnabled, isTrue);
      await _tap(tester, find.text('Chỉnh sửa hồ sơ'));
      expect(find.byType(ProfileEditSheet), findsNothing);
      device.authenticated = true;
      await _tap(
        tester,
        find.byKey(const ValueKey('profile-biometric-switch')),
      );
      expect(
        _container(tester).read(profileProvider).biometricEnabled,
        isFalse,
      );
    },
  );

  testWidgets('Unsupported biometrics leaves the switch off', (tester) async {
    final device = _Device()..error = 'Thiết bị chưa hỗ trợ sinh trắc học';
    await _open(tester, device: device);
    await _tap(tester, find.byKey(const ValueKey('profile-biometric-switch')));
    expect(_container(tester).read(profileProvider).biometricEnabled, isFalse);
    expect(find.text('Thiết bị chưa hỗ trợ sinh trắc học'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Biometric requests cannot be submitted twice while pending', (
    tester,
  ) async {
    final device = _Device()..pendingAuth = Completer<bool>();
    await _open(tester, device: device);
    final tile = find.byKey(const ValueKey('profile-biometric-switch'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    expect(device.authCalls, 1);
    device.pendingAuth!.complete(true);
    await tester.pumpAndSettle();
    expect(_container(tester).read(profileProvider).biometricEnabled, isTrue);
  });

  testWidgets(
    'Password validation prevents invalid submission and service success closes the dialog',
    (tester) async {
      final account = _Account();
      await _open(tester, account: account);
      await _tap(tester, find.text('Đổi mật khẩu'));
      await _enter(tester, 'current-password', 'old-password');
      await _enter(tester, 'new-password', 'new-password');
      await _enter(tester, 'confirm-password', 'different-password');
      await _tap(tester, find.text('Cập nhật mật khẩu'));
      expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);
      expect(account.changes, 0);
      await _enter(tester, 'confirm-password', 'new-password');
      await _tap(tester, find.text('Cập nhật mật khẩu'));
      expect(account.changes, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Đã đổi mật khẩu.'), findsOneWidget);
      expect(
        _container(tester).read(profileProvider).profile,
        same(profileFixture),
      );
    },
  );

  testWidgets('Unavailable account service never reports password success', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('Đổi mật khẩu'));
    await _enter(tester, 'current-password', 'old-password');
    await _enter(tester, 'new-password', 'new-password');
    await _enter(tester, 'confirm-password', 'new-password');
    await _tap(tester, find.text('Cập nhật mật khẩu'));
    expect(
      find.text('Chưa thể đổi mật khẩu. Dịch vụ tài khoản chưa sẵn sàng.'),
      findsOneWidget,
    );
    expect(find.text('Đã đổi mật khẩu.'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('Delete cancellation and service failure keep the account open', (
    tester,
  ) async {
    final account = _Account()..error = 'Chưa thể xóa tài khoản';
    final router = await _open(tester, account: account);
    await _tap(tester, find.text('Xóa tài khoản'));
    await _tap(tester, find.text('Hủy'));
    expect(account.deletions, 0);
    await _tap(tester, find.text('Xóa tài khoản'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Xóa tài khoản'),
      ),
    );
    expect(account.deletions, 1);
    expect(router.state.uri.path, '/thong-tin-ca-nhan');
    expect(
      _container(tester).read(profileProvider).profile,
      same(profileFixture),
    );
    expect(find.text('Chưa thể xóa tài khoản'), findsOneWidget);
  });

  testWidgets(
    'Successful account deletion clears the profile and returns to login',
    (tester) async {
      final account = _Account();
      final router = await _open(tester, account: account);
      await _tap(tester, find.text('Xóa tài khoản'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xóa tài khoản'),
        ),
      );
      expect(account.deletions, 1);
      expect(router.state.uri.path, '/login');
      expect(router.canPop(), isFalse);
      expect(
        _container(tester).read(profileProvider).profile,
        UserProfile.empty,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Logout cancellation preserves data and confirmation removes the previous route stack',
    (tester) async {
      final router = await _open(tester, home: true);
      router.push('/thong-tin-ca-nhan');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Đăng xuất'));
      await _tap(tester, find.text('Hủy'));
      expect(
        _container(tester).read(profileProvider).profile,
        same(profileFixture),
      );
      await _tap(tester, find.text('Đăng xuất'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      expect(router.state.uri.path, '/login');
      expect(router.canPop(), isFalse);
      expect(
        _container(tester).read(profileProvider).profile,
        UserProfile.empty,
      );
      expect(find.byType(TrangChu), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Direct profile route has neutral placeholders and a home fallback',
    (tester) async {
      final router = await _open(tester, profile: UserProfile.empty);
      expect(find.text('Hồ sơ của bạn'), findsOneWidget);
      expect(find.text('Chưa cập nhật số điện thoại'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsNothing);
      await _tap(tester, find.byTooltip('Quay lại'));
      expect(router.state.uri.path, '/trang-chu');
      expect(find.text('Chào bạn'), findsOneWidget);
    },
  );

  testWidgets(
    'Narrow screens, larger text and the keyboard remain scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('Chỉnh sửa hồ sơ'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await _enter(tester, 'profile-name', 'Nguyễn An');
      await _tap(tester, find.text('Lưu thay đổi'));
      expect(find.byType(ProfileEditSheet), findsNothing);
      expect(
        _container(tester).read(profileProvider).profile.fullName,
        'Nguyễn An',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
