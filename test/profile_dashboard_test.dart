import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:revo/core/router/app_router.dart';
import 'package:revo/core/theme/app_theme.dart';
import 'package:revo/features/customer/profile/profile_screen.dart';
import 'package:revo/features/home/theme/revo_home_theme.dart';
import 'package:revo/features/home/widgets/home_bottom_navigation.dart';
import 'package:revo/features/profile/models/user_profile.dart';
import 'package:revo/features/profile/providers/profile_actions_provider.dart';
import 'package:revo/features/profile/providers/profile_provider.dart';
import 'package:revo/features/profile/services/profile_account_service.dart';
import 'package:revo/features/profile/services/profile_device_service.dart';

import 'fixtures/user_profile_fixture.dart';

class _Device extends ProfileDeviceService {
  bool authenticated = true;
  int authCalls = 0;
  Completer<bool>? pendingAuth;
  Completer<Uint8List?>? pendingPhoto;

  @override
  Future<bool> authenticate() async {
    authCalls++;
    return pendingAuth == null ? authenticated : pendingAuth!.future;
  }

  @override
  Future<Uint8List?> pickAvatar() async => pendingPhoto == null
      ? (await rootBundle.load('assets/images/REVO.png')).buffer
            .asUint8List()
      : pendingPhoto!.future;

  @override
  Future<Uint8List?> recoverAvatar() async => null;
}

class _Account extends ProfileAccountService {
  int deletions = 0;
  bool failDelete = true;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount(String userId) async {
    deletions++;
    if (failDelete) {
      throw const ProfileAccountException('Không thể xóa tài khoản lúc này.');
    }
  }
}

Future<GoRouter> _open(
  WidgetTester tester, {
  UserProfile profile = profileFixture,
  _Device? device,
  ProfileAccountService? account,
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
  router.go('/tai-khoan');
  await tester.pumpAndSettle();
  return router;
}

ProviderContainer _state(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
Finder _key(String id) => find.byKey(ValueKey('account-$id'));

Future<void> _reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      220,
      scrollable: find.descendant(
        of: _key('scroll'),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Dashboard uses shared identity and verification without an unranked badge',
    (tester) async {
      await _open(
        tester,
        profile: const UserProfile(
          id: 'thu',
          fullName: 'Phạm Thị Cẩm Thư',
          phoneNumber: '0965891653',
          isVerified: true,
        ),
      );
      expect(find.text('Phạm Thị Cẩm Thư'), findsOneWidget);
      expect(find.text('SĐT: 0965891653'), findsOneWidget);
      expect(find.byTooltip('Đã xác thực'), findsOneWidget);
      expect(find.text('Chưa có hạng'), findsNothing);
      expect(
        tester
            .widget<HomeBottomNavigation>(find.byType(HomeBottomNavigation))
            .floatingSelectedColor,
        RevoHomeColors.navigationSelected,
      );
      final provider = _state(tester);
      provider
          .read(profileProvider.notifier)
          .initialize(const UserProfile(id: 'new', fullName: 'Hồ sơ mới'));
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ mới'), findsOneWidget);
      expect(find.byTooltip('Đã xác thực'), findsNothing);
      expect(find.text('Chưa cập nhật SĐT'), findsOneWidget);
      expect(find.text('Chưa có hạng'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Utilities show the actual vehicle, addresses and email', (
    tester,
  ) async {
    await _open(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);
    await _tap(tester, _key('vehicle-info'));
    expect(
      find.textContaining(profileFixture.defaultVehicle!.plate),
      findsOneWidget,
    );
    expect(
      find.textContaining(profileFixture.defaultVehicle!.tireType),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip('Đóng'));
    await _tap(tester, _key('addresses'));
    expect(find.textContaining(profileFixture.defaultAddress), findsOneWidget);
    expect(find.textContaining(profileFixture.workAddress), findsOneWidget);
    await _tap(tester, find.byTooltip('Đóng'));
    await _tap(tester, _key('email'));
    expect(find.text(profileFixture.email), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard camera updates the shared avatar', (tester) async {
    await _open(tester);
    await _tap(tester, _key('avatar'));
    expect(_state(tester).read(profileProvider).avatarBytes, isNotNull);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Biometrics prevent duplicate requests and protect password changes',
    (tester) async {
      final device = _Device()..pendingAuth = Completer<bool>();
      await _open(tester, device: device);
      await _reveal(tester, _key('biometric-switch'));
      await tester.tap(_key('biometric-switch'));
      await tester.pump();
      expect(_state(tester).read(profileActionsProvider), isTrue);
      expect(tester.widget<Switch>(_key('biometric-switch')).onChanged, isNull);
      expect(device.authCalls, 1);
      device.pendingAuth!.complete(true);
      await tester.pumpAndSettle();
      expect(_state(tester).read(profileProvider).biometricEnabled, isTrue);
      device.pendingAuth = null;
      device.authenticated = false;
      await _tap(tester, _key('password'));
      expect(find.text('Đổi mật khẩu').evaluate().length, 1);
      expect(find.byType(AlertDialog), findsNothing);
      await _tap(tester, _key('biometric-switch'));
      expect(_state(tester).read(profileProvider).biometricEnabled, isTrue);
      device.authenticated = true;
      await _tap(tester, _key('password'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(device.authCalls, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Delete cancellation and failure preserve the session; success clears it',
    (tester) async {
      final account = _Account();
      final router = await _open(tester, account: account);
      await _tap(tester, _key('delete'));
      await _tap(tester, find.text('Hủy'));
      expect(account.deletions, 0);
      await _tap(tester, _key('delete'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xóa tài khoản'),
        ),
      );
      expect(account.deletions, 1);
      expect(router.state.uri.path, '/tai-khoan');
      expect(
        _state(tester).read(profileProvider).profile.id,
        profileFixture.id,
      );
      expect(find.text('Không thể xóa tài khoản lúc này.'), findsOneWidget);
      account.failDelete = false;
      await _tap(tester, _key('delete'));
      await _tap(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Xóa tài khoản'),
        ),
      );
      expect(router.state.uri.path, '/login');
      expect(_state(tester).read(profileProvider).profile.id, isEmpty);
      expect(router.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Logout requires confirmation and replaces the route stack', (
    tester,
  ) async {
    final router = await _open(tester);
    await _tap(tester, _key('logout'));
    await _tap(tester, find.text('Hủy'));
    expect(_state(tester).read(profileProvider).profile.id, profileFixture.id);
    await _tap(tester, _key('logout'));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Đăng xuất'),
      ),
    );
    expect(router.state.uri.path, '/login');
    expect(_state(tester).read(profileProvider).profile.id, isEmpty);
    expect(router.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All dashboard sections remain usable at 320px and 1.5x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester);
    expect(tester.takeException(), isNull);
    for (final id in [
      'vehicle-info',
      'shop',
      'biometric-switch',
      'settings',
      'delete',
    ]) {
      await _reveal(tester, _key(id));
      expect(_key(id).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Phiên bản Revo v1.0.0'), findsOneWidget);
    expect(find.text('Chưa có hạng'), findsNothing);
  });

  test('A delayed photo selection cannot overwrite another account', () async {
    final device = _Device()..pendingPhoto = Completer<Uint8List?>();
    final container = ProviderContainer(
      overrides: [
        initialUserProfileProvider.overrideWithValue(profileFixture),
        profileDeviceServiceProvider.overrideWithValue(device),
      ],
    );
    final subscription = container.listen(profileActionsProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    final operation = container
        .read(profileActionsProvider.notifier)
        .pickAvatar();
    await Future<void>.delayed(Duration.zero);
    container
        .read(profileProvider.notifier)
        .initialize(const UserProfile(id: 'another', fullName: 'Bình'));
    device.pendingPhoto!.complete(Uint8List.fromList([1, 2, 3]));
    expect((await operation).success, isFalse);
    expect(container.read(profileProvider).avatarBytes, isNull);
    expect(container.read(profileProvider).profile.id, 'another');
  });
}
